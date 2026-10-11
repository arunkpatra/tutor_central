#!/usr/bin/env bun
/** bun cost [--since 30m|2h|1d|7d] [--kinds a,b]: what the local AI calls cost, by kind and model, priced by
 *  api/models.json (D67). Reads the local database's ai_generations (status ok) with psql; DATABASE_URL names another. */
import table from "../api/models.json" with { type: "json" };
import { must } from "./lib/sh";

export type Generation = { kind: string; model: string; tokens_in: number | null; tokens_out: number | null };
export type CostRow = { kind: string; model: string; calls: number; tokensIn: number; tokensOut: number; rupees: number | null };
type Table = { rupeesPerDollar: number; models: Record<string, { inputUsdPerMillion: number; outputUsdPerMillion: number }> };

/** The rows summed by kind and model, in rupees to the paisa; a model the table does not price has no rupees. */
export function costTable(rows: Generation[], prices: Table): CostRow[] {
  const sums = new Map<string, CostRow>();
  for (const r of rows) {
    const key = `${r.kind} ${r.model}`;
    const row = sums.get(key) ?? { kind: r.kind, model: r.model, calls: 0, tokensIn: 0, tokensOut: 0, rupees: 0 };
    row.calls += 1;
    row.tokensIn += r.tokens_in ?? 0;
    row.tokensOut += r.tokens_out ?? 0;
    sums.set(key, row);
  }
  return [...sums.values()]
    .map((row) => {
      const price = prices.models[row.model];
      if (!price) return { ...row, rupees: null };
      const dollars = (row.tokensIn * price.inputUsdPerMillion + row.tokensOut * price.outputUsdPerMillion) / 1_000_000;
      return { ...row, rupees: Math.round(dollars * prices.rupeesPerDollar * 100) / 100 };
    })
    .sort((a, b) => a.kind.localeCompare(b.kind) || a.model.localeCompare(b.model));
}

const UNITS: Record<string, string> = { m: "minutes", h: "hours", d: "days" };

async function main(args: string[]) {
  const flag = (name: string) => {
    const i = args.indexOf(name);
    return i >= 0 ? args[i + 1] : undefined;
  };
  const since = flag("--since") ?? "30m";
  const match = /^(\d+)([mhd])$/.exec(since);
  if (!match) throw new Error(`--since takes a number and m, h or d (30m, 2h, 7d), not ${since}`);
  const kinds = flag("--kinds")?.split(",").filter(Boolean) ?? [];
  if (kinds.some((k) => !/^[a-z_0-9]+$/.test(k))) throw new Error("--kinds takes kind names, such as note,can_do");
  const url = process.env.DATABASE_URL ?? "postgresql://postgres:postgres@127.0.0.1:54322/postgres";
  const where = [`status = 'ok'`, `created_at > now() - interval '${match[1]} ${UNITS[match[2] as string]}'`];
  if (kinds.length > 0) where.push(`kind::text in (${kinds.map((k) => `'${k}'`).join(", ")})`);
  const query = `select coalesce(json_agg(json_build_object('kind', kind, 'model', model, 'tokens_in', tokens_in, 'tokens_out', tokens_out)), '[]') from public.ai_generations where ${where.join(" and ")}`;
  const rows = JSON.parse(await must(["psql", url, "-Atc", query])) as Generation[];
  const priced = costTable(rows, table);
  for (const r of priced) {
    console.log([r.kind.padEnd(16), r.model.padEnd(18), String(r.calls).padStart(4), String(r.tokensIn).padStart(9), String(r.tokensOut).padStart(9), r.rupees === null ? "  no price" : `₹${r.rupees.toFixed(2)}`.padStart(10)].join(" "));
  }
  const total = priced.reduce((sum, r) => sum + (r.rupees ?? 0), 0);
  console.log(`${priced.reduce((n, r) => n + r.calls, 0)} calls since ${since}: ₹${total.toFixed(2)}`);
}

if (import.meta.main) {
  main(process.argv.slice(2)).catch((e) => {
    console.error((e as Error).message);
    process.exit(1);
  });
}
