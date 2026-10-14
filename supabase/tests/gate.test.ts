import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// The recorded call (D76, D84): start_ai_call's key, lock and allowance; the gate trigger; the sweep.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let centreA: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `gate-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Gate A" })).data as string;
});
afterAll(() => sql.close());

const start = (args: Record<string, unknown>) =>
  a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: { topic: "Fractions" }, p_model: "claude-haiku-5-5", ...args });

test("a first call makes a pending row with its key, hash, request id and user", async () => {
  const r = await start({ p_key: "k1", p_input_hash: "h1", p_request_id: "11111111-1111-1111-1111-111111111111" });
  expect(r.error).toBeNull();
  expect(r.data).toMatchObject({ replay: false, status: "pending" });
  const row = await sql`select idempotency_key, input_hash, request_id, user_id, job_id, status from public.ai_generations where id = ${r.data.id}`;
  expect(row[0]).toMatchObject({ idempotency_key: "k1", input_hash: "h1", request_id: "11111111-1111-1111-1111-111111111111", job_id: null, status: "pending" });
  expect(row[0].user_id).not.toBeNull();
});

test("the same key with the same body replays: pending while pending, the output once finished; never a new row", async () => {
  const first = await start({ p_key: "k2", p_input_hash: "h2" });
  const pending = await start({ p_key: "k2", p_input_hash: "h2" });
  expect(pending.data).toEqual({ id: first.data.id, replay: true, status: "pending", output: null });
  const done = { status: "ok", output: '{"q":1}', tokens_in: 5, tokens_out: 7, cost_paise: 3, latency_ms: 900, stop_reason: "end_turn", finished_at: new Date().toISOString() };
  expect((await svc.from("ai_generations").update(done).eq("id", first.data.id)).error).toBeNull();
  const replayed = await start({ p_key: "k2", p_input_hash: "h2" });
  expect(replayed.data).toEqual({ id: first.data.id, replay: true, status: "ok", output: '{"q":1}' });
  expect((await sql`select count(*)::int as n from public.ai_generations where idempotency_key = 'k2'`)[0].n).toBe(1);
});

test("a member writes no row, pending or finished: the platform finishes it (the review's finding 7)", async () => {
  const r = await start({ p_key: `final-${stamp}`, p_input_hash: "h" });
  expect((await a.from("ai_generations").update({ status: "failed", cost_paise: 0 }).eq("id", r.data.id)).error?.code).toBe("42501");
  const finish = { status: "ok", output: "{}", tokens_in: 9, tokens_out: 9, cost_paise: 40, finished_at: new Date().toISOString() };
  expect((await svc.from("ai_generations").update(finish).eq("id", r.data.id)).error).toBeNull();
  expect((await a.from("ai_generations").update({ cost_paise: 0 }).eq("id", r.data.id)).error?.code).toBe("42501");
  expect((await sql`select cost_paise, status from public.ai_generations where id = ${r.data.id}`)[0]).toEqual({ cost_paise: 40, status: "ok" });
  expect((await svc.from("ai_generations").update({ error_reason: "checked" }).eq("id", r.data.id)).error).toBeNull();
});

test("a call names only its own centre's job", async () => {
  const other = await userClient(l, `gate-job-${stamp}@example.com`);
  const centreB = (await other.rpc("create_centre", { p_name: "Gate Job" })).data as string;
  const job = (await svc.rpc("enqueue_job", { p_centre: centreB, p_kind: "plan", p_key: `gate-foreign-${stamp}` })).data as string;
  expect((await start({ p_job: job })).error).not.toBeNull();
  await sql`delete from public.jobs where id = ${job}`;
});

test("the money cap counts the month's cost for a V1 call too, not the last day's", async () => {
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`update public.centres set ai_allowance_paise = 100 where id = ${centreA}`;
  await sql`insert into public.ai_generations (centre_id, kind, input, status, cost_paise, created_at) values (${centreA}, 'sheet', '{}', 'ok', 100,
    greatest(date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata', now() - interval '30 hours'))`;
  expect((await start({ p_kind: "homework" })).error?.message).toContain("ai_limit_reached");
  await sql`update public.centres set ai_allowance_paise = 0 where id = ${centreA}`;
});

