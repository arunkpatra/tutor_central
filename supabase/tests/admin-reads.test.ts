import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 19 (D78, D79, D94): the admin portal's reads (migration 0047), granted to the platform alone. The db step resets
// with no seed, so the test builds its own centre: two students (one with consent), a batch, three calls, two jobs, four
// requests and an app_opened event.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let centreA: string;
let adminId: string;
let sheetCall: string;
let noteWithConsent: string;
let noteWithoutConsent: string;
let failedJob: string;
const stamp = Date.now();
const india = (d: Date) => new Date(d.getTime() + 5.5 * 3600_000).toISOString().slice(0, 10);
const today = () => india(new Date());
const monthStart = () => `${today().slice(0, 8)}01`;

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `admin-r-a-${stamp}@example.com`);
  const me = (await a.auth.getUser()).data.user!.id;
  centreA = (await a.rpc("create_centre", { p_name: "Reads A", p_whatsapp: "+919999999999" })).data as string;
  const batch = (await a.from("classes").insert({ centre_id: centreA, name: "Evening batch", meeting_days: [1, 2, 3, 4, 5] }).select("id").single()).data!.id as string;
  const given = (await a.from("students").insert({ centre_id: centreA, name: "Aarav Sharma", class_id: batch, class_level: "8", parent_phone: "+919876543210" }).select("id").single()).data!.id as string;
  const none = (await a.from("students").insert({ centre_id: centreA, name: "Akshita Rao", class_id: batch, class_level: "10", parent_phone: "+919812345678" }).select("id").single()).data!.id as string;
  await sql`update public.students set consent_at = now(), consent_phone = '+919876543210', consent_how = 'whatsapp' where id = ${given}`;
  const call = async (kind: string, student: string | null, paise: number) => {
    const [{ id }] = await sql`insert into public.ai_generations (centre_id, kind, input, model, status, student_id, cost_paise, latency_ms, tokens_in, tokens_out, user_id, finished_at)
      values (${centreA}, ${kind}, ${JSON.stringify({ kind, studentName: student ? "named" : null })}::text::jsonb, 'claude-haiku-5-5', 'ok', ${student}, ${paise}, 900, 700, 60, ${me}, now()) returning id`;
    return id as string;
  };
  sheetCall = await call("sheet", null, 120);
  noteWithConsent = await call("note", given, 7);
  noteWithoutConsent = await call("note", none, 0);
  await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, input, result, started_at, finished_at)
    values (${centreA}, 'plan', ${`reads-done-${stamp}`}, 'done', ${JSON.stringify({ class_id: batch, date: today() })}::text::jsonb, '{"made": 11, "not_made": []}', now() - interval '1 minute', now())`;
  [{ id: failedJob }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, attempts, input, step, error, started_at, finished_at)
    values (${centreA}, 'plan', ${`reads-failed-${stamp}`}, 'failed', 3, ${JSON.stringify({ class_id: batch, date: today() })}::text::jsonb, '{"at":"make","n":2}', '{"reason":"attempts"}', now() - interval '8 minutes', now()) returning id`;
  await sql`insert into public.job_steps (centre_id, job_id, step, attempt, state) values (${centreA}, ${failedJob}, 'read', 1, 'done')`;
  await sql`insert into public.job_steps (centre_id, job_id, step, attempt, state, generation_id, cost_paise) values
    (${centreA}, ${failedJob}, 'make:2', 1, 'failed', ${sheetCall}, 6), (${centreA}, ${failedJob}, 'make:2', 2, 'failed', ${sheetCall}, 6)`;
  await svc.from("api_requests").insert([
    { request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 502, latency_ms: 110000, centre_id: centreA, reason: "timeout" },
    { request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 403, latency_ms: 40, centre_id: centreA, reason: "student_consent" },
    { request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 200, latency_ms: 2000, centre_id: centreA },
    { request_id: crypto.randomUUID(), route: "/account", method: "GET", status: 401, latency_ms: 5, reason: "sign in again" },
  ]);
  await a.from("events").insert({ centre_id: centreA, kind: "app_opened", screen: "today", at: new Date().toISOString() });
  // A batch or student change queues the reminders' plan (0045); this test counts the plan jobs alone.
  await sql`delete from public.jobs where centre_id = ${centreA} and kind = 'reminder_sweep'`;
  const admin = await userClient(l, `admin-r-admin-${stamp}@example.com`);
  adminId = (await admin.auth.getUser()).data.user!.id;
  await sql`insert into public.admin_users (user_id, email) values (${adminId}, ${`admin-r-admin-${stamp}@example.com`})`;
});
afterAll(async () => {
  await sql`delete from public.jobs where centre_id = ${centreA}`;
  await sql.close();
});

