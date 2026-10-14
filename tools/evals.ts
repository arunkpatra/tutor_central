#!/usr/bin/env bun
/** bun evals [--kinds a,b] [--cases id,id] [--fake]: the golden sets (api/evals/<kind>/cases.json) run through each kind's agent by
 *  promptfoo (D101): a free javascript assertion (the schema, verify, the case's expectations) and the kind's rubric
 *  graded by Opus 5.5, a model other than any generator. Writes the tests to api/evals/output/tests.yaml, runs promptfoo
 *  (Node, through `bun run`; never npx), runs each failed case once more (D103), then the gate (tools/evals-gate.ts). --fake answers from the fake (AI_FAKE=1),
 *  costs nothing and skips the rubric. The real run needs ANTHROPIC_API_KEY (api/.env.local locally; the repository's
 *  secret in CI). */
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { failedCases, gate, type Results, withRetries } from "./evals-gate";

const ROOT = join(import.meta.dir, "..");
const EVALS = join(ROOT, "api/evals");
export const KINDS = [
  "sheet", "worked_example", "figure", "brief", "check", "placement", "plan", "parse_textbook", "parse_school",
  "note", "can_do", "test_tomorrow", "not_on_track",
] as const;
/** The language anchors (D110): run by name, graded by the free checks alone until the speakers' labels come. */
export const ANCHORS = ["anchor_hi", "anchor_kn"] as const;
const folderOf = (set: string) => (set.startsWith("anchor_") ? join("anchors", set.slice("anchor_".length)) : set);
export const GRADER = "anthropic:messages:claude-opus-5-5";
/** The grader's room: Opus thinks before it grades, and a Kannada note's reasoning spent promptfoo's default 2,048 tokens
 *  with no grade written ("No output", Phase 21). */
const GRADER_PROVIDER = { id: GRADER, config: { max_tokens: 16000 } };

type Case = { id: string; expect: { refused?: boolean } };
type Assertion = { type: "javascript" | "llm-rubric"; value: string; provider?: typeof GRADER_PROVIDER };
export type TestCase = { description: string; vars: { kind: string; id: string }; assert: Assertion[] };

export function kindsAsked(argv: string[]): string[] {
  const at = argv.indexOf("--kinds");
  if (at === -1) return [...KINDS];
  const kinds = (argv[at + 1] ?? "").split(",").filter(Boolean);
  for (const kind of kinds) if (![...KINDS, ...ANCHORS].includes(kind as never)) throw new Error(`${kind} has no golden set`);
  return kinds;
}

/** One test per case: the javascript assertion, and the rubric unless the run is fake or the case expects a refusal. */
export async function testsFor(kinds: string[], options: { fake: boolean; cases?: string[] }): Promise<TestCase[]> {
  const tests: TestCase[] = [];
  for (const kind of kinds) {
    const cases = (await Bun.file(join(EVALS, folderOf(kind), "cases.json")).json()) as Case[];
    const anchor = (ANCHORS as readonly string[]).includes(kind);
    for (const c of cases) {
      if (options.cases && !options.cases.includes(c.id)) continue;
      const assert: Assertion[] = [{ type: "javascript", value: "file://assert.ts" }];
      if (!options.fake && !anchor && !c.expect.refused) assert.push({ type: "llm-rubric", value: `file://${kind}/rubric.md`, provider: GRADER_PROVIDER });
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
  const promptfoo = async (output: string): Promise<Results> => {
    const run = Bun.spawnSync(
      ["bun", "run", "promptfoo", "eval", "-c", "promptfooconfig.yaml", "-o", output, "--no-cache", "--no-progress-bar", "-j", "4"],
      { cwd: EVALS, env, stdout: "inherit", stderr: "inherit" },
    );
    const results = Bun.file(join(EVALS, output));
    if (!(await results.exists())) throw new Error(`promptfoo wrote no results (exit ${run.exitCode})`);
    return (await results.json()) as Results;
  };
  let results = await promptfoo("output/results.json");
  // D103: each failed case gets one fresh run; it counts as failed only if it fails again.
  const failed = fake ? [] : failedCases(results);
  if (failed.length > 0) {
    console.log(`\nretrying ${failed.length} failed case(s) once: ${failed.join(", ")}`);
    await Bun.write(join(EVALS, "output/tests.yaml"), JSON.stringify(await testsFor(kinds, { fake, cases: failed }), null, 2));
    results = withRetries(results, await promptfoo("output/retry.json"));
  }
  const out = gate(results, { fake });
  console.log(`\n${out.table}`);
  if (!out.ok) {
    console.error(`\nthe evals' gate is red:\n${out.failures.map((f) => `  - ${f}`).join("\n")}`);
    process.exit(1);
  }
  console.log("\nthe evals' gate is green");
}
