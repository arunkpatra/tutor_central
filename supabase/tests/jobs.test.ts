import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// The jobs of Phase 17 (D71, D83): the table, the lease, the steps and the functions the worker calls as the platform.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let centreB: string;
const stamp = Date.now();
const enqueue = (centre: string | null, key: string, input = {}) => svc.rpc("enqueue_job", { p_centre: centre, p_kind: "plan", p_key: key, p_input: input });
const claim = (worker: string, limit = 5) => svc.rpc("claim_jobs", { p_worker: worker, p_limit: limit });
/** A claim takes any centre's due jobs, so each test that claims starts from an empty table. */
const clear = () => sql`delete from public.jobs`;

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `jobs-a-${stamp}@example.com`);
  b = await userClient(l, `jobs-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Jobs A" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Jobs B" })).data as string;
});
afterAll(async () => {
  await clear();
  await sql.close();
});

test("the platform passes is_member for any centre; a member still fails for another's", async () => {
  expect((await svc.rpc("is_member", { c: centreA })).data).toBe(true);
  expect((await b.rpc("is_member", { c: centreA })).data).toBe(false);
  expect((await a.rpc("is_member", { c: centreA })).data).toBe(true);
});

test("is_member without a request is false, as before", async () => {
  expect((await sql`select public.is_member(${centreA}::uuid) as m`)[0].m).toBe(false);
});

test("enqueue is idempotent per centre and key, and the same key in another centre is another job", async () => {
  const first = await enqueue(centreA, "plan:x:2026-10-13", { class_id: "c" });
  expect(first.error).toBeNull();
  const again = await enqueue(centreA, "plan:x:2026-10-13", { class_id: "changed" });
  expect(again.data).toBe(first.data);
  const row = await svc.from("jobs").select("input, state, attempts").eq("id", first.data as string).single();
  expect(row.data).toEqual({ input: { class_id: "c" }, state: "queued", attempts: 0 });
  expect((await enqueue(centreB, "plan:x:2026-10-13")).data).not.toBe(first.data);
});

test("a member may enqueue for their centre and read it, not another's; a member cannot write the table", async () => {
  const mine = await a.rpc("enqueue_job", { p_centre: centreA, p_kind: "export", p_key: `export:${stamp}` });
  expect(mine.error).toBeNull();
  expect((await b.rpc("enqueue_job", { p_centre: centreA, p_kind: "export", p_key: "x" })).error?.code).toBe("42501");
  expect((await a.from("jobs").select("id").eq("id", mine.data as string)).data?.length).toBe(1);
  expect((await b.from("jobs").select("id").eq("id", mine.data as string)).data).toEqual([]);
  expect((await a.from("jobs").insert({ centre_id: centreA, kind: "plan", idempotency_key: "direct" })).error).not.toBeNull();
  expect((await a.from("jobs").update({ state: "done" }).eq("id", mine.data as string).select("id")).data).toEqual([]);
  expect((await svc.from("jobs").select("state").eq("id", mine.data as string).single()).data).toEqual({ state: "queued" });
  await a.from("jobs").delete().eq("id", mine.data as string);
  expect((await svc.from("jobs").select("id").eq("id", mine.data as string)).data?.length).toBe(1);
});

test("a claim takes due jobs in run_at order with a lease, skips the future and what another worker holds", async () => {
  await clear();
  await enqueue(centreA, "due-1");
  await enqueue(centreA, "due-2");
  await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "later", p_run_at: new Date(Date.now() + 3_600_000).toISOString() });
  const [one, two] = await Promise.all([claim("w1", 1), claim("w2", 1)]);
  const ids = [one.data![0].id, two.data![0].id];
  expect(new Set(ids).size).toBe(2);
  expect(one.data![0]).toMatchObject({ state: "running", leased_by: "w1", attempts: 1 });
  expect(new Date(one.data![0].lease_until).getTime()).toBeGreaterThan(Date.now() + 100_000);
  expect((await claim("w3")).data).toEqual([]);
});

test("two workers claiming at once each take a job, every time (skip locked under contention)", async () => {
  for (let round = 0; round < 25; round++) {
    await clear();
    await enqueue(centreA, `race-${round}-1`);
    await enqueue(centreA, `race-${round}-2`);
    const [one, two] = await Promise.all([claim("w1", 1), claim("w2", 1)]);
    expect({ round, taken: [one.data?.length, two.data?.length], errors: [one.error?.message, two.error?.message] }).toEqual({ round, taken: [1, 1], errors: [undefined, undefined] });
  }
});

test("a write by a worker that lost the lease is refused; the lease past its time is retaken", async () => {
  await clear();
  const id = (await enqueue(centreA, "lease")).data as string;
  expect((await claim("w1")).data?.length).toBe(1);
  expect((await svc.rpc("record_step", { p_job: id, p_worker: "w2", p_step: "read", p_state: "done" })).error?.message).toContain("job_lease_lost");
  await sql`update public.jobs set lease_until = now() - interval '1 second' where id = ${id}`;
  const retaken = await claim("w2");
  expect(retaken.data![0]).toMatchObject({ id, leased_by: "w2", attempts: 2 });
  expect((await svc.rpc("finish_job", { p_job: id, p_worker: "w1", p_result: {} })).error?.message).toContain("job_lease_lost");
  const step = await svc.rpc("record_step", { p_job: id, p_worker: "w2", p_step: "read", p_state: "done", p_cost_paise: 12, p_step_data: { at: "read" } });
  expect(step.error).toBeNull();
  const row = await svc.from("jobs").select("cost_paise, step").eq("id", id).single();
  expect(row.data).toEqual({ cost_paise: 12, step: { at: "read" } });
  expect((await svc.from("job_steps").select("step, attempt, state, centre_id").eq("job_id", id)).data).toEqual([
    { step: "read", attempt: 2, state: "done", centre_id: centreA },
  ]);
  expect((await svc.rpc("extend_lease", { p_job: id, p_worker: "w2" })).data).toBe(true);
  expect((await svc.rpc("extend_lease", { p_job: id, p_worker: "w1" })).data).toBe(false);
});

test("a lease that lapsed on the last attempt fails the job with its reason", async () => {
  await clear();
  const id = (await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "lapsed", p_max_attempts: 1 })).data as string;
  await claim("w1");
  await sql`update public.jobs set lease_until = now() - interval '1 second' where id = ${id}`;
  expect((await claim("w2")).data).toEqual([]);
  const row = await svc.from("jobs").select("state, error").eq("id", id).single();
  expect(row.data).toMatchObject({ state: "failed", error: { reason: "attempts" } });
});

test("a failure retries with backoff until max_attempts, then fails with its error", async () => {
  await clear();
  const id = (await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "retry", p_max_attempts: 2 })).data as string;
  await claim("w1");
  expect((await svc.rpc("fail_job", { p_job: id, p_worker: "w1", p_error: { reason: "timeout" }, p_retry: true })).data).toBe("queued");
  const queued = await svc.from("jobs").select("run_at, leased_by, attempts").eq("id", id).single();
  expect(queued.data!.leased_by).toBeNull();
  expect(new Date(queued.data!.run_at).getTime()).toBeGreaterThan(Date.now() + 20_000);
  await sql`update public.jobs set run_at = now() where id = ${id}`;
  await claim("w1");
  expect((await svc.rpc("fail_job", { p_job: id, p_worker: "w1", p_error: { reason: "timeout" }, p_retry: true })).data).toBe("failed");
  const failed = await svc.from("jobs").select("state, error, finished_at").eq("id", id).single();
  expect(failed.data).toMatchObject({ state: "failed", error: { reason: "timeout" } });
  expect(failed.data!.finished_at).not.toBeNull();
  expect((await claim("w1")).data).toEqual([]);
});

test("a failure without retry fails at once", async () => {
  await clear();
  const id = (await enqueue(centreA, "no-retry")).data as string;
  await claim("w1");
  expect((await svc.rpc("fail_job", { p_job: id, p_worker: "w1", p_error: { reason: "unfit" }, p_retry: false })).data).toBe("failed");
});

test("waiting continues at the step reached and is not another attempt; done keeps its result", async () => {
  await clear();
  const id = (await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "wait", p_max_attempts: 1 })).data as string;
  await claim("w1");
  expect((await svc.rpc("wait_job", { p_job: id, p_worker: "w1", p_step: { at: "name" }, p_run_at: new Date().toISOString() })).error).toBeNull();
  const again = await claim("w2");
  expect(again.data![0]).toMatchObject({ id, step: { at: "name" }, attempts: 1 });
  expect((await svc.rpc("finish_job", { p_job: id, p_worker: "w2", p_result: { plan_id: "p" } })).error).toBeNull();
  expect((await svc.from("jobs").select("state, result").eq("id", id).single()).data).toEqual({ state: "done", result: { plan_id: "p" } });
});

test("cancel: a member cancels their own job, not another's; cancel refuses the worker's next write", async () => {
  await clear();
  const id = (await enqueue(centreA, "cancel")).data as string;
  expect((await b.rpc("cancel_job", { p_centre: centreA, p_job: id })).error?.code).toBe("42501");
  await claim("w1");
  expect((await a.rpc("cancel_job", { p_centre: centreA, p_job: id })).data).toBe(true);
  expect((await svc.rpc("record_step", { p_job: id, p_worker: "w1", p_step: "read", p_state: "done" })).error?.message).toContain("job_cancelled");
  expect((await svc.from("jobs").select("state").eq("id", id).single()).data).toEqual({ state: "cancelled" });
  expect((await a.rpc("cancel_job", { p_centre: centreA, p_job: id })).data).toBe(false);
});

test("a platform job has no centre and no member sees it; a centre kind needs a centre", async () => {
  const id = (await svc.rpc("enqueue_job", { p_centre: null, p_kind: "sweep", p_key: `sweep:${stamp}` })).data as string;
  expect(id).toBeString();
  expect((await svc.rpc("enqueue_job", { p_centre: null, p_kind: "sweep", p_key: `sweep:${stamp}` })).data).toBe(id);
  expect((await a.from("jobs").select("id").eq("id", id)).data).toEqual([]);
  expect((await svc.rpc("enqueue_job", { p_centre: null, p_kind: "plan", p_key: "no-centre" })).error).not.toBeNull();
  expect((await a.rpc("enqueue_job", { p_centre: null, p_kind: "sweep", p_key: "mine" })).error?.code).toBe("42501");
});

test("the worker's functions are not the app's", async () => {
  const job = "00000000-0000-0000-0000-000000000000";
  const calls: [string, Record<string, unknown>][] = [
    ["claim_jobs", { p_worker: "me" }],
    ["extend_lease", { p_job: job, p_worker: "me" }],
    ["record_step", { p_job: job, p_worker: "me", p_step: "read", p_state: "done" }],
    ["wait_job", { p_job: job, p_worker: "me", p_step: {}, p_run_at: new Date().toISOString() }],
    ["finish_job", { p_job: job, p_worker: "me", p_result: {} }],
    ["fail_job", { p_job: job, p_worker: "me", p_error: {}, p_retry: false }],
  ];
  for (const [fn, args] of calls) {
    const r = await a.rpc(fn, args);
    expect({ fn, code: r.error?.code }).toEqual({ fn, code: "42501" });
  }
});
