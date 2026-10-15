import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 21 (D109): the standing cost report (0061): by kind, step and model with the batched calls apart, and by month
// for six months. Read by the platform alone, as every admin read (0047).
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let centreA: string;
const stamp = Date.now();
const india = (d: Date) => new Date(d.getTime() + 5.5 * 3600_000).toISOString().slice(0, 10);
const month = `${india(new Date()).slice(0, 8)}01`;
const lastMonth = (() => {
  const [y, m] = month.split("-").map(Number) as [number, number];
  return m === 1 ? `${y - 1}-12-01` : `${y}-${String(m - 1).padStart(2, "0")}-01`;
})();

type Row = { kind: string; step: string; model: string; paise: number; batched?: boolean };
async function rows(centre: string, list: Row[]) {
  for (const r of list) {
    await sql`insert into public.ai_generations (centre_id, kind, input, model, status, agent_step, batched, cost_paise, finished_at)
      values (${centre}, ${r.kind}, '{}'::jsonb, ${r.model}, 'ok', ${r.step}, ${r.batched ?? false}, ${r.paise}, now())`;
  }
}

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `cost-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Cost A", p_whatsapp: "+919999999999" })).data as string;
  await rows(centreA, [
    { kind: "sheet", step: "draft", model: "claude-sonnet-5-5", paise: 100 },
    { kind: "sheet", step: "check", model: "claude-haiku-5-5", paise: 10 },
    { kind: "note", step: "draft", model: "claude-haiku-5-5", paise: 4, batched: true },
  ]);
});

afterAll(async () => {
  await sql`delete from public.centres where id = ${centreA}`;
  await sql.close();
});

test("the cost by step names a check row apart from its draft, and a batched row apart", async () => {
  const by = (await svc.rpc("admin_cost_by_step", { p_month: month, p_centre: centreA })).data as { kind: string; step: string; model: string; batched: boolean; calls: number; paise: number }[];
  expect(by.filter((r) => r.kind === "sheet").map((r) => [r.step, r.model, r.paise])).toEqual([["draft", "claude-sonnet-5-5", 100], ["check", "claude-haiku-5-5", 10]]);
  expect(by.find((r) => r.kind === "note")).toMatchObject({ step: "draft", batched: true, calls: 1, paise: 4 });
});

test("by month: six months, the batched share apart, per active centre; a month with no batched row shows zero", async () => {
  const months = (await svc.rpc("admin_cost_by_month", { p_centre: centreA })).data as { month: string; calls: number; paise: number; batched_paise: number; active_centres: number; per_active_centre_paise: number }[];
  expect(months).toHaveLength(6);
  expect(months.at(-1)).toMatchObject({ month, calls: 3, paise: 114, batched_paise: 4, active_centres: 1, per_active_centre_paise: 114 });
  expect(months.find((m) => m.month === lastMonth)).toMatchObject({ calls: 0, paise: 0, batched_paise: 0, active_centres: 0, per_active_centre_paise: 0 });
});

test("an internal centre's calls keep their cost in the month but make no active centre (0066)", async () => {
  await svc.from("centres").update({ internal: true }).eq("id", centreA);
  const months = (await svc.rpc("admin_cost_by_month", { p_centre: centreA })).data as { month: string; paise: number; active_centres: number; per_active_centre_paise: number }[];
  await svc.from("centres").update({ internal: false }).eq("id", centreA);
  expect(months.at(-1)).toMatchObject({ month, paise: 114, active_centres: 0, per_active_centre_paise: 0 });
});

test("a member reads neither function", async () => {
  expect((await a.rpc("admin_cost_by_step", { p_month: month })).error?.code).toBe("42501");
  expect((await a.rpc("admin_cost_by_month", {})).error?.code).toBe("42501");
});
