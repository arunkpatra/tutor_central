#!/usr/bin/env bun
/** bun tools/evals-gate.ts <results.json> [--fake]: the evals' gate (D101) over promptfoo's output. Every case must pass
 *  its javascript assertion (the schema, the kind's verify, the case's expectations); each kind's rubric, graded by Opus
 *  5.5, must pass at least 85% of its cases (a fake run skips the rubric). Prints a table; exit 1 naming each failure. */
import table from "../api/models.json" with { type: "json" };

export const RUBRIC_GATE = 0.85;

type Component = { pass: boolean; assertion?: { type?: string }; reason?: string };
type Row = {
  vars: { kind: string; id: string };
  cost?: number;
  error?: string;
  response?: { metadata?: { repaired?: boolean } };
  gradingResult: { componentResults?: Component[]; tokensUsed?: { prompt?: number; completion?: number } } | null;
};
/** The grader's price (Opus 5.5, models.json): promptfoo counts its tokens apart from the provider's cost. */
const GRADER_PRICE = (table.models as Record<string, { inputUsdPerMillion: number; outputUsdPerMillion: number }>)["claude-opus-5-5"];
export type Results = { results: { results: Row[] } };
type Tally = { cases: number; js: number; rubricPass: number; rubricOf: number; repaired: number; usd: number };

export function gate(results: Results, options: { fake: boolean }): { ok: boolean; failures: string[]; table: string } {
  const kinds = new Map<string, Tally>();
  const failures: string[] = [];
  for (const row of results.results.results) {
    const kind = row.vars.kind;
    const t = kinds.get(kind) ?? { cases: 0, js: 0, rubricPass: 0, rubricOf: 0, repaired: 0, usd: 0 };
    kinds.set(kind, t);
    t.cases += 1;
    const graded = row.gradingResult?.tokensUsed;
    t.usd += (row.cost ?? 0) + ((graded?.prompt ?? 0) * (GRADER_PRICE?.inputUsdPerMillion ?? 0) + (graded?.completion ?? 0) * (GRADER_PRICE?.outputUsdPerMillion ?? 0)) / 1_000_000;
    if (row.response?.metadata?.repaired) t.repaired += 1;
    const parts = row.gradingResult?.componentResults ?? [];
    const js = parts.find((p) => p.assertion?.type === "javascript");
    if (row.error || !js) failures.push(`${kind}: ${row.vars.id}: ${row.error ?? "no result"}`);
    else if (js.pass) t.js += 1;
    else failures.push(`${kind}: ${row.vars.id}: ${js.reason ?? "failed"}`);
    const rubric = parts.find((p) => p.assertion?.type === "llm-rubric");
    if (rubric) {
      t.rubricOf += 1;
      if (rubric.pass) t.rubricPass += 1;
    }
  }
  const lines = ["| kind | cases | schema, verify, expect | rubric | repaired | cost |", "|---|---|---|---|---|---|"];
  for (const [kind, t] of [...kinds.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    const rate = t.rubricOf === 0 ? null : t.rubricPass / t.rubricOf;
    if (!options.fake && rate !== null && rate < RUBRIC_GATE) {
      failures.push(`${kind}: the rubric passed ${t.rubricPass} of ${t.rubricOf} (${Math.round(rate * 100)}%), under ${RUBRIC_GATE * 100}%`);
    }
    const rubric = options.fake || rate === null ? "skipped" : `${Math.round(rate * 100)}% (${t.rubricPass}/${t.rubricOf})`;
    lines.push(`| ${kind} | ${t.cases} | ${t.js}/${t.cases} | ${rubric} | ${t.repaired} | ₹${(t.usd * table.rupeesPerDollar).toFixed(2)} |`);
  }
  return { ok: failures.length === 0, failures, table: lines.join("\n") };
}

if (import.meta.main) {
  const [path] = process.argv.slice(2).filter((a) => !a.startsWith("--"));
  if (!path) throw new Error("usage: bun tools/evals-gate.ts <results.json> [--fake]");
  const out = gate(await Bun.file(path).json(), { fake: process.argv.includes("--fake") });
  console.log(out.table);
  if (!out.ok) {
    console.error(`\nthe evals' gate is red:\n${out.failures.map((f) => `  - ${f}`).join("\n")}`);
    process.exit(1);
  }
  console.log("\nthe evals' gate is green");
}