type Row = { id: string; students: number; tutors: number; cost_paise: number; in_use: boolean; jobs_today: number; failed_today: number };

test("admin_centres counts the centre, its students and tutors, its cost and jobs, and says it is in use", async () => {
  const { data, error } = await svc.rpc("admin_centres", { p_month: monthStart() });
  expect(error).toBeNull();
  const row = (data as { rows: Row[] }).rows.find((r) => r.id === centreA)!;
  expect(row).toMatchObject({ students: 2, tutors: 1, cost_paise: 127, in_use: true, jobs_today: 2, failed_today: 1 });
  expect((data as { tiles: { failed_today: number } }).tiles.failed_today).toBeGreaterThanOrEqual(1);
});

test("admin_centre names the tutors (their emails come from the Auth admin API) and never a parent's number", async () => {
  const { data, error } = await svc.rpc("admin_centre", { p_centre: centreA, p_month: monthStart() });
  expect(error).toBeNull();
  const text = JSON.stringify(data);
  expect(text).toContain((await a.auth.getUser()).data.user!.id);
  expect(text).not.toContain("+91");
  expect(data).toMatchObject({ students: 2, batches: 1, cost_paise: 127, calls: 3, cost_by_kind: { plan: 120, notes: 7, exams: 0, other: 0 } });
  expect((data as { tutors: unknown[] }).tutors.length).toBe(1);
  expect((await svc.rpc("admin_centre", { p_centre: crypto.randomUUID(), p_month: monthStart() })).data).toBeNull();
});

test("admin_activity names what the tutor did by kind, never the content", async () => {
  const { data } = await svc.rpc("admin_activity", { p_centre: centreA, p_limit: 20 });
  expect((data as { kind: string; screen: string }[])[0]).toMatchObject({ kind: "app_opened", screen: "today" });
});

test("admin_centre_jobs names a job's subject by its batch and day, and its made count", async () => {
  const { data } = await svc.rpc("admin_centre_jobs", { p_centre: centreA, p_limit: 5 });
  const rows = data as { subject: string; state: string; made: number | null; not_made: number | null }[];
  expect(rows.length).toBe(2);
  const day = new Date(`${today()}T12:00:00Z`).toLocaleString("en-GB", { day: "numeric", month: "short", timeZone: "UTC" });
  expect(rows.map((r) => r.subject)).toEqual([`Evening batch · ${day}`, `Evening batch · ${day}`]);
  expect(rows.find((r) => r.state === "done")).toMatchObject({ made: 11, not_made: 0 });
});

test("admin_open_record writes the audit first and answers the students' consent states; an empty reason is refused", async () => {
  const r = await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "a support ask", p_ip: "1.1.1.1" });
  expect(r.error).toBeNull();
  const students = (r.data as { students: { name: string; consent: { state: string } }[] }).students;
  expect(students.map((s) => s.consent.state).sort()).toEqual(["given", "not_asked"]);
  expect(JSON.stringify(r.data)).not.toContain("+91");
  expect((await sql`select count(*)::int as n from public.admin_audit where action = 'open_record' and centre_id = ${centreA}`)[0].n).toBe(1);
  const blank = await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "  ", p_ip: null });
  expect(blank.error?.message).toContain("reason_required");
  expect((await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "x".repeat(201), p_ip: null })).error?.message).toContain("reason_required");
});

test("admin_record_opened answers for a fresh open_record row and not for one eleven minutes old or of another action", async () => {
  const opened = await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "again", p_ip: null });
  const audit = (opened.data as { audit_id: string }).audit_id;
  expect(((await svc.rpc("admin_record_opened", { p_audit: audit, p_admin: adminId })).data as { reason: string }).reason).toBe("again");
  await sql`update public.admin_audit set created_at = now() - interval '11 minutes' where id = ${audit}`;
  expect((await svc.rpc("admin_record_opened", { p_audit: audit, p_admin: adminId })).data).toBeNull();
  const other = (await svc.rpc("admin_audit_write", { p_admin: adminId, p_action: "sign_in", p_centre: centreA, p_target: {}, p_reason: null, p_ip: null })).data as string;
  expect((await svc.rpc("admin_record_opened", { p_audit: other, p_admin: adminId })).data).toBeNull();
});

