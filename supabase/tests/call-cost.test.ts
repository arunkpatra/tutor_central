import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { costPaise } from "../../api/src/price";
import table from "../../api/models.json" with { type: "json" };
import { type Local, local, userClient } from "./client";

// 0051: the calls made before Phase 17's deploy carry their tokens but no cost, so the portal and the money cap counted
// them as nothing. The migration prices them as the API does at finish (api/src/price.ts, api/models.json).
const MIGRATION = readFileSync(join(import.meta.dir, "..", "migrations", "20261125000051_v3_backfill_call_cost.sql"), "utf8");
let l: Local;
let sql: SQL;
let centre: string;
let me: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  const a = await userClient(l, `call-cost-${stamp}@example.com`);
  me = (await a.auth.getUser()).data.user!.id;
  centre = (await a.rpc("create_centre", { p_name: "Cost", p_whatsapp: "+919999999999" })).data as string;
});
afterAll(async () => {
  await sql.close();
});

test("the migration's prices and rate are api/models.json's", () => {
  const rows = [...MIGRATION.matchAll(/\('(claude-[a-z0-9-]+)', ([\d.]+), ([\d.]+)\)/g)].map((m) => [m[1], Number(m[2]), Number(m[3])]);
  const models = table.models as Record<string, { inputUsdPerMillion: number; outputUsdPerMillion: number }>;
  expect(rows).toEqual(Object.entries(models).map(([name, p]) => [name, p.inputUsdPerMillion, p.outputUsdPerMillion]));
  expect(MIGRATION).toContain(`* ${table.rupeesPerDollar} * 100`);
});

test("a call with tokens and no cost is priced as the API prices it; the rest are left as they are", async () => {
  const calls: [string, number | null, number | null, number | null][] = [
    ["claude-sonnet-5-5", 2044, 4267, null],
    ["claude-haiku-5-5", 742, 69, null],
    ["claude-opus-5-5", 3498, 114, null],
    ["claude-haiku-5-5", null, null, null],
    ["claude-sonnet-5-5", 700, 60, 999],
    ["claude-unknown", 700, 60, null],
  ];
  await sql
    .begin(async (tx) => {
      const ids: string[] = [];
      for (const [model, tin, tout, paise] of calls) {
        const [{ id }] = await tx`insert into public.ai_generations (centre_id, kind, input, model, status, tokens_in, tokens_out, cost_paise, user_id)
          values (${centre}, 'sheet', '{}'::jsonb, ${model}, 'ok', ${tin}, ${tout}, ${paise}, ${me}) returning id`;
        ids.push(id as string);
      }
      await tx.unsafe(MIGRATION);
      const after = await tx`select id, cost_paise from public.ai_generations where id in ${tx(ids)}`;
      const cost = (id: string) => after.find((r: { id: string }) => r.id === id).cost_paise as number | null;
      expect(cost(ids[0]!)).toBe(costPaise("claude-sonnet-5-5", 2044, 4267));
      expect(cost(ids[0]!)).toBe(397);
      expect(cost(ids[1]!)).toBe(costPaise("claude-haiku-5-5", 742, 69));
      expect(cost(ids[2]!)).toBe(costPaise("claude-opus-5-5", 3498, 114));
      expect(cost(ids[3]!)).toBeNull();
      expect(cost(ids[4]!)).toBe(999);
      expect(cost(ids[5]!)).toBeNull();
      throw new Error("rollback");
    })
    .catch((e: Error) => {
      if (e.message !== "rollback") throw e;
    });
});
