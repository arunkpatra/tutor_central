import { expect, test } from "bun:test";
import { gate, isDocument } from "./check-gate";

const sha = "a".repeat(40);
const older = "b".repeat(40);
type Run = { status: string; conclusion: string | null; created_at?: string };
const runs = (m: Record<string, Run[]>) => async (s: string) => m[s] ?? [];
const none = { parents: async () => [], changedFiles: async () => [] };

test("a green run for the commit passes", async () => {
  expect(await gate(sha, { runs: runs({ [sha]: [{ status: "completed", conclusion: "success" }] }), ...none })).toBeNull();
});

test("a run in progress is not green", async () => {
  const why = await gate(sha, { runs: runs({ [sha]: [{ status: "in_progress", conclusion: null }] }), ...none });
  expect(why).toContain("still running");
});

test("a red run fails", async () => {
  const why = await gate(sha, { runs: runs({ [sha]: [{ status: "completed", conclusion: "failure" }] }), ...none });
  expect(why).toContain("not green");
});

test("the latest run decides: a re-run that passed after a failure passes", async () => {
  const m = {
    [sha]: [
      { status: "completed", conclusion: "failure", created_at: "2026-10-12T10:00:00Z" },
      { status: "completed", conclusion: "success", created_at: "2026-10-12T11:00:00Z" },
    ],
  };
  expect(await gate(sha, { runs: runs(m), ...none })).toBeNull();
});

test("a documents-only commit takes the nearest run", async () => {
  const deps = {
    runs: runs({ [older]: [{ status: "completed", conclusion: "success" }] }),
    parents: async () => [older],
    changedFiles: async () => ["plan/STATE.md", "docs/x.md"],
  };
  expect(await gate(sha, deps)).toBeNull();
});

test("a code change after the nearest run is refused", async () => {
  const deps = {
    runs: runs({ [older]: [{ status: "completed", conclusion: "success" }] }),
    parents: async () => [older],
    changedFiles: async () => ["plan/STATE.md", "api/src/x.ts"],
  };
  expect(await gate(sha, deps)).toContain("api/src/x.ts");
});

test("a documents-only commit whose nearest run is red fails", async () => {
  const deps = {
    runs: runs({ [older]: [{ status: "completed", conclusion: "failure" }] }),
    parents: async () => [older],
    changedFiles: async () => ["plan/STATE.md"],
  };
  expect(await gate(sha, deps)).toContain("not green");
});

test("no run anywhere in the history fails in words", async () => {
  expect(await gate(sha, { runs: runs({}), parents: async () => [older], changedFiles: async () => [] })).toContain("no check run");
});

test("the token document is not a document here", () => {
  expect(isDocument("docs/design/design-tokens.md")).toBe(false);
  expect(isDocument("ios/CLAUDE.md")).toBe(true);
  expect(isDocument("README.md")).toBe(true);
  expect(isDocument("plan/STATE.md")).toBe(true);
  expect(isDocument("tools/smoke.ts")).toBe(false);
});
