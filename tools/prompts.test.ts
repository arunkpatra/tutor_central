import { expect, test } from "bun:test";
import { join } from "node:path";
import { writable } from "./prompts";

// bun prompts (D74): the table is written only when every changed kind carries a raised VERSION.
test("--write refuses words moved under the same version and allows a raised version or a new kind", () => {
  expect(writable(["sheet: its words changed; raise VERSION (now 2)"])).toEqual(["sheet: its words changed; raise VERSION (now 2)"]);
  expect(writable(["sheet: VERSION changed with the same words"])).toEqual(["sheet: VERSION changed with the same words"]);
  expect(writable(["sheet: versions.json is stale; run bun prompts --write", "mock: not in versions.json", "x: in versions.json but no prompt"])).toEqual([]);
});

test("the check passes on the written table and fails when a hash moves", async () => {
  const run = (cwd: string) => Bun.spawnSync(["bun", join(import.meta.dir, "prompts.ts")], { cwd, stderr: "pipe", stdout: "pipe" });
  expect(run(join(import.meta.dir, "..")).exitCode).toBe(0);
  const file = Bun.file(join(import.meta.dir, "../api/src/prompts/versions.json"));
  const written = await file.text();
  const table = JSON.parse(written) as Record<string, { version: string; hash: string }>;
  table.sheet = { version: table.sheet?.version ?? "2", hash: "0".repeat(64) };
  await Bun.write(file, JSON.stringify(table));
  try {
    const moved = run(join(import.meta.dir, ".."));
    expect(moved.exitCode).toBe(1);
    expect(moved.stderr.toString()).toContain("sheet: its words changed; raise VERSION");
  } finally {
    await Bun.write(file, written);
  }
});