test("a key with another body is refused; a key whose row failed is a new call; a key older than a day is a new call", async () => {
  const first = await start({ p_key: "k3", p_input_hash: "h3" });
  expect((await start({ p_key: "k3", p_input_hash: "other" })).error?.message).toContain("ai_key_reused");
  await svc.from("ai_generations").update({ status: "failed" }).eq("id", first.data.id);
  const again = await start({ p_key: "k3", p_input_hash: "h3" });
  expect(again.data.replay).toBe(false);
  await sql`update public.ai_generations set created_at = now() - interval '25 hours' where id = ${again.data.id}`;
  expect((await start({ p_key: "k3", p_input_hash: "h3" })).data.replay).toBe(false);
});

test("the same key in another centre is that centre's own", async () => {
  const other = await userClient(l, `gate-b-${stamp}@example.com`);
  const centreB = (await other.rpc("create_centre", { p_name: "Gate B" })).data as string;
  const mine = await start({ p_key: "shared", p_input_hash: "h" });
  const theirs = await other.rpc("start_ai_call", { p_centre: centreB, p_kind: "sheet", p_input: {}, p_model: "m", p_key: "shared", p_input_hash: "x" });
  expect(theirs.error).toBeNull();
  expect(theirs.data.replay).toBe(false);
  expect(theirs.data.id).not.toBe(mine.data.id);
});

test("the allowance is the centre's column; two starts at once cannot both pass it", async () => {
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`update public.centres set ai_allowance = 1 where id = ${centreA}`;
  const [one, two] = await Promise.all([start({ p_key: "race-1" }), start({ p_key: "race-2" })]);
  const errors = [one, two].filter((r) => r.error?.message.includes("ai_limit_reached"));
  expect(errors.length).toBe(1);
  expect(errors[0]?.error?.details).toBe("1");
  expect((await sql`select count(*)::int as n from public.ai_generations where centre_id = ${centreA}`)[0].n).toBe(1);
  await sql`update public.centres set ai_allowance = 600 where id = ${centreA}`;
});

test("a money cap, when set, is read from the month's cost", async () => {
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`update public.centres set ai_allowance_paise = 100 where id = ${centreA}`;
  await sql`insert into public.ai_generations (centre_id, kind, input, status, cost_paise) values (${centreA}, 'sheet', '{}', 'ok', 100)`;
  expect((await start({})).error?.message).toContain("ai_limit_reached");
  await sql`update public.centres set ai_allowance_paise = 0 where id = ${centreA}`;
  expect((await start({})).error).toBeNull();
});

test("the owner cannot raise the allowance; Settings' columns still save", async () => {
  expect((await a.from("centres").update({ ai_allowance: 5000 }).eq("id", centreA)).error?.code).toBe("42501");
  expect((await a.from("centres").update({ ai_allowance_paise: 1 }).eq("id", centreA)).error?.code).toBe("42501");
  const ok = await a
    .from("centres")
    .update({ name: "Gate A", upi_id: "gate@okbank", payment_link: "https://pay.example/g", send_receipts: false, whatsapp_number: "+919999999991", ai_consent_at: new Date().toISOString(), upi_confirmed_at: null })
    .eq("id", centreA)
    .select("name")
    .single();
  expect(ok.data).toEqual({ name: "Gate A" });
  expect((await svc.from("centres").update({ ai_allowance: 700 }).eq("id", centreA).select("ai_allowance").single()).data).toEqual({ ai_allowance: 700 });
  await sql`update public.centres set ai_allowance = 600 where id = ${centreA}`;
});

test("a row cannot be inserted around the gate; the platform and the seed can", async () => {
  expect((await a.from("ai_generations").insert({ centre_id: centreA, kind: "sheet", input: {} })).error?.code).toBe("42501");
  expect((await svc.from("ai_generations").insert({ centre_id: centreA, kind: "sheet", input: {}, status: "ok" })).error).toBeNull();
  expect((await sql`insert into public.ai_generations (centre_id, kind, input) values (${centreA}, 'sheet', '{}') returning id`).length).toBe(1);
});

