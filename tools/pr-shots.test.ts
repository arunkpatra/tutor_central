import { expect, test } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { must } from "./lib/sh";
import { commitShots, linkTable } from "./pr-shots";

const author = { name: "t", email: "t@t" };

async function scratchRepo(): Promise<string> {
  const repo = mkdtempSync(join(tmpdir(), "tc-repo-"));
  await must(["git", "init", "-q", "-b", "main"], { cwd: repo });
  writeFileSync(join(repo, "tracked.txt"), "committed");
  await must(["git", "add", "tracked.txt"], { cwd: repo });
  await must(["git", "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "init"], { cwd: repo });
  return repo;
}

test("commitShots writes to the orphan branch and leaves the working tree, index and HEAD alone", async () => {
  const repo = await scratchRepo();
  writeFileSync(join(repo, "dirty.txt"), "uncommitted");
  writeFileSync(join(repo, "tracked.txt"), "changed but not staged");
  const png = join(repo, "a-dark.png");
  writeFileSync(png, "not really a png");
  const statusBefore = await must(["git", "status", "--porcelain"], { cwd: repo });
  const headBefore = await must(["git", "rev-parse", "HEAD"], { cwd: repo });

  const sha = await commitShots({ repo, folder: "demo", files: [png], push: false, author });

  expect(sha).toMatch(/^[0-9a-f]{40}$/);
  expect(await must(["git", "status", "--porcelain"], { cwd: repo })).toBe(statusBefore);
  expect(await must(["git", "rev-parse", "HEAD"], { cwd: repo })).toBe(headBefore);
  expect(await must(["git", "rev-parse", "--abbrev-ref", "HEAD"], { cwd: repo })).toBe("main\n");
  expect(await must(["git", "ls-tree", "-r", "--name-only", "pr-shots"], { cwd: repo })).toBe("demo/a-dark.png\n");
  expect(await must(["git", "rev-list", "--count", "pr-shots"], { cwd: repo })).toBe("1\n");
});

test("a second folder keeps the first, and the same folder again replaces its pictures", async () => {
  const repo = await scratchRepo();
  const a = join(repo, "a.png");
  const b = join(repo, "b.png");
  writeFileSync(a, "1");
  writeFileSync(b, "2");
  await commitShots({ repo, folder: "one", files: [a], push: false, author });
  await commitShots({ repo, folder: "two", files: [b], push: false, author });
  await commitShots({ repo, folder: "one", files: [b], push: false, author });
  expect(await must(["git", "ls-tree", "-r", "--name-only", "pr-shots"], { cwd: repo })).toBe("one/b.png\ntwo/b.png\n");
  expect(await must(["git", "rev-list", "--count", "pr-shots"], { cwd: repo })).toBe("3\n");
});

test("a file name with a space or a quote is kept as it is", async () => {
  const repo = await scratchRepo();
  const odd = join(repo, "it's a shot.png");
  writeFileSync(odd, "x");
  await commitShots({ repo, folder: "odd", files: [odd], push: false, author });
  expect(await must(["git", "ls-tree", "-r", "--name-only", "-z", "pr-shots"], { cwd: repo })).toBe("odd/it's a shot.png\0");
});

test("the link table names the state and appearance of each picture", () => {
  const table = linkTable("https://github.com/o/r", "abc", "p1", ["x/today-empty-dark.png", "x/today-empty-light.png", "x/kit.png"]);
  expect(table).toBe(
    [
      "| Screen | Appearance | Picture |",
      "|---|---|---|",
      "| today-empty | dark | ![today-empty-dark](https://github.com/o/r/blob/abc/p1/today-empty-dark.png?raw=true) |",
      "| today-empty | light | ![today-empty-light](https://github.com/o/r/blob/abc/p1/today-empty-light.png?raw=true) |",
      "| kit |  | ![kit](https://github.com/o/r/blob/abc/p1/kit.png?raw=true) |",
    ].join("\n"),
  );
});
