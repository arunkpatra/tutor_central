#!/usr/bin/env bun
/** bun pr-shots <folder> <file.png>...: keep a pull request's screenshots on the orphan branch pr-shots (D7) and print
 *  the markdown table of links for its description. Plumbing only: no checkout, no index, no change to the working
 *  tree or the branch in hand, so a half-done change can never be committed by accident. */
import { basename } from "node:path";
import { must, sh } from "./lib/sh";

export type ShotsOptions = {
  repo: string;
  folder: string;
  files: string[];
  push: boolean;
  author?: { name: string; email: string };
};

const BRANCH = "refs/heads/pr-shots";

/** The pictures under <folder>/ in a new commit on pr-shots; other folders are kept. Returns the commit. */
export async function commitShots(o: ShotsOptions): Promise<string> {
  if (o.folder.includes("/")) throw new Error(`folder must be one name, not a path: ${o.folder}`);
  const names = o.files.map((f) => basename(f));
  const dup = names.find((n, i) => names.indexOf(n) !== i);
  if (dup) throw new Error(`duplicate picture name: ${dup}`);
  const git = (args: string[], extra: { env?: Record<string, string>; stdin?: string } = {}) =>
    must(["git", ...args], { cwd: o.repo, ...extra });
  const mktree = (entries: string[]) => git(["mktree", "-z"], { stdin: entries.map((e) => `${e}\0`).join("") });

  const blobs: string[] = [];
  for (const f of o.files) blobs.push(`100644 blob ${(await git(["hash-object", "-w", "--", f])).trim()}\t${basename(f)}`);
  const folderTree = (await mktree(blobs)).trim();

  const parent = (await sh(["git", "rev-parse", "-q", "--verify", BRANCH], { cwd: o.repo })).stdout.trim();
  const kept = parent
    ? (await git(["ls-tree", "-z", parent])).split("\0").filter((e) => e && !e.endsWith(`\t${o.folder}`))
    : [];
  const rootTree = (await mktree([...kept, `040000 tree ${folderTree}\t${o.folder}`])).trim();

  const env: Record<string, string> = o.author
    ? {
        GIT_AUTHOR_NAME: o.author.name,
        GIT_AUTHOR_EMAIL: o.author.email,
        GIT_COMMITTER_NAME: o.author.name,
        GIT_COMMITTER_EMAIL: o.author.email,
      }
    : {};
  const commit = (await git(["commit-tree", rootTree, ...(parent ? ["-p", parent] : []), "-m", `shots: ${o.folder}`], { env })).trim();
  await git(["update-ref", BRANCH, commit, ...(parent ? [parent] : [])]);
  if (o.push) await git(["push", "-q", "origin", `${BRANCH}:${BRANCH}`]);
  return commit;
}

/** "| state | appearance | picture |" rows, the picture linked at the commit so it never changes under the PR. */
export function linkTable(remote: string, sha: string, folder: string, files: string[]): string {
  const rows = files.map((f) => {
    const name = basename(f, ".png");
    const [state, appearance = ""] = name.split(/-(?=(?:dark|light)$)/);
    return `| ${state} | ${appearance} | ![${name}](${remote}/blob/${sha}/${folder}/${basename(f)}?raw=true) |`;
  });
  return ["| Screen | Appearance | Picture |", "|---|---|---|", ...rows].join("\n");
}

if (import.meta.main) {
  const [folder, ...files] = process.argv.slice(2);
  if (!folder || files.length === 0) {
    console.error("usage: bun pr-shots <folder> <file.png>...");
    process.exit(2);
  }
  const repo = (await must(["git", "rev-parse", "--show-toplevel"])).trim();
  const remote = (await must(["git", "remote", "get-url", "origin"]))
    .trim()
    .replace(/^git@github\.com:/, "https://github.com/")
    .replace(/\.git$/, "");
  const sha = await commitShots({ repo, folder, files, push: true });
  console.log(linkTable(remote, sha, folder, files));
}