test("admin_call hides a personal kind's input without consent and shows a group kind's and a consented one's", async () => {
  const held = await svc.rpc("admin_call", { p_id: noteWithoutConsent });
  expect(held.data).toMatchObject({ input: null, input_held: true, student: true });
  const sheet = (await svc.rpc("admin_call", { p_id: sheetCall })).data as { input: unknown; input_held: boolean; started_by: string };
  expect(sheet).toMatchObject({ input_held: false, started_by: "tap" });
  expect(sheet.input).not.toBeNull();
  expect(((await svc.rpc("admin_call", { p_id: noteWithConsent })).data as { input_held: boolean }).input_held).toBe(false);
  expect((await svc.rpc("admin_call", { p_id: crypto.randomUUID() })).data).toBeNull();
});

test("admin_calls lists the day's calls with the tiles, filtered by kind", async () => {
  const { data } = await svc.rpc("admin_calls", { p_day: today(), p_centre: centreA, p_kind: "note", p_status: null, p_limit: 50 });
  const calls = data as { tiles: { calls: number }; rows: { kind: string }[] };
  expect(calls.tiles.calls).toBe(2);
  expect(calls.rows.every((r) => r.kind === "note")).toBe(true);
});

test("the cost functions add up to the same rupees", async () => {
  const byCentre = (await svc.rpc("admin_cost_by_centre", { p_month: monthStart() })).data as { id: string; paise: number }[];
  const byKind = (await svc.rpc("admin_cost_by_kind", { p_month: monthStart() })).data as { paise: number }[];
  const byDay = (await svc.rpc("admin_cost_by_day", { p_month: monthStart() })).data as { paise: number }[];
  const total = byCentre.reduce((s, r) => s + r.paise, 0);
  expect(byKind.reduce((s, r) => s + r.paise, 0)).toBe(total);
  expect(byDay.reduce((s, r) => s + r.paise, 0)).toBe(total);
  expect(byDay.length).toBeGreaterThanOrEqual(28);
  expect(byCentre.find((r) => r.id === centreA)?.paise).toBe(127);
  const mine = (await svc.rpc("admin_cost_by_day", { p_month: monthStart(), p_centre: centreA })).data as { paise: number }[];
  expect(mine.reduce((s, r) => s + r.paise, 0)).toBe(127);
  const tiles = (await svc.rpc("admin_cost_tiles", { p_month: monthStart() })).data as { month_paise: number };
  expect(tiles.month_paise).toBe(total);
});

test("admin_jobs filters by state and admin_job lists the steps, one row a step with its last try", async () => {
  const failed = (await svc.rpc("admin_jobs", { p_day: today(), p_state: "failed", p_kind: null, p_centre: centreA, p_limit: 50 })).data as { tiles: { today: number }; rows: { id: string }[] };
  expect(failed.rows.map((r) => r.id)).toEqual([failedJob]);
  expect(failed.tiles.today).toBe(2);
  const job = (await svc.rpc("admin_job", { p_id: failedJob })).data as { steps: { step: string; state: string; attempt: number; cost_paise: number }[]; step: string };
  expect(job.steps.map((s) => `${s.step}:${s.state}`)).toEqual(["read:done", "make:2:failed"]);
  expect(job.steps[1]).toMatchObject({ attempt: 2, cost_paise: 12 });
  expect(job.step).toBe("make:2");
});

test("admin_errors_by_route groups by route, status and reason; admin_errors_recent is newest first", async () => {
  const by = (await svc.rpc("admin_errors_by_route", { p_hours: 24 })).data as { rows: { route: string; status: number; reason: string; last_24h: number }[] };
  expect(by.rows.find((r) => r.route === "POST /ai/make" && r.status === 502)?.last_24h).toBeGreaterThanOrEqual(1);
  expect(by.rows.find((r) => r.status === 401)?.route).toBe("any");
  const recent = (await svc.rpc("admin_errors_recent", { p_limit: 10 })).data as { status: number; created_at: string }[];
  expect(recent.every((r) => r.status >= 400)).toBe(true);
  expect(recent.map((r) => r.created_at)).toEqual([...recent.map((r) => r.created_at)].sort().reverse());
});

