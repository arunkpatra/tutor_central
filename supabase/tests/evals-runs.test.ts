import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 22 (D116, migration 0067): the golden sets' page reads the done eval_run jobs; a person starts a run from it.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let adminId: string;
const stamp = Date.now();
const kind = (gate: boolean, rate: number) => ({ cases: 5, expect: 5, schema: 5, verify: 5, check_pass: 4, grade_pass: Math.round(rate * 5), grade_rate: rate, gate, cost_paise: 400, would_repair: 1 });

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `evals-a-${stamp}@example.com`);
  await a.rpc("create_centre", { p_name: "Evals A", p_whatsapp: "+919999999999" });
  const admin = await userClient(l, `evals-admin-${stamp}@example.com`);
  adminId = (await admin.auth.getUser()).data.user!.id;
  await sql`insert into public.admin_users (user_id, email) values (${adminId}, ${`evals-admin-${stamp}@example.com`})`;
  await sql`delete from public.jobs where kind = 'eval_run'`;
  const older = { day: "2026-10-13", gate: true, kinds: { check: kind(true, 1) }, cost_paise: 400, failures: [] };
  const newer = { day: "2026-10-14", gate: false, kinds: { plan: kind(false, 0.6), brief: kind(true, 1) }, cost_paise: 800, failures: [{ id: "plan-oct-8-science", reasons: ["grade: the tenth chapter, not October's"] }] };
  await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, input, result, finished_at)
    values (null, 'eval_run', 'evals:2026-10-13', 'done', '{"day":"2026-10-13"}', ${JSON.stringify(older)}::text::jsonb, now() - interval '2 days'),
           (null, 'eval_run', 'evals:2026-10-14', 'done', '{"day":"2026-10-14"}', ${JSON.stringify(newer)}::text::jsonb, now() - interval '1 day')`;
});
afterAll(async () => {
  await sql`delete from public.jobs where kind = 'eval_run'`;
  await sql.close();
});

type Runs = {
  tiles: { kinds: number; passed: number; below: number; last_run_paise: number };
  rows: { kind: string; gate: boolean; grade_rate: number; cases: number; cost_paise: number; by_admin: boolean }[];
  failures: { id: string; reasons: string[] }[];
  queued: string | null;
};

test("the newest done run answers each kind's figures and the failures", async () => {
  const runs = (await svc.rpc("admin_eval_runs")).data as Runs;
  expect(runs.rows.map((r) => r.kind)).toEqual(["brief", "check", "plan"]);
  expect(runs.rows.find((r) => r.kind === "plan")).toMatchObject({ gate: false, grade_rate: 0.6, cases: 5, cost_paise: 400, by_admin: false });
  expect(runs.rows.find((r) => r.kind === "check")?.gate).toBe(true);
  expect(runs.tiles).toMatchObject({ kinds: 3, passed: 2, below: 1, last_run_paise: 800 });
  expect(runs.failures).toEqual([{ id: "plan-oct-8-science", reasons: ["grade: the tenth chapter, not October's"] }]);
  expect(runs.queued).toBeNull();
});

test("a run started by an admin is a job with its kinds and an audit row; a second while one is queued answers null", async () => {
  const id = (await svc.rpc("admin_run_evals", { p_admin: adminId, p_kinds: ["plan", "brief"], p_ip: "127.0.0.1" })).data as string;
  const job = (await svc.from("jobs").select("centre_id, kind, idempotency_key, input, state").eq("id", id).single()).data!;
  expect(job).toMatchObject({ centre_id: null, kind: "eval_run", state: "queued", input: { kinds: ["plan", "brief"] } });
  expect(job.idempotency_key).toMatch(/^evals:\d{4}-\d{2}-\d{2}:admin:\d{4}$/);
  expect((job.input as { day: string }).day).toMatch(/^\d{4}-\d{2}-\d{2}-\d{4}$/);
  const audit = (await svc.from("admin_audit").select("action, target, ip").eq("admin_user_id", adminId).single()).data;
  expect(audit).toMatchObject({ action: "run_evals", target: { job: id, kinds: ["plan", "brief"] }, ip: "127.0.0.1" });
  expect(((await svc.rpc("admin_eval_runs")).data as Runs).queued).toBe(id);
  expect((await svc.rpc("admin_run_evals", { p_admin: adminId, p_kinds: null, p_ip: null })).data).toBeNull();
  expect((await svc.rpc("admin_run_evals", { p_admin: adminId, p_kinds: ["Plan; drop"], p_ip: null })).error?.message).toContain("unknown_kind");
  await sql`delete from public.jobs where id = ${id}`;
  const every = (await svc.rpc("admin_run_evals", { p_admin: adminId, p_kinds: [], p_ip: null })).data as string;
  expect((await svc.from("jobs").select("input").eq("id", every).single()).data?.input).not.toHaveProperty("kinds");
});

test("a run that measured nothing (no kinds) does not take over the tiles or hide the last failures (review R-db-3)", async () => {
  const [{ id }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, input, result, finished_at)
    values (null, 'eval_run', ${`evals:nothing-${stamp}`}, 'done', '{"day":"x"}', '{"day":"x","gate":false,"reason":"no_cases","kinds":{},"failures":[],"cost_paise":0}', now()) returning id`;
  const runs = (await svc.rpc("admin_eval_runs")).data as Runs;
  await sql`delete from public.jobs where id = ${id}`;
  expect(runs.tiles.last_run_paise).toBe(800);
  expect(runs.failures).toEqual([{ id: "plan-oct-8-science", reasons: ["grade: the tenth chapter, not October's"] }]);
});

test("with no run yet the read answers empty lists and zeros, never a null (hand run 6, F2)", async () => {
  const kept = await sql`select id from public.jobs where kind = 'eval_run'`;
  await sql`update public.jobs set state = 'cancelled' where kind = 'eval_run'`;
  const runs = (await svc.rpc("admin_eval_runs")).data as Runs & { failures_job: string | null };
  await sql`update public.jobs set state = 'done' where id in ${sql(kept.map((r: { id: string }) => r.id))}`;
  expect(runs).toMatchObject({ rows: [], failures: [], failures_job: null, queued: null });
  expect(runs.tiles).toMatchObject({ kinds: 0, passed: 0, below: 0, last_run_paise: 0 });
});

test("a member reads and starts nothing (42501)", async () => {
  expect((await a.rpc("admin_eval_runs")).error?.code).toBe("42501");
  expect((await a.rpc("admin_run_evals", { p_admin: adminId, p_kinds: null, p_ip: null })).error?.code).toBe("42501");
});
