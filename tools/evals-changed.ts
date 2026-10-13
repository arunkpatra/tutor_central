#!/usr/bin/env bun
/** bun tools/evals-changed.ts <base>..<head>: the kinds whose evals a change must run (D101), from `git diff
 *  --name-only`: a kind's prompt, agent or golden set names that kind; what every kind shares (the shared prompt words,
 *  the agent, its check, the rubric's common lines, the schemas, the evals' provider and assertion) names all nine;
 *  anything else names none. Prints them comma-separated, or `none`. */
import { KINDS } from "./evals";

const EVERY = ["api/src/prompts/shared.ts", "api/src/agents/agent.ts", "api/src/agents/check.ts", "api/src/agents/kinds/rubric.ts", "api/src/agents/kinds/index.ts", "api/src/schemas.ts", "api/evals/provider.ts", "api/evals/assert.ts", "api/evals/promptfooconfig.yaml", "api/src/evals/cases.ts", "api/src/agents/maths.ts", "api/src/evals/runner.ts"];

/** A file name in kebab case for a kind in snake case (`worked-example.ts` for `worked_example`). */
const fileOf = (kind: string) => kind.replaceAll("_", "-");

export function kindsChanged(paths: string[]): string[] {
  if (paths.some((p) => EVERY.includes(p))) return [...KINDS].sort();
  const kinds = new Set<string>();
  for (const path of paths) {
    for (const kind of KINDS) {
      if (path === `api/src/prompts/${fileOf(kind)}.ts` || path === `api/src/agents/kinds/${fileOf(kind)}.ts` || path.startsWith(`api/evals/${kind}/`)) kinds.add(kind);
    }
  }
  return [...kinds].sort();
}

if (import.meta.main) {
  const range = process.argv[2];
  if (!range) throw new Error("usage: bun tools/evals-changed.ts <base>..<head>");
  const diff = Bun.spawnSync(["git", "diff", "--name-only", range], { stdout: "pipe", stderr: "pipe" });
  if (diff.exitCode !== 0) throw new Error(`git diff ${range}: ${diff.stderr.toString()}`);
  const kinds = kindsChanged(diff.stdout.toString().split("\n").filter(Boolean));
  console.log(kinds.length > 0 ? kinds.join(",") : "none");
}