test("admin_alerts, admin_audit: open first; the audit names the admin's email", async () => {
  await svc.rpc("raise_alert", { p_key: `reads-open-${stamp}`, p_kind: "job_failed", p_centre: centreA, p_threshold: 0, p_value: 1, p_message: "m" });
  await svc.rpc("raise_alert", { p_key: `reads-ack-${stamp}`, p_kind: "job_stuck", p_centre: centreA, p_threshold: 10, p_value: 14, p_message: "m" });
  const [{ id }] = await sql`select id from public.alerts where key = ${`reads-ack-${stamp}`}`;
  await svc.rpc("admin_acknowledge_alert", { p_admin: adminId, p_alert: id, p_ip: null });
  const alerts = (await svc.rpc("admin_alerts", { p_open_first: true })).data as { rows: { acknowledged_at: string | null; acknowledged_by_email: string | null }[] };
  const firstAck = alerts.rows.findIndex((r) => r.acknowledged_at !== null);
  expect(firstAck).toBeGreaterThan(0);
  expect(alerts.rows.slice(firstAck).every((r) => r.acknowledged_at !== null)).toBe(true);
  expect(alerts.rows[firstAck]!.acknowledged_by_email).toBe(`admin-r-admin-${stamp}@example.com`);
  const audit = (await svc.rpc("admin_audit", { p_days: 30, p_admin: null, p_action: "open_record", p_limit: 10 })).data as { admin_email: string }[];
  expect(audit[0]?.admin_email).toBe(`admin-r-admin-${stamp}@example.com`);
});

test("a member cannot call any admin read", async () => {
  const id = "00000000-0000-0000-0000-000000000000";
  const calls: [string, Record<string, unknown>][] = [
    ["admin_centres", { p_month: monthStart() }],
    ["admin_centre", { p_centre: id, p_month: monthStart() }],
    ["admin_activity", { p_centre: id, p_limit: 1 }],
    ["admin_centre_jobs", { p_centre: id, p_limit: 1 }],
    ["admin_record", { p_centre: id }],
    ["admin_open_record", { p_admin: id, p_centre: id, p_reason: "x", p_ip: null }],
    ["admin_record_opened", { p_audit: id, p_admin: id }],
    ["admin_cost_by_day", { p_month: monthStart() }],
    ["admin_cost_by_centre", { p_month: monthStart() }],
    ["admin_cost_by_kind", { p_month: monthStart() }],
    ["admin_cost_tiles", { p_month: monthStart() }],
    ["admin_calls", { p_day: null, p_centre: null, p_kind: null, p_status: null, p_limit: 1 }],
    ["admin_call", { p_id: id }],
    ["admin_jobs", { p_day: null, p_state: null, p_kind: null, p_centre: null, p_limit: 1 }],
    ["admin_job", { p_id: id }],
    ["admin_errors_by_route", { p_hours: 24 }],
    ["admin_errors_recent", { p_limit: 1 }],
    ["admin_alerts", { p_open_first: true }],
    ["admin_audit", { p_days: 1, p_admin: null, p_action: null, p_limit: 1 }],
  ];
  for (const [fn, args] of calls) expect({ fn, code: (await a.rpc(fn, args)).error?.code }).toEqual({ fn, code: "42501" });
});

test("every activity row, record student and made row carries its own id (two rows at one time are two rows)", async () => {
  const [{ id: inv }] = await sql`insert into public.fee_invoices (centre_id, student_id, period, amount, status, paid_at)
    select ${centreA}, s.id, date '2026-10-01', 500, 'paid', now() from public.students s where s.centre_id = ${centreA} limit 1 returning id`;
  await sql`insert into public.fee_invoices (centre_id, student_id, period, amount, status, paid_at)
    select ${centreA}, s.id, date '2026-09-01', 500, 'paid', (select paid_at from public.fee_invoices where id = ${inv}) from public.students s where s.centre_id = ${centreA} limit 1`;
  const activity = (await svc.rpc("admin_activity", { p_centre: centreA, p_limit: 50 })).data as { id: string; kind: string }[];
  const fees = activity.filter((a) => a.kind === "fee_paid");
  expect(fees).toHaveLength(2);
  expect(new Set(activity.map((a) => a.id)).size).toBe(activity.length);
  const record = (await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "ids", p_ip: null })).data as { students: { id: string }[]; made: { id: string }[] };
  expect(record.students.every((s) => typeof s.id === "string")).toBe(true);
  expect(record.made.every((m) => typeof m.id === "string")).toBe(true);
});

