import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { finished } from "../src/agents/agent.js";
import { PROMPTS, type VersionTable, versionProblems, versionTable } from "../src/prompts/registry.js";
import { request as sheet, VERSION as SHEET_VERSION } from "../src/prompts/sheet.js";
import { MakeInput, type SheetInput } from "../src/schemas.js";

// Prompts as files with a version (D74, plan decision 9): the version and a hash of the words pinned in versions.json;
// the shared block cached, so it carries nothing of the request but the class and subject (review focus 7).
const written = JSON.parse(readFileSync(join(import.meta.dir, "../src/prompts/versions.json"), "utf8")) as VersionTable;

test("every prompt file exports a VERSION that is an integer string", () => {
  for (const [kind, e] of Object.entries(PROMPTS)) expect({ kind, ok: /^[1-9]\d*$/.test(e.version) }).toEqual({ kind, ok: true });
});

test("versions.json holds every prompt's version and the hash of its words (bun prompts --write)", () => {
  expect(versionProblems(written, versionTable())).toEqual([]);
});

const body = (skills: string[], reason?: string) =>
  MakeInput.parse({ centreId: "22222222-2222-2222-2222-222222222222", kind: "sheet", classLevel: "8", subject: "Science", skills, questions: 6, reason }) as SheetInput;

test("the shared block of two requests of one kind and class is byte-equal", () => {
  const a = sheet(body(["Balance a chemical equation"]));
  const b = sheet(body(["Spot a chemical change", "Write a word equation"], "harder"));
  expect(a.system.shared).toBe(b.system.shared);
  expect(a.system.shared.length).toBeGreaterThan(0);
});

test("the shared block carries no date, id or name", () => {
  const ids = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/;
  const day = /\d{4}-\d{2}-\d{2}/;
  for (const [kind, e] of Object.entries(PROMPTS)) {
    const shared = e.build().system.shared;
    expect({ kind, id: ids.test(shared), day: day.test(shared), name: /Hemanth|Lakshmi|Meera|Bright Minds/.test(shared) }).toEqual({ kind, id: false, day: false, name: false });
  }
});

test("the row's version is kind@VERSION", () => {
  const r = sheet(body(["Balance a chemical equation"]));
  const answer = { kind: "ok" as const, parsed: {}, model: "claude-sonnet-5-5", tokensIn: 1, tokensOut: 1, tokensCached: 0, tokensWritten: 0, stopReason: "end_turn", latencyMs: 1 };
  expect(finished(answer, { ...r, model: r.model }, `sheet@${r.version}`, null, {}).promptVersion).toBe(`sheet@${SHEET_VERSION}`);
});

test("a moved word under the same version, or a version moved alone, is a problem", () => {
  const current = versionTable();
  const moved = { ...current, sheet: { version: current.sheet!.version, hash: "0".repeat(64) } };
  expect(versionProblems(moved, current)).toEqual([`sheet: its words changed; raise VERSION (now ${current.sheet!.version})`]);
  const bumped = { ...current, sheet: { version: "1", hash: current.sheet!.hash } };
  expect(versionProblems(bumped, current)).toEqual(["sheet: VERSION changed with the same words"]);
  const { sheet: _gone, ...missing } = current;
  expect(versionProblems(missing, current)).toEqual(["sheet: not in versions.json"]);
});
