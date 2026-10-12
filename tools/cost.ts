#!/usr/bin/env bun
/** bun cost [--since 30m|2h|1d|7d] [--kinds a,b]: what the local AI calls cost, by kind and model, priced by
 *  api/models.json (D67). Reads the local database's ai_generations with psql (each billed call: a failed one that
 *  carries tokens was billed too); DATABASE_URL names another. */
import table from "../api/models.json" with { type: "json" };
import { must } from "./lib/sh";

export type Generation = { kind: string; model: string; tokens_in: number | null; tokens_out: number | null; cost_paise?: number | null };
export type CostRow = { kind: string; model: string; calls: number; tokensIn: number; tokensOut: number; rupees: number | null };
type Table = { rupeesPerDollar: number; models: Record<string, { inputUsdPerMillion: number; outputUsdPerMillion: number }> };

/** A row's cost in paise: what the API recorded at finish (0029's `cost_paise`), else its tokens priced by the table; null
 *  when neither is known. */
function paiseOf(r: Generation, prices: Table): number | null {
  if (r.cost_paise !== null && r.cost_paise !== undefined) return r.cost_paise;
  const price = prices.models[r.model];
  if (!price) return null;
  const dollars = ((r.tokens_in ?? 0) * price.inputUsdPerMillion + (r.tokens_out ?? 0) * price.outputUsdPerMillion) / 1_000_000;
  return dollars * prices.rupeesPerDollar * 100;
}

/** The rows summed by kind and model, in rupees to the paisa; a group with a row neither recorded nor priced has none. */
export function costTable(rows: Generation[], prices: Table): CostRow[] {
  const sums = new Map<string, CostRow & { paise: number | null }>();
  for (const r of rows) {
    const key = `${r.kind} ${r.model}`;
    const row = sums.get(key) ?? { kind: r.kind, model: r.model, calls: 0, tokensIn: 0, tokensOut: 0, rupees: 0, paise: 0 };
    row.calls += 1;
    row.tokensIn += r.tokens_in ?? 0;
    row.tokensOut += r.tokens_out ?? 0;
    const paise = paiseOf(r, prices);
    row.paise = row.paise === null || paise === null ? null : row.paise + paise;
    sums.set(key, row);
  }
  return [...sums.values()]
    .map(({ paise, ...row }) => ({ ...row, rupees: paise === null ? null : Math.round(paise) / 100 }))
    .sort((a, b) => a.kind.localeCompare(b.kind) || a.model.localeCompare(b.model));
}

const UNITS: Record<string, string> = { m: "minutes", h: "hours", d: "days" };

/** The rows a cost run reads: every call Claude billed (it carries tokens, whatever its status) in the window. */
export function costWhere(since: string, kinds: string[]): string {
  const match = /^(\d+)([mhd])$/.exec(since);
  if (!match) throw new Error(`--since takes a number and m, h or d (30m, 2h, 7d), not ${since}`);
  if (kinds.some((k) => !/^[a-z_0-9]+$/.test(k))) throw new Error("--kinds takes kind names, such as note,can_do");
  const where = [`tokens_in is not null`, `created_at > now() - interval '${match[1]} ${UNITS[match[2] as string]}'`];
  if (kinds.length > 0) where.push(`kind::text in (${kinds.map((k) => `'${k}'`).join(", ")})`);
  return where.join(" and ");
}

/** "15 calls since 30m: ₹2.52", and how many calls the table could not price. */
export function totalLine(priced: CostRow[], since: string): string {
  const total = priced.reduce((sum, r) => sum + (r.rupees ?? 0), 0);
  const calls = priced.reduce((n, r) => n + r.calls, 0);
  const unpriced = priced.filter((r) => r.rupees === null).reduce((n, r) => n + r.calls, 0);
  const note = unpriced > 0 ? ` (${unpriced} ${unpriced === 1 ? "call" : "calls"} not priced)` : "";
  return `${calls} calls since ${since}: ₹${total.toFixed(2)}${note}`;
}

async function main(args: string[]) {
  const flag = (name: string) => {
    const i = args.indexOf(name);
    return i >= 0 ? args[i + 1] : undefined;
  };
  const since = flag("--since") ?? "30m";
  const kinds = flag("--kinds")?.split(",").filter(Boolean) ?? [];
  const url = process.env.DATABASE_URL ?? "postgresql://postgres:postgres@127.0.0.1:54322/postgres";
  const query = `select coalesce(json_agg(json_build_object('kind', kind, 'model', model, 'tokens_in', tokens_in, 'tokens_out', tokens_out, 'cost_paise', cost_paise)), '[]') from public.ai_generations where ${costWhere(since, kinds)}`;
  const rows = JSON.parse(await must(["psql", url, "-Atc", query])) as Generation[];
  const priced = costTable(rows, table);
  for (const r of priced) {
    console.log([r.kind.padEnd(16), r.model.padEnd(18), String(r.calls).padStart(4), String(r.tokensIn).padStart(9), String(r.tokensOut).padStart(9), r.rupees === null ? "  no price" : `₹${r.rupees.toFixed(2)}`.padStart(10)].join(" "));
  }
  console.log(totalLine(priced, since));
}

if (import.meta.main) {
  main(process.argv.slice(2)).catch((e) => {
    console.error((e as Error).message);
    process.exit(1);
  });
}