test("a job kind with nothing to name has no subject", async () => {
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state) values (${centreA}, 'artefact', ${`subject-${stamp}`}, 'failed') returning id`;
  expect(((await svc.rpc("admin_job", { p_id: id })).data as { subject: string | null }).subject).toBeNull();
});

test("a V1 call that names its student without an id is held (R-a2: progress_note, a typed-scheme check_paper)", async () => {
  const [{ id }] = await sql`insert into public.ai_generations (centre_id, kind, input, model, status, cost_paise, finished_at)
    values (${centreA}, 'progress_note', ${JSON.stringify({ studentName: "Hemanth", parentName: "Mr Reddy", observations: "quiet" })}::text::jsonb, 'claude-sonnet-5-5', 'ok', 5, now()) returning id`;
  const held = (await svc.rpc("admin_call", { p_id: id })).data as { input: unknown; input_held: boolean };
  expect(held).toMatchObject({ input: null, input_held: true });
  expect(JSON.stringify(held)).not.toContain("Hemanth");
});

test("admin_job's step shows the attempt of its latest row, after a retry too (R-db-6)", async () => {
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, attempts) values (${centreA}, 'plan', ${`attempt-${stamp}`}, 'running', 1) returning id`;
  await sql`insert into public.job_steps (centre_id, job_id, step, attempt, state, created_at) values
    (${centreA}, ${id}, 'make:0', 2, 'failed', now() - interval '5 minutes'), (${centreA}, ${id}, 'make:0', 1, 'done', now())`;
  const job = (await svc.rpc("admin_job", { p_id: id })).data as { steps: { attempt: number; state: string }[] };
  expect(job.steps[0]).toMatchObject({ attempt: 1, state: "done" });
});

test("admin_record_opened answers only the admin who opened it (R-db-7, R-a5)", async () => {
  const other = await userClient(l, `admin-r-other-${stamp}@example.com`);
  const otherId = (await other.auth.getUser()).data.user!.id;
  const opened = await svc.rpc("admin_open_record", { p_admin: adminId, p_centre: centreA, p_reason: "mine", p_ip: null });
  const audit = (opened.data as { audit_id: string }).audit_id;
  expect(((await svc.rpc("admin_record_opened", { p_audit: audit, p_admin: adminId })).data as { reason: string }).reason).toBe("mine");
  expect((await svc.rpc("admin_record_opened", { p_audit: audit, p_admin: otherId })).data).toBeNull();
});

test("an open alert older than the newest 200 is still listed, first (R-db-8)", async () => {
  await sql`insert into public.alerts (key, kind, raised_at, message) values (${`old-open-${stamp}`}, 'job_failed', now() - interval '30 days', 'old')`;
  await sql`insert into public.alerts (key, kind, raised_at, acknowledged_at, message)
    select 'acked-' || ${String(stamp)} || '-' || n, 'job_failed', now() - make_interval(mins => n), now(), 'acked' from generate_series(1, 205) n`;
  const alerts = (await svc.rpc("admin_alerts", { p_open_first: true })).data as { rows: { message: string; acknowledged_at: string | null }[] };
  expect(alerts.rows.some((r) => r.message === "old")).toBe(true);
  await sql`delete from public.alerts where key like ${`acked-${stamp}-%`} or key = ${`old-open-${stamp}`}`;
});

test("a call carries its agent step in the list and on its page; the nightly evals' job is named so (0052)", async () => {
  const [{ id }] = await sql`insert into public.ai_generations (centre_id, kind, input, model, status, cost_paise, finished_at, agent_step)
    values (${centreA}, 'sheet', '{}'::jsonb, 'claude-haiku-5-5', 'ok', 1, now(), 'check') returning id`;
  const call = (await svc.rpc("admin_call", { p_id: id })).data as { agent_step: string };
  expect(call.agent_step).toBe("check");
  const list = (await svc.rpc("admin_calls", { p_day: today(), p_centre: centreA, p_kind: "sheet", p_status: null, p_limit: 50 })).data as { rows: { id: string; agent_step: string }[] };
  expect(list.rows.find((r) => r.id === id)?.agent_step).toBe("check");
  expect(list.rows.find((r) => r.id === sheetCall)?.agent_step).toBe("draft");
  const [job] = await sql`insert into public.jobs (kind, idempotency_key, state, input) values ('eval_run', ${`evals-subject-${stamp}`}, 'done', '{"day":"2026-10-20"}') returning id`;
  expect(((await svc.rpc("admin_job", { p_id: job.id })).data as { subject: string }).subject).toBe("nightly evals");
  await sql`delete from public.jobs where id = ${job.id}`;
});

