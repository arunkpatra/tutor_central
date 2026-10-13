import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import table from "../../api/models.json" with { type: "json" };
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 20 (D99, D100, migration 0052): the model per kind and step in `ai_models`, seeded from api/models.json and read by
// the platform alone; a call's agent step, of which only a draft counts against the allowance; the nightly evals' schedule.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let centreA: string;
const stamp = Date.now();
const OTHER: Record<string, string> = {
  "claude-haiku-5-5": "claude-sonnet-5-5",
  "claude-sonnet-5-5": "claude-haiku-5-5",
  "claude-opus-5-5": "claude-sonnet-5-5",
};
type Row = { kind: string; step: string; model: string; effort: string; fallback_model: string | null; enabled: boolean };

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `models-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Centre A", p_whatsapp: "+919999999999" })).data as string;
});
afterAll(async () => {
  await sql.close();
});

test("ai_models is seeded from models.json: a draft, a check on the other tier and a repair per work type", async () => {
  const rows = (await svc.rpc("ai_models_current")).data as Row[];
  for (const [kind, model] of Object.entries(table.work)) {
    const draft = rows.find((r) => r.kind === kind && r.step === "draft");
    const check = rows.find((r) => r.kind === kind && r.step === "check");
    const repair = rows.find((r) => r.kind === kind && r.step === "repair");
    expect({ kind, draft: draft?.model, check: check?.model, repair: repair?.model, enabled: draft?.enabled }).toEqual({
      kind,
      draft: model,
      check: OTHER[model],
      repair: model,
      enabled: true,
    });
    expect({ kind, fallback: draft?.fallback_model }).toEqual({ kind, fallback: OTHER[model] });
    expect({ kind, effort: repair?.effort }).toEqual({ kind, effort: draft?.effort });
  }
  expect(rows.length).toBe(Object.keys(table.work).length * 3);
  const high = rows.filter((r) => r.step === "draft" && r.effort === "high").map((r) => r.kind).sort();
  expect(high).toEqual(["check_paper", "mock", "scan_register"]);
});

test("the current row is the newest since; a member reads nothing and writes nothing", async () => {
  await sql`insert into public.ai_models (kind, step, model, effort, enabled, set_by, note)
    values ('sheet_to_5', 'draft', 'claude-sonnet-5-5', 'medium', false, 'test', 'switched off')`;
  const rows = (await svc.rpc("ai_models_current")).data as Row[];
  expect(rows.find((r) => r.kind === "sheet_to_5" && r.step === "draft")).toMatchObject({ model: "claude-sonnet-5-5", enabled: false });
  expect((await a.from("ai_models").select("kind")).data ?? []).toEqual([]);
  expect((await a.from("ai_models").insert({ kind: "x", step: "draft", model: "m", effort: "medium" })).error).not.toBeNull();
  expect((await a.rpc("ai_models_current")).error?.code).toBe("42501");
  // Append-only: a change is a new row, even for the platform.
  expect((await svc.from("ai_models").update({ enabled: true }).eq("set_by", "test")).error?.code).toBe("42501");
  expect((await svc.from("ai_models").delete().eq("set_by", "test")).error?.code).toBe("42501");
  await sql`delete from public.ai_models where set_by = 'test'`;
});

test("a check row counts against the cost and not the allowance", async () => {
  await sql`update public.centres set ai_allowance = 1 where id = ${centreA}`;
  const start = (key: string, model: string, step?: string) =>
    a.rpc("start_ai_call", {
      p_centre: centreA,
      p_kind: "sheet",
      p_input: {},
      p_model: model,
      p_key: key,
      ...(step ? { p_agent_step: step } : {}),
    });
  expect((await start(`d-${stamp}`, "claude-haiku-5-5", "draft")).error).toBeNull();
  expect((await start(`d-${stamp}:check`, "claude-sonnet-5-5", "check")).error).toBeNull();
  expect((await start(`d-${stamp}:repair`, "claude-haiku-5-5", "repair")).error).toBeNull();
  expect((await start(`d-${stamp}:repair:check`, "claude-sonnet-5-5", "check")).error).toBeNull();
  expect((await start(`d2-${stamp}`, "claude-haiku-5-5")).error?.message).toContain("ai_limit_reached");
  const rows = await sql`select idempotency_key, agent_step from public.ai_generations where centre_id = ${centreA} order by created_at`;
  expect(rows.map((r: { agent_step: string }) => r.agent_step)).toEqual(["draft", "check", "repair", "check"]);
  expect((await a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: {}, p_model: "m", p_key: `x-${stamp}`, p_agent_step: "nonsense" })).error).not.toBeNull();
});

test("a check, repair or grade only hangs off a live draft of the centre, by its key", async () => {
  const step = (key: string | null, agent: string) =>
    a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: {}, p_model: "claude-sonnet-5-5", p_key: key, p_agent_step: agent });
  expect((await step(null, "check")).error?.message).toContain("ai_step_orphan");
  expect((await step(`nothing-${stamp}:check`, "check")).error?.message).toContain("ai_step_orphan");
  expect((await step(`free-${stamp}`, "check")).error?.message).toContain("ai_step_orphan");
  expect((await step(`d-${stamp}:grade`, "grade")).error).toBeNull();
  // A draft of another centre is no parent.
  const b = await userClient(l, `models-b-${stamp}@example.com`);
  const centreB = (await b.rpc("create_centre", { p_name: "Centre B", p_whatsapp: "+919999999998" })).data as string;
  const other = await b.rpc("start_ai_call", { p_centre: centreB, p_kind: "sheet", p_input: {}, p_model: "m", p_key: `d-${stamp}:check`, p_agent_step: "check" });
  expect(other.error?.message).toContain("ai_step_orphan");
});

test("the platform finishes a row with its cached tokens", async () => {
  const [row] = await sql`select id from public.ai_generations where idempotency_key = ${`d-${stamp}:check`}`;
  const done = await svc.from("ai_generations").update({ status: "ok", tokens_in: 1000, tokens_out: 100, tokens_cached: 1000, finished_at: new Date().toISOString() }).eq("id", row.id).select("tokens_cached").single();
  expect(done.error).toBeNull();
  expect(done.data?.tokens_cached).toBe(1000);
});

test("schedule_evals queues one eval_run for India's day, once", async () => {
  const now = "2026-10-20T10:00:00Z";
  expect((await svc.rpc("schedule_evals", { p_now: now })).data).toBe(1);
  expect((await svc.rpc("schedule_evals", { p_now: now })).data).toBe(0);
  const [job] = await sql`select kind, centre_id, idempotency_key, input->>'day' as day, run_at from public.jobs where idempotency_key = 'evals:2026-10-20'`;
  expect(job).toMatchObject({ kind: "eval_run", day: "2026-10-20", centre_id: null });
  expect(new Date(job.run_at).toISOString()).toBe("2026-10-19T20:30:00.000Z");
  expect((await a.rpc("schedule_evals", { p_now: now })).error?.code).toBe("42501");
  const [cron] = await sql`select schedule, command from cron.job where jobname = 'schedule_evals'`;
  expect(cron).toEqual({ schedule: "35 20 * * *", command: "select public.schedule_evals()" });
  await sql`delete from public.jobs where idempotency_key = 'evals:2026-10-20'`;
});