test("the platform starts a call for a job with no user", async () => {
  const job = (await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: `gate-job-${stamp}` })).data as string;
  const r = await svc.rpc("start_ai_call", { p_centre: centreA, p_kind: "plan", p_input: {}, p_model: "claude-sonnet-5-5", p_key: `${job}:name`, p_job: job });
  expect(r.error).toBeNull();
  const row = await sql`select user_id, job_id from public.ai_generations where id = ${r.data.id}`;
  expect(row[0]).toEqual({ user_id: null, job_id: job });
  await sql`delete from public.jobs where id = ${job}`;
});

test("a batched row is left pending for a day: a Message Batch may take hours (D108)", async () => {
  await svc.rpc("close_pending_generations");
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`insert into public.ai_generations (centre_id, kind, input, status, batched, created_at) values
    (${centreA}, 'sheet', '{}', 'pending', true, now() - interval '3 hours'), (${centreA}, 'sheet', '{}', 'pending', true, now() - interval '26 hours')`;
  expect((await svc.rpc("close_pending_generations")).data).toBe(1);
  const rows = await sql`select status from public.ai_generations where centre_id = ${centreA} order by created_at desc`;
  expect(rows.map((r: { status: string }) => r.status)).toEqual(["pending", "failed"]);
});

test("the nightly's eval_run job starts a parent's-message kind with no student; any other call of that kind needs one (Phase 21 hand run 11)", async () => {
  const evals = (await svc.rpc("enqueue_job", { p_centre: null, p_kind: "eval_run", p_key: `gate-evals-${stamp}` })).data as string;
  const plan = (await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: `gate-plan-${stamp}` })).data as string;
  const asked = (job: string | null) => svc.rpc("start_ai_call", { p_centre: centreA, p_kind: "can_do", p_input: {}, p_model: "claude-haiku-5-5", p_key: `gate-cando-${job ?? "none"}-${stamp}`, p_job: job });
  expect((await asked(evals)).error).toBeNull();
  expect((await asked(plan)).error?.message).toContain("ai_consent_missing");
  expect((await asked(null)).error?.message).toContain("ai_consent_missing");
  // A member naming the nightly's job is still asked for the student.
  const member = await a.rpc("start_ai_call", { p_centre: centreA, p_kind: "can_do", p_input: {}, p_model: "claude-haiku-5-5", p_key: `gate-cando-member-${stamp}`, p_job: evals });
  expect(member.error?.message).toContain("ai_consent_missing");
  await sql`delete from public.jobs where id in (${evals}, ${plan})`;
});

test("the nightly's eval_run job starts a progress note's case with no student; any other progress note needs one (the review of Phase 21, R-api-3)", async () => {
  const evals = (await svc.rpc("enqueue_job", { p_centre: null, p_kind: "eval_run", p_key: `gate-evals-pn-${stamp}` })).data as string;
  const asked = (job: string | null) => svc.rpc("start_ai_call", { p_centre: centreA, p_kind: "progress_note", p_input: {}, p_model: "claude-haiku-5-5", p_key: `gate-pn-${job ?? "none"}-${stamp}`, p_job: job });
  expect((await asked(evals)).error).toBeNull();
  expect((await asked(null)).error?.message).toContain("ai_consent_missing");
  await sql`delete from public.jobs where id = ${evals}`;
});

test("start_ai_generation still answers an id and shares the gate", async () => {
  const r = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "homework", p_input: {}, p_model: "m" });
  expect(r.error).toBeNull();
  expect(typeof r.data).toBe("string");
});

test("close_pending_generations closes a 10-minute pending row and leaves a 2-minute one", async () => {
  await svc.rpc("close_pending_generations");
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`insert into public.ai_generations (centre_id, kind, input, status, created_at) values
    (${centreA}, 'sheet', '{}', 'pending', now() - interval '11 minutes'), (${centreA}, 'sheet', '{}', 'pending', now() - interval '2 minutes')`;
  expect((await a.rpc("close_pending_generations")).error?.code).toBe("42501");
  expect((await svc.rpc("close_pending_generations")).data).toBe(1);
  const rows = await sql`select status, error_reason from public.ai_generations where centre_id = ${centreA} order by created_at`;
  expect(rows.map((r: { status: string; error_reason: string | null }) => [r.status, r.error_reason])).toEqual([
    ["failed", "swept"],
    ["pending", null],
  ]);
});