test("a draft refused after its check counts as refused in the tiles and the filter (0054)", async () => {
  const day = (await sql`select (now() at time zone 'Asia/Kolkata')::date::text as d`)[0].d as string;
  const before = ((await svc.rpc("admin_calls", { p_day: day, p_centre: centreA, p_kind: null, p_status: null, p_limit: 100 })).data as { tiles: { refused: number; failed: number } }).tiles;
  const [{ id }] = await sql`insert into public.ai_generations (centre_id, kind, input, model, status, error_reason, cost_paise, finished_at)
    values (${centreA}, 'sheet', '{}'::jsonb, 'claude-sonnet-5-5', 'failed', 'check:question 1', 3, now()) returning id`;
  const after = ((await svc.rpc("admin_calls", { p_day: day, p_centre: centreA, p_kind: null, p_status: null, p_limit: 100 })).data as { tiles: { refused: number; failed: number } }).tiles;
  expect(after).toEqual({ ...after, refused: before.refused + 1, failed: before.failed });
  const refused = (await svc.rpc("admin_calls", { p_day: day, p_centre: centreA, p_kind: null, p_status: "refused", p_limit: 100 })).data as { rows: { id: string }[] };
  expect(refused.rows.map((r) => r.id)).toContain(id);
});

test("admin_call carries the feedback rows, oldest first (D107)", async () => {
  await sql`insert into public.generation_feedback (centre_id, generation_id, kind, reason) values (${centreA}, ${sheetCall}, 'again', 'Less about marks')`;
  await sql`insert into public.generation_feedback (centre_id, generation_id, kind, revised) values (${centreA}, ${sheetCall}, 'edit', '{"text": "x"}'::jsonb)`;
  const call = (await svc.rpc("admin_call", { p_id: sheetCall })).data as { feedback: { kind: string; reason: string | null; created_at: string }[] };
  expect(call.feedback.map((f) => [f.kind, f.reason])).toEqual([["again", "Less about marks"], ["edit", null]]);
  const none = (await svc.rpc("admin_call", { p_id: noteWithConsent })).data as { feedback: unknown[] };
  expect(none.feedback).toEqual([]);
  // Never the revised text: the rows carry these three keys alone.
  for (const f of call.feedback) expect(Object.keys(f).sort()).toEqual(["created_at", "kind", "reason"]);
});

test("a reason the tutor typed reaches the call page as typed, never in its own words (0068, review R-portal-2)", async () => {
  await sql`insert into public.generation_feedback (centre_id, generation_id, kind, reason) values (${centreA}, ${noteWithConsent}, 'again', 'make Dev''s note warmer, Sunita worried')`;
  await sql`insert into public.generation_feedback (centre_id, generation_id, kind, reason) values (${centreA}, ${noteWithConsent}, 'again', 'Warmer')`;
  const call = (await svc.rpc("admin_call", { p_id: noteWithConsent })).data as { feedback: { reason: string | null }[] };
  expect(call.feedback.map((f) => f.reason)).toEqual(["typed", "Warmer"]);
  await sql`delete from public.generation_feedback where generation_id = ${noteWithConsent}`;
});

test("the syllabi and one syllabus with its chapters and skills (0067)", async () => {
  type Syllabi = { tiles: { syllabi: number; boards: string[]; classes: string[]; chapters: number }; rows: { id: string; board: string; class_level: string; subject: string; chapters: number; skills: number }[] };
  const list = (await svc.rpc("admin_syllabi")).data as Syllabi;
  expect(list.tiles.syllabi).toBe(list.rows.length);
  expect(list.tiles.boards).toContain("cbse");
  const maths = list.rows.find((r) => r.board === "cbse" && r.class_level === "8" && r.subject === "Mathematics")!;
  expect(maths.chapters).toBeGreaterThan(0);
  const one = (await svc.rpc("admin_syllabus", { p_id: maths.id })).data as { subject: string; chapters: { no: number; name: string; skills: string[]; marks: number | null }[] };
  expect(one.subject).toBe("Mathematics");
  expect(one.chapters).toHaveLength(maths.chapters);
  expect(one.chapters[0]).toMatchObject({ no: 1, marks: null });
  expect(one.chapters.reduce((n, c) => n + c.skills.length, 0)).toBe(maths.skills);
  expect((await svc.rpc("admin_syllabus", { p_id: crypto.randomUUID() })).data).toBeNull();
  expect((await a.rpc("admin_syllabi")).error?.code).toBe("42501");
});
