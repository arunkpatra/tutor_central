#!/usr/bin/env bun
/** bun tools/check-gate.ts <sha>: the deploy's gate (D80). Passes when the `check` workflow's latest run for the commit
 *  on main is green; a documents-only commit (D31 runs no check) passes on the nearest earlier commit's green run when
 *  every file changed since it is a document (D12). Exit 1 with the reason. */

export type CheckRun = { status: string; conclusion: string | null; created_at?: string };
export type GateDeps = {
  /** The check workflow's runs for a commit on main. */
  runs(sha: string): Promise<CheckRun[]>;
  /** The first-parent history before the commit, nearest first. */
  parents(sha: string): Promise<string[]>;
  /** The files changed between two commits. */
  changedFiles(from: string, to: string): Promise<string[]>;
};

/** D12's documents. The token document is not one here: the iOS and web token tests read it. */
export function isDocument(path: string): boolean {
  if (path === "docs/design/design-tokens.md") return false;
  return path.startsWith("plan/") || path.startsWith("docs/") || path === "README.md" || path.endsWith("CLAUDE.md");
}

function latest(runs: CheckRun[]): CheckRun | undefined {
  return [...runs].sort((a, b) => (a.created_at ?? "").localeCompare(b.created_at ?? "")).at(-1);
}

function verdict(sha: string, run: CheckRun): string | null {
  if (run.status === "queued" || run.status === "in_progress" || run.status === "waiting" || run.status === "pending") {
    return `the check for ${sha} is still running; wait for it and run the deploy again`;
  }
  if (run.conclusion === "success") return null;
  return `the check for ${sha} is not green (${run.conclusion ?? run.status})`;
}

/** null passes; otherwise the reason the deploy stops. */
export async function gate(sha: string, deps: GateDeps): Promise<string | null> {
  const own = latest(await deps.runs(sha));
  if (own) return verdict(sha, own);
  for (const parent of (await deps.parents(sha)).slice(0, 50)) {
    const run = latest(await deps.runs(parent));
    if (!run) continue;
    const why = verdict(parent, run);
    if (why) return why;
    const code = (await deps.changedFiles(parent, sha)).filter((f) => !isDocument(f));
    if (code.length > 0) return `${code.join(", ")} changed since the last check run ${parent}`;
    return null;
  }
  return `no check run for ${sha} or the 50 commits before it`;
}

async function git(args: string[]): Promise<string[]> {
  const p = Bun.spawn(["git", ...args], { stdout: "pipe", stderr: "pipe" });
  const out = await new Response(p.stdout).text();
  if ((await p.exited) !== 0) throw new Error(`git ${args.join(" ")} failed: ${await new Response(p.stderr).text()}`);
  return out.split("\n").filter(Boolean);
}

if (import.meta.main) {
  const sha = process.argv[2];
  const repo = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  if (!sha || !repo || !token) {
    console.error("usage: GITHUB_REPOSITORY=… GITHUB_TOKEN=… bun tools/check-gate.ts <sha>");
    process.exit(2);
  }
  const why = await gate(sha, {
    runs: async (s) => {
      const res = await fetch(
        `https://api.github.com/repos/${repo}/actions/workflows/check.yml/runs?head_sha=${s}&branch=main&per_page=20`,
        { headers: { authorization: `Bearer ${token}`, accept: "application/vnd.github+json" } },
      );
      if (!res.ok) throw new Error(`GitHub answered ${res.status} for the check runs of ${s}`);
      return ((await res.json()) as { workflow_runs: CheckRun[] }).workflow_runs;
    },
    parents: (s) => git(["rev-list", "--first-parent", "--max-count=50", `${s}^`]),
    changedFiles: (a, b) => git(["diff", "--name-only", a, b]),
  });
  if (why) {
    console.error(`::error::The deploy stops: ${why}.`);
    process.exit(1);
  }
  console.log(`the check for ${sha} (or the documents after its last run) is green`);
}
