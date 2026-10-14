import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 19 (D78, D94, D95): the admin allow-list, the alerts' key, and the platform's write functions (migration 0046).
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let centreA: string;
let adminId: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `admin-w-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Centre A", p_whatsapp: "+919999999999" })).data as string;
  const admin = await userClient(l, `admin-w-admin-${stamp}@example.com`);
  adminId = (await admin.auth.getUser()).data.user!.id;
  await sql`insert into public.admin_users (user_id, email) values (${adminId}, ${`admin-w-admin-${stamp}@example.com`})`;
});
afterAll(async () => {
  await sql`delete from public.jobs where centre_id = ${centreA}`;
  await sql.close();
});

test("admin_users is read by no member and written by none but the platform", async () => {
  expect((await a.from("admin_users").select("user_id")).data).toEqual([]);
  expect((await a.from("admin_users").insert({ user_id: adminId, email: "x@example.com" })).error).not.toBeNull();
  expect((await svc.from("admin_users").select("email").eq("user_id", adminId)).data?.length).toBe(1);
});

test("admin_audit_write keeps who, what, which centre, the reason and the address", async () => {
  const { data: id, error } = await svc.rpc("admin_audit_write", { p_admin: adminId, p_action: "sign_in", p_centre: null, p_target: {}, p_reason: "second factor verified", p_ip: "49.207.1.1" });
  expect(error).toBeNull();
  const [row] = await sql`select admin_user_id, action, reason, ip from public.admin_audit where id = ${id}`;
  expect(row).toEqual({ admin_user_id: adminId, action: "sign_in", reason: "second factor verified", ip: "49.207.1.1" });
  expect((await a.rpc("admin_audit_write", { p_admin: adminId, p_action: "sign_in", p_centre: null, p_target: {}, p_reason: null, p_ip: null })).error?.code).toBe("42501");
});

test("raise_alert raises a key once and answers false the second time", async () => {
  const key = `job_failed:${crypto.randomUUID()}`;
  const first = await svc.rpc("raise_alert", { p_key: key, p_kind: "job_failed", p_centre: centreA, p_threshold: 0, p_value: 1, p_message: "a plan job failed after 3 tries" });
  const second = await svc.rpc("raise_alert", { p_key: key, p_kind: "job_failed", p_centre: centreA, p_threshold: 0, p_value: 1, p_message: "again" });
  expect([first.data, second.data]).toEqual([true, false]);
  const rows = await sql`select message from public.alerts where key = ${key}`;
  expect(rows).toEqual([{ message: "a plan job failed after 3 tries" }]);
});

test("admin_acknowledge_alert marks once, by whom, and writes the audit", async () => {
  const key = `cost_day:${centreA}:2026-10-13`;
  await svc.rpc("raise_alert", { p_key: key, p_kind: "cost_day", p_centre: centreA, p_threshold: 6000, p_value: 7200, p_message: "over ₹60" });
  const [{ id }] = await sql`select id from public.alerts where key = ${key}`;
  expect((await svc.rpc("admin_acknowledge_alert", { p_admin: adminId, p_alert: id, p_ip: "1.2.3.4" })).data).toBe(true);
  expect((await svc.rpc("admin_acknowledge_alert", { p_admin: adminId, p_alert: id, p_ip: "1.2.3.4" })).data).toBe(false);
  expect((await svc.rpc("admin_acknowledge_alert", { p_admin: adminId, p_alert: crypto.randomUUID(), p_ip: null })).data).toBe(false);
  const [row] = await sql`select acknowledged_by, acknowledged_at is not null as done from public.alerts where id = ${id}`;
  expect(row).toEqual({ acknowledged_by: adminId, done: true });
  const audit = await sql`select centre_id, target->>'kind' as kind from public.admin_audit where action = 'acknowledge_alert' and target->>'alert' = ${id}`;
  expect(audit).toEqual([{ centre_id: centreA, kind: "cost_day" }]);
});

test("admin_retry_job re-queues a failed job at its step with attempts 0, and refuses a job that is not failed", async () => {
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, attempts, step, error, started_at, finished_at)
    values (${centreA}, 'plan', ${`retry-${stamp}`}, 'failed', 3, '{"at":"make","n":2}', '{"reason":"attempts"}', now() - interval '1 hour', now()) returning id`;
  expect((await svc.rpc("admin_retry_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(true);
  const [row] = await sql`select state, attempts, error, leased_by, started_at, finished_at, step->>'at' as at, run_at <= now() as due from public.jobs where id = ${id}`;
  // started_at cleared: the next claim starts the clock again, so a retried job is not taken for a stuck one.
  expect(row).toEqual({ state: "queued", attempts: 0, error: null, leased_by: null, started_at: null, finished_at: null, at: "make", due: true });
  expect((await svc.rpc("admin_retry_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(false);
  const audit = await sql`select centre_id, target->>'step' as step, target->>'kind' as kind from public.admin_audit where action = 'retry_job' and target->>'job' = ${id}`;
  expect(audit).toEqual([{ centre_id: centreA, step: "make", kind: "plan" }]);
});

test("admin_cancel_job cancels a live job and writes the audit; a done job is refused", async () => {
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state) values (${centreA}, 'plan', ${`cancel-${stamp}`}, 'queued') returning id`;
  expect((await svc.rpc("admin_cancel_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(true);
  const [row] = await sql`select state, finished_at is not null as finished from public.jobs where id = ${id}`;
  expect(row).toEqual({ state: "cancelled", finished: true });
  expect((await svc.rpc("admin_cancel_job", { p_admin: adminId, p_job: id, p_ip: "1.2.3.4" })).data).toBe(false);
  expect((await sql`select count(*)::int as n from public.admin_audit where action = 'cancel_job' and target->>'job' = ${id}`)[0].n).toBe(1);
});

test("alert_facts names the failed, the stuck, today's cost and the hour's errors", async () => {
  const [{ id: failed }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, attempts, finished_at) values (${centreA}, 'plan', ${`facts-f-${stamp}`}, 'failed', 3, now()) returning id`;
  const [{ id: old }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, attempts, finished_at) values (${centreA}, 'plan', ${`facts-o-${stamp}`}, 'failed', 3, now() - interval '31 minutes') returning id`;
  const [{ id: stuck }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, started_at, lease_until) values (${centreA}, 'plan', ${`facts-s-${stamp}`}, 'running', now() - interval '11 minutes', now() + interval '1 minute') returning id`;
  const [{ id: fresh }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, started_at, lease_until) values (${centreA}, 'plan', ${`facts-r-${stamp}`}, 'running', now() - interval '9 minutes', now() + interval '1 minute') returning id`;
  await svc.from("api_requests").insert([
    { request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 502, latency_ms: 1, centre_id: centreA, reason: "timeout" },
    { request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 200, latency_ms: 1, centre_id: centreA },
  ]);
  type Facts = { failed_jobs: { id: string; kind: string; centre_id: string }[]; stuck_jobs: { id: string }[]; requests_hour: { total: number; errors: number }; cost_today: { centre_id: string; paise: number }[] };
  const { data, error } = await svc.rpc("alert_facts", { p_now: new Date().toISOString() });
  expect(error).toBeNull();
  const facts = data as Facts;
  const ids = facts.failed_jobs.map((j) => j.id);
  expect(ids).toContain(failed);
  expect(ids).not.toContain(old);
  expect(facts.failed_jobs.find((j) => j.id === failed)).toMatchObject({ kind: "plan", centre_id: centreA });
  expect(facts.stuck_jobs.map((j) => j.id)).toContain(stuck);
  expect(facts.stuck_jobs.map((j) => j.id)).not.toContain(fresh);
  expect(facts.requests_hour.errors).toBeGreaterThanOrEqual(1);
  expect(facts.requests_hour.total).toBeGreaterThanOrEqual(2);
  expect(Array.isArray(facts.cost_today)).toBe(true);
});

test("admin_push_targets answers the admins with a tutor account and centre to push to", async () => {
  const target = (await a.auth.getUser()).data.user!.id;
  await sql`update public.admin_users set notify_user_id = ${target}, notify_centre_id = ${centreA} where user_id = ${adminId}`;
  const { data } = await svc.rpc("admin_push_targets");
  expect(data).toContainEqual({ user_id: target, centre_id: centreA });
});

test("a member cannot call the platform's admin functions", async () => {
  const id = "00000000-0000-0000-0000-000000000000";
  const calls: [string, Record<string, unknown>][] = [
    ["admin_audit_write", { p_admin: id, p_action: "x", p_centre: null, p_target: {}, p_reason: null, p_ip: null }],
    ["raise_alert", { p_key: "k", p_kind: "x", p_centre: null, p_threshold: 0, p_value: 0, p_message: "m" }],
    ["alert_facts", { p_now: new Date().toISOString() }],
    ["admin_push_targets", {}],
    ["admin_acknowledge_alert", { p_admin: id, p_alert: id, p_ip: null }],
    ["admin_retry_job", { p_admin: id, p_job: id, p_ip: null }],
    ["admin_cancel_job", { p_admin: id, p_job: id, p_ip: null }],
  ];
  for (const [fn, args] of calls) {
    const r = await a.rpc(fn, args);
    expect({ fn, code: r.error?.code }).toEqual({ fn, code: "42501" });
  }
});

test("the platform queues an alerts job with no centre, as it does the sweep", async () => {
  const { data, error } = await svc.rpc("enqueue_job", { p_centre: null, p_kind: "alerts", p_key: `alerts:test-${stamp}` });
  expect(error).toBeNull();
  await sql`delete from public.jobs where id = ${data as string}`;
});

test("a long job still making progress is not stuck; one with no step for over ten minutes is, from its last step (R-db-1)", async () => {
  const [{ id: busy }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, started_at, lease_until) values (${centreA}, 'plan', ${`busy-${stamp}`}, 'running', now() - interval '20 minutes', now() + interval '1 minute') returning id`;
  await sql`insert into public.job_steps (centre_id, job_id, step, attempt, state, created_at, updated_at) values (${centreA}, ${busy}, 'make:3', 1, 'done', now() - interval '2 minutes', now() - interval '2 minutes')`;
  const [{ id: idle }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, started_at, lease_until) values (${centreA}, 'plan', ${`idle-${stamp}`}, 'running', now() - interval '20 minutes', now() + interval '1 minute') returning id`;
  await sql`insert into public.job_steps (centre_id, job_id, step, attempt, state, created_at, updated_at) values (${centreA}, ${idle}, 'make:1', 1, 'done', now() - interval '12 minutes', now() - interval '12 minutes')`;
  const facts = (await svc.rpc("alert_facts", { p_now: new Date().toISOString() })).data as { stuck_jobs: { id: string; since: string }[] };
  const ids = facts.stuck_jobs.map((j) => j.id);
  expect(ids).toContain(idle);
  expect(ids).not.toContain(busy);
  const since = Date.parse(facts.stuck_jobs.find((j) => j.id === idle)!.since);
  expect(Math.round((Date.now() - since) / 60_000)).toBe(12);
});

test("the hour's requests are the API's answers, not the worker's ticks (R-db-2)", async () => {
  // A second ahead: the rows' times carry microseconds and the runner's clock milliseconds, so an hour ending at the
  // runner's "now" could end before the row just written (CI run 38535228062).
  const at = () => new Date(Date.now() + 1_000).toISOString();
  const before = (await svc.rpc("alert_facts", { p_now: at() })).data as { requests_hour: { total: number; errors: number } };
  const tick = () => ({ request_id: crypto.randomUUID(), route: "/jobs/tick", method: "GET", status: 200, latency_ms: 1 });
  await svc.from("api_requests").insert([tick(), tick(), tick(), { request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status: 502, latency_ms: 1, reason: "timeout" }]);
  const after = (await svc.rpc("alert_facts", { p_now: at() })).data as { requests_hour: { total: number; errors: number } };
  expect(after.requests_hour.total - before.requests_hour.total).toBe(1);
  expect(after.requests_hour.errors - before.requests_hour.errors).toBe(1);
});

test("trim_platform removes the alerts jobs done over seven days ago, as the sweeps' (R-db-3)", async () => {
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, finished_at) values (null, 'alerts', ${`alerts:old-${stamp}`}, 'done', now() - interval '8 days') returning id`;
  await svc.rpc("trim_platform", { p_now: new Date().toISOString() });
  expect((await sql`select id from public.jobs where id = ${id}`).length).toBe(0);
});
