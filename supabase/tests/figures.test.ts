import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 22 (D114, D115, migration 0067): the product figures from the tables already kept, the week's reasons, the weekly
// report's job. Other files leave rows of their own this week, so each count is read before and after this file's rows.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let centreB: string;
let adminId: string;
const stamp = Date.now();

type Figures = {
  week_monday: string;
  so_far: boolean;
  tutors_active: number;
  closes: number;
  plans_made: number;
  plans_followed: number;
  notes_sent: number;
  made: number;
  again: number;
  make: number;
  consent_given: number;
  cost_paise: number;
  per_active_tutor_paise: number;
};
type Reasons = { again: { reason: string; count: number }[]; edits: number; made: number; notes: number };
const figures = async (weeks = 2) => (await svc.rpc("admin_figures", { p_weeks: weeks })).data as Figures[];
const reasons = async (monday: string) => (await svc.rpc("admin_reasons_week", { p_monday: monday })).data as Reasons;
let before: Figures;
let reasonsBefore: Reasons;

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `figures-a-${stamp}@example.com`);
  b = await userClient(l, `figures-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Figures A", p_whatsapp: "+919999999999" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Figures B", p_whatsapp: "+919999999998" })).data as string;
  const admin = await userClient(l, `figures-admin-${stamp}@example.com`);
  adminId = (await admin.auth.getUser()).data.user!.id;
  await sql`insert into public.admin_users (user_id, email) values (${adminId}, ${`figures-admin-${stamp}@example.com`})`;
  before = (await figures())[0]!;
  reasonsBefore = await reasons(before.week_monday);
  const userA = (await a.auth.getUser()).data.user!.id;
  const [{ id: batch }] = await sql`insert into public.classes (centre_id, name, meeting_days) values (${centreA}, 'Evening', '{1,2,3,4,5}') returning id`;
  const [{ id: student }] = await sql`insert into public.students (centre_id, name, class_id, class_level) values (${centreA}, 'Dev', ${batch}, '8') returning id`;
  const [{ id: session }] = await sql`insert into public.attendance_sessions (centre_id, class_id, date, closed_at) values (${centreA}, ${batch}, current_date, now()) returning id`;
  await sql`insert into public.plans (centre_id, class_id, date, session_id) values (${centreA}, ${batch}, current_date, ${session})`;
  await sql`insert into public.plans (centre_id, class_id, date) values (${centreA}, ${batch}, current_date + 1)`;
  await sql`insert into public.message_log (centre_id, student_id, kind) values (${centreA}, ${student}, 'note'), (${centreA}, ${student}, 'reminder')`;
  await sql`insert into public.artefacts (centre_id, kind, title, source, made_from) values (${centreA}, 'sheet', 'Fractions', 'made', 'make'), (${centreA}, 'brief', 'Fractions', 'made', null)`;
  await sql`insert into public.consent_events (centre_id, student_id, kind, at) values (${centreA}, ${student}, 'given', now())`;
  const [{ id: gen }] = await sql`insert into public.ai_generations (centre_id, kind, input, model, status, cost_paise, user_id, finished_at)
    values (${centreA}, 'note', '{}'::jsonb, 'claude-haiku-5-5', 'ok', 100, ${userA}, now()) returning id`;
  await sql`insert into public.generation_feedback (centre_id, generation_id, kind, reason) values
    (${centreA}, ${gen}, 'again', 'Less about marks'), (${centreA}, ${gen}, 'again', 'make it about Dev''s cricket')`;
  await sql`insert into public.generation_feedback (centre_id, generation_id, kind, revised) values (${centreA}, ${gen}, 'edit', '{"text":"x"}')`;
  await a.from("events").insert({ centre_id: centreA, kind: "app_opened", at: new Date().toISOString() });
});
afterAll(async () => {
  await sql`delete from public.jobs where kind = 'weekly_report'`;
  await sql`delete from public.centres where id in (${centreA}, ${centreB})`;
  await sql.close();
});

test("the week's figures count what the tables hold, the current week first and so far", async () => {
  const [now] = await figures();
  expect(now!.so_far).toBe(true);
  const delta = (k: keyof Figures) => (now![k] as number) - (before[k] as number);
  expect({
    tutors_active: delta("tutors_active"),
    closes: delta("closes"),
    plans_made: delta("plans_made"),
    plans_followed: delta("plans_followed"),
    notes_sent: delta("notes_sent"),
    made: delta("made"),
    again: delta("again"),
    make: delta("make"),
    consent_given: delta("consent_given"),
    cost_paise: delta("cost_paise"),
  }).toEqual({ tutors_active: 1, closes: 1, plans_made: 2, plans_followed: 1, notes_sent: 1, made: 2, again: 2, make: 1, consent_given: 1, cost_paise: 100 });
  expect(now!.per_active_tutor_paise).toBe(Math.round(now!.cost_paise / now!.tutors_active));
});

test("weeks run Monday to Sunday, newest first; a week with no active tutor shows zero per tutor", async () => {
  const weeks = await figures(52);
  expect(weeks).toHaveLength(52);
  const mondays = weeks.map((w) => w.week_monday);
  for (const m of mondays) expect(new Date(`${m}T12:00:00Z`).getUTCDay()).toBe(1);
  expect(mondays[0]! > mondays[1]!).toBe(true);
  expect(weeks.slice(1).every((w) => !w.so_far)).toBe(true);
  expect(weeks.at(-1)).toMatchObject({ tutors_active: 0, per_active_tutor_paise: 0 });
});

test("an internal centre is left out of the figures", async () => {
  const counted = (await figures(1))[0]!;
  await svc.from("centres").update({ internal: true }).eq("id", centreB);
  await b.from("events").insert({ centre_id: centreB, kind: "app_opened", at: new Date().toISOString() });
  await sql`insert into public.ai_generations (centre_id, kind, input, model, status, cost_paise, finished_at) values (${centreB}, 'sheet', '{}'::jsonb, 'm', 'ok', 999, now())`;
  const after = (await figures(1))[0]!;
  expect({ tutors: after.tutors_active, cost: after.cost_paise }).toEqual({ tutors: counted.tutors_active, cost: counted.cost_paise });
});

test("the reasons of the week: a menu's reason by its words, the tutor's own as typed; the edits, made and notes", async () => {
  const r = await reasons(before.week_monday);
  const count = (x: Reasons, reason: string) => x.again.find((g) => g.reason === reason)?.count ?? 0;
  expect(count(r, "less about marks") - count(reasonsBefore, "less about marks")).toBe(1);
  expect(count(r, "typed") - count(reasonsBefore, "typed")).toBe(1);
  expect(r.again.some((g) => g.reason.includes("cricket"))).toBe(false);
  expect({ edits: r.edits - reasonsBefore.edits, made: r.made - reasonsBefore.made, notes: r.notes - reasonsBefore.notes }).toEqual({ edits: 1, made: 2, notes: 1 });
});

test("the weekly report is scheduled once a week for the week before, and sent now by an admin with its audit row", async () => {
  expect((await svc.rpc("schedule_weekly_report", { p_now: "2026-10-19T02:30:00Z" })).data).toBe(1);
  expect((await svc.rpc("schedule_weekly_report", { p_now: "2026-10-19T02:31:00Z" })).data).toBe(0);
  const job = await svc.from("jobs").select("centre_id, idempotency_key, input").eq("kind", "weekly_report").eq("idempotency_key", "report:2026-10-12").single();
  expect(job.data).toEqual({ centre_id: null, idempotency_key: "report:2026-10-12", input: { week_monday: "2026-10-12" } });
  const id = (await svc.rpc("admin_send_report", { p_admin: adminId, p_ip: null })).data as string;
  const sent = (await svc.from("jobs").select("input, idempotency_key").eq("id", id).single()).data;
  expect(sent?.input).toEqual({ week_monday: before.week_monday, so_far: true });
  expect(sent?.idempotency_key).toMatch(/^report:now:\d{4}-\d{2}-\d{2}-\d{4}$/);
  // A second press in the same minute answers the same job.
  expect((await svc.rpc("admin_send_report", { p_admin: adminId, p_ip: null })).data).toBe(id);
  const audit = await svc.from("admin_audit").select("action, target").eq("admin_user_id", adminId).eq("action", "send_report");
  expect(audit.data).toHaveLength(1);
  const last = (await svc.rpc("admin_report_last")).data as { id: string; so_far: boolean };
  expect(last).toMatchObject({ id, so_far: true });
  const subject = (await svc.rpc("admin_job", { p_id: id })).data as { subject: string };
  expect(subject.subject).toStartWith("the week of ");
});

test("a member reads and starts none of it", async () => {
  const calls: [string, Record<string, unknown>][] = [
    ["admin_figures", { p_weeks: 1 }],
    ["admin_reasons_week", { p_monday: before.week_monday }],
    ["admin_send_report", { p_admin: adminId, p_ip: null }],
    ["schedule_weekly_report", {}],
    ["admin_report_last", {}],
  ];
  for (const [fn, args] of calls) expect({ fn, code: (await a.rpc(fn, args)).error?.code }).toEqual({ fn, code: "42501" });
});
