#!/usr/bin/env bun
/** bun evals [--kinds a,b] [--cases id,id] [--fake]: the golden sets (api/evals/<kind>/cases.json) run through each kind's agent by
 *  promptfoo (D101): a free javascript assertion (the schema, verify, the case's expectations) and the kind's rubric
 *  graded by Opus 5.5, a model other than any generator. Writes the tests to api/evals/output/tests.yaml, runs promptfoo
 *  (Node, through `bun run`; never npx), then the gate (tools/evals-gate.ts). --fake answers from the fake (AI_FAKE=1),
 *  costs nothing and skips the rubric. The real run needs ANTHROPIC_API_KEY (api/.env.local locally; the repository's
 *  secret in CI). */
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { gate } from "./evals-gate";

const ROOT = join(import.meta.dir, "..");
const EVALS = join(ROOT, "api/evals");
export const KINDS = ["sheet", "worked_example", "figure", "brief", "check", "placement", "plan", "parse_textbook", "parse_school"] as const;
export const GRADER = "anthropic:messages:claude-opus-5-5";

type Case = { id: string; expect: { refused?: boolean } };
type Assertion = { type: "javascript" | "llm-rubric"; value: string; provider?: string };
export type TestCase = { description: string; vars: { kind: string; id: string }; assert: Assertion[] };

export function kindsAsked(argv: string[]): string[] {
  const at = argv.indexOf("--kinds");
  if (at === -1) return [...KINDS];
  const kinds = (argv[at + 1] ?? "").split(",").filter(Boolean);
  for (const kind of kinds) if (!(KINDS as readonly string[]).includes(kind)) throw new Error(`${kind} has no golden set`);
  return kinds;
}

/** One test per case: the javascript assertion, and the rubric unless the run is fake or the case expects a refusal. */
export async function testsFor(kinds: string[], options: { fake: boolean; cases?: string[] }): Promise<TestCase[]> {
  const tests: TestCase[] = [];
  for (const kind of kinds) {
    const cases = (await Bun.file(join(EVALS, kind, "cases.json")).json()) as Case[];
    for (const c of cases) {
      if (options.cases && !options.cases.includes(c.id)) continue;
      const assert: Assertion[] = [{ type: "javascript", value: "file://assert.ts" }];
      if (!options.fake && !c.expect.refused) assert.push({ type: "llm-rubric", value: `file://${kind}/rubric.md`, provider: GRADER });
      tests.push({ description: c.id, vars: { kind, id: c.id }, assert });
    }
  }
  return tests;
}

/** The key from api/.env.local when the environment has none (a local run). */
async function apiKey(): Promise<string | undefined> {
  if (process.env.ANTHROPIC_API_KEY) return process.env.ANTHROPIC_API_KEY;
  const file = Bun.file(join(ROOT, "api/.env.local"));
  if (!(await file.exists())) return undefined;
  return (await file.text()).match(/^ANTHROPIC_API_KEY=(.+)$/m)?.[1]?.trim().replace(/^(["'])(.*)\1$/, "$2");
}

if (import.meta.main) {
  const fake = process.argv.includes("--fake");
  const kinds = kindsAsked(process.argv.slice(2));
  const at = process.argv.indexOf("--cases");
  const cases = at === -1 ? undefined : (process.argv[at + 1] ?? "").split(",").filter(Boolean);
  mkdirSync(join(EVALS, "output"), { recursive: true });
  // JSON is YAML: promptfoo reads the tests file as either.
  await Bun.write(join(EVALS, "output/tests.yaml"), JSON.stringify(await testsFor(kinds, { fake, cases }), null, 2));
  const key = await apiKey();
  if (!fake && !key) throw new Error("ANTHROPIC_API_KEY is needed for a real run (or --fake)");
  const env = {
    ...process.env,
    ...(key ? { ANTHROPIC_API_KEY: key } : {}),
    ...(fake ? { AI_FAKE: "1" } : {}),
    PROMPTFOO_DISABLE_TELEMETRY: "1",
    PROMPTFOO_DISABLE_UPDATE: "1",
    PROMPTFOO_CONFIG_DIR: join(EVALS, ".promptfoo"),
  };
  const run = Bun.spawnSync(
    ["bun", "run", "promptfoo", "eval", "-c", "promptfooconfig.yaml", "-o", "output/results.json", "--no-cache", "--no-progress-bar", "-j", "4"],
    { cwd: EVALS, env, stdout: "inherit", stderr: "inherit" },
  );
  const results = Bun.file(join(EVALS, "output/results.json"));
  if (!(await results.exists())) throw new Error(`promptfoo wrote no results (exit ${run.exitCode})`);
  const out = gate(await results.json(), { fake });
  console.log(`\n${out.table}`);
  if (!out.ok) {
    console.error(`\nthe evals' gate is red:\n${out.failures.map((f) => `  - ${f}`).join("\n")}`);
    process.exit(1);
  }
  console.log("\nthe evals' gate is green");
}
