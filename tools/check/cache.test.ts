import { expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { hashInputs, readStamp, writeStamp } from "./cache";

const scratch = () => mkdtempSync(join(tmpdir(), "tc-"));

test("hash changes when a matched file changes and ignores others", async () => {
  const dir = scratch();
  writeFileSync(join(dir, "a.swift"), "1");
  writeFileSync(join(dir, "b.md"), "x");
  const h1 = await hashInputs(["**/*.swift"], dir, "tool-1");
  writeFileSync(join(dir, "b.md"), "y");
  expect(await hashInputs(["**/*.swift"], dir, "tool-1")).toBe(h1);
  writeFileSync(join(dir, "a.swift"), "2");
  expect(await hashInputs(["**/*.swift"], dir, "tool-1")).not.toBe(h1);
  expect(await hashInputs(["**/*.swift"], dir, "tool-2")).not.toBe(h1);
});

test("hash changes when a matched file is renamed", async () => {
  const dir = scratch();
  writeFileSync(join(dir, "a.swift"), "1");
  const h1 = await hashInputs(["**/*.swift"], dir, "s");
  const other = scratch();
  writeFileSync(join(other, "b.swift"), "1");
  expect(await hashInputs(["**/*.swift"], other, "s")).not.toBe(h1);
});

test("hash ignores hidden directories and node_modules", async () => {
  const dir = scratch();
  writeFileSync(join(dir, "a.swift"), "1");
  const h1 = await hashInputs(["**/*.swift"], dir, "s");
  mkdirSync(join(dir, ".build"), { recursive: true });
  writeFileSync(join(dir, ".build", "dep.swift"), "x");
  mkdirSync(join(dir, "node_modules", "p"), { recursive: true });
  writeFileSync(join(dir, "node_modules", "p", "x.swift"), "x");
  expect(await hashInputs(["**/*.swift"], dir, "s")).toBe(h1);
});

test("stamps round-trip", async () => {
  const dir = scratch();
  expect(await readStamp("ios", dir)).toBeNull();
  await writeStamp("ios", "abc", dir);
  expect(await readStamp("ios", dir)).toBe("abc");
});

test("an explicitly named dotfile counts", async () => {
  const dir = scratch();
  mkdirSync(join(dir, "ios"));
  writeFileSync(join(dir, "ios", ".swiftformat"), "--indent 4");
  const h1 = await hashInputs(["ios/.swiftformat"], dir, "s");
  writeFileSync(join(dir, "ios", ".swiftformat"), "--indent 2");
  expect(await hashInputs(["ios/.swiftformat"], dir, "s")).not.toBe(h1);
});
