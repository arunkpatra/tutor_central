#!/usr/bin/env bun
/** bun evals-changed [<base>..<head>]: the kinds whose evals a change must run before its pull request (D101; by hand,
 *  D112: docs/working/pre-pr-proof.md). With no range, everything this branch changes from main, committed or not. From
 *  `git diff --name-only`: a kind's prompt, agent or golden set names that kind; what every kind shares (the shared prompt words,
 *  the agent, its check, the rubric's common lines, the schemas, the evals' provider and assertion) names every kind;
 *  the parents' shared rules name the four message kinds and the language anchors (D110); an anchor's folder names its
 *  set; anything else names none. Prints them comma-separated, or `none`. */
import { ANCHORS, KINDS } from "./evals";

const EVERY = ["api/src/prompts/shared.ts", "api/src/agents/agent.ts", "api/src/agents/check.ts", "api/src/agents/kinds/rubric.ts", "api/src/agents/kinds/index.ts", "api/src/schemas.ts", "api/evals/provider.ts", "api/evals/assert.ts", "api/evals/promptfooconfig.yaml", "api/src/evals/cases.ts", "api/src/agents/maths.ts", "api/src/evals/runner.ts"];

/** A file name in kebab case for a kind in snake case (`worked-example.ts` for `worked_example`). */
const fileOf = (kind: string) => kind.replaceAll("_", "-");

/** What some kinds share: the parents' message rules and words (V1's progress note reads its sign-off rule and the first
 *  name), the numbers a caption or a message is read for, and homework's and a worksheet's one agent file. */
const PARENTS = ["note", "can_do", "test_tomorrow", "not_on_track", ...ANCHORS];
const SOME: Record<string, string[]> = {
  "api/src/agents/kinds/message.ts": [...PARENTS, "progress_note"],
  "api/src/prompts/message.ts": [...PARENTS, "progress_note"],
  "api/src/agents/kinds/numbers.ts": [...PARENTS, "figure"],
  "api/src/agents/kinds/question-set.ts": ["homework", "worksheet"],
};

export function kindsChanged(paths: string[]): string[] {
  if (paths.some((p) => EVERY.includes(p))) return [...KINDS].sort();
  const kinds = new Set<string>();
  for (const path of paths) {
    for (const kind of SOME[path] ?? []) kinds.add(kind);
    for (const set of ANCHORS) if (path.startsWith(`api/evals/anchors/${set.slice("anchor_".length)}/`)) kinds.add(set);
    for (const kind of KINDS) {
      if (path === `api/src/prompts/${fileOf(kind)}.ts` || path === `api/src/agents/kinds/${fileOf(kind)}.ts` || path.startsWith(`api/evals/${kind}/`)) kinds.add(kind);
    }
  }
  return [...kinds].sort();
}

if (import.meta.main) {
  const base = Bun.spawnSync(["git", "merge-base", "main", "HEAD"], { stdout: "pipe" }).stdout.toString().trim();
  // The branch's changes from main, the working tree's included; or the range given.
  const range = process.argv[2] ?? base;
  const diff = Bun.spawnSync(["git", "diff", "--name-only", range], { stdout: "pipe", stderr: "pipe" });
  if (diff.exitCode !== 0) throw new Error(`git diff ${range}: ${diff.stderr.toString()}`);
  const kinds = kindsChanged(diff.stdout.toString().split("\n").filter(Boolean));
  console.log(kinds.length > 0 ? kinds.join(",") : "none");
}
