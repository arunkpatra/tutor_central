import { afterEach, expect, test } from "bun:test";
import { z } from "zod";
import { type AgentContext, type Kind, runAgent } from "../src/agents/agent.js";
import { proofHolds } from "../src/agents/arith.js";
import type { ClaudeRequest } from "../src/claude.js";
import { fakeClaude, type FakeScript } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeModelSource } from "../src/models-db.js";
import { installModelTable } from "../src/models.js";
import { Proof } from "../src/schemas.js";

// The agent (D99): draft, verify, a check by the other tier, one repair, refuse; every call a recorded row with its step.
const Answer = z.object({ answer: z.number(), proof: Proof.nullable() });
type Answer = z.infer<typeof Answer>;
const kind: Kind<{ x: number }, Answer> = {
  kind: "sheet",
  classLevel: () => "8",
  draft: (input) => ({ system: { shared: "You solve.", own: `x is ${input.x}.` }, version: "2", text: "Solve 3x + 5 = 20.", schema: Answer }),
  verify: (_input, draft) => (draft.proof && !proofHolds(draft.proof) ? [{ item: "answer", problem: "the proof does not add up" }] : []),
  rubric: "The answer is right.",
};
const isCheck = (r: ClaudeRequest<unknown>) => r.system.shared.includes("You check");
const ctx = (db: ReturnType<typeof fakeDb>, claude: ReturnType<typeof fakeClaude>, extra: Partial<AgentContext> = {}): AgentContext => ({
  db,
  claude,
  token: "t",
  requestId: "r",
  centre: "c1",
  key: "k",
  inputHash: "h",
  ...extra,
});
const pass: FakeScript = { answer: { pass: true, findings: [] } };
let stop: (() => void) | null = null;
afterEach(() => {
  stop?.();
  stop = null;
});

test("a draft that verifies and passes the check is kept with one draft row and one check row", async () => {
  const claude = fakeClaude((r) => (isCheck(r) ? pass : { answer: { answer: 20, proof: { expression: "3*5+5", equals: 20 } } }));
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kind, { x: 5 });
  expect(out).toMatchObject({ kind: "ok", repaired: false, parsed: { answer: 20 } });
  expect(db.rows.map((r) => r.agentStep)).toEqual(["draft", "check"]);
  expect(db.rows.map((r) => r.key)).toEqual(["k", "k:check"]);
  expect(db.rows[0]?.finish).toMatchObject({ status: "ok", promptVersion: "sheet@2" });
  // The checker is the other tier: Haiku checks a Sonnet draft (class 8's sheet).
  expect(db.rows.map((r) => r.model)).toEqual(["claude-sonnet-5-5", "claude-haiku-5-5"]);
});

test("a planted wrong key is a finding; the repair is kept when it adds up", async () => {
  let drafts = 0;
  const claude = fakeClaude((r) => {
    if (isCheck(r)) return pass;
    drafts += 1;
    return { answer: drafts === 1 ? { answer: 20, proof: { expression: "3*6+5", equals: 20 } } : { answer: 20, proof: { expression: "3*5+5", equals: 20 } } };
  });
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kind, { x: 5 });
  expect(out).toMatchObject({ kind: "ok", repaired: true });
  expect(claude.requests.filter((r) => !isCheck(r)).length).toBe(2);
  expect(claude.requests[2]?.system.own).toContain("Fix these and change nothing else:");
  expect(claude.requests[2]?.system.own).toContain("answer: the proof does not add up");
  expect(claude.requests[2]?.system.shared).toBe("You solve.");
  expect(db.rows.map((r) => [r.agentStep, r.key])).toEqual([["draft", "k"], ["check", "k:check"], ["repair", "k:repair"], ["check", "k:repair:check"]]);
  // The draft's row keeps the answer the tutor got, so a replay of its key answers the repaired one.
  expect(JSON.parse(db.rows[0]?.finish?.output ?? "{}").proof.expression).toBe("3*5+5");
});

test("a draft the repair cannot fix is refused in words, with the finding on the draft's row", async () => {
  const claude = fakeClaude((r) =>
    isCheck(r) ? { answer: { pass: false, findings: [{ item: "answer", problem: "does not match the proof" }] } } : { answer: { answer: 21, proof: { expression: "3*5+5", equals: 20 } } },
  );
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kind, { x: 5 });
  expect(out).toMatchObject({ kind: "failed", reason: "check:answer", words: "refused" });
  expect(db.rows[0]?.finish).toMatchObject({ status: "failed", errorReason: "check:answer", output: null });
  expect(db.rows.length).toBe(4);
  // The cost is every row's.
  expect((out as { costPaise: number }).costPaise).toBe(db.rows.reduce((n, r) => n + (r.finish?.costPaise ?? 0), 0));
});

test("a kind switched off answers paused before any call or row", async () => {
  const t = installModelTable(fakeModelSource([{ kind: "sheet_from_6", step: "draft", model: "claude-sonnet-5-5", effort: "medium", fallbackModel: null, enabled: false }]));
  stop = t.stop;
  await t.refresh();
  const claude = fakeClaude({ answer: {} });
  const db = fakeDb();
  expect(await runAgent(ctx(db, claude), kind, { x: 5 })).toEqual({ kind: "paused" });
  expect(claude.requests.length).toBe(0);
  expect(db.rows.length).toBe(0);
});

test("a failed draft call tries the fallback model once and records it; a refused one is not tried elsewhere", async () => {
  const t = installModelTable(fakeModelSource([{ kind: "sheet_from_6", step: "draft", model: "claude-sonnet-5-5", effort: "medium", fallbackModel: "claude-haiku-5-5", enabled: true }]));
  stop = t.stop;
  await t.refresh();
  let n = 0;
  const claude = fakeClaude((r) => {
    n += 1;
    return n === 1 ? { fail: "api 529" } : isCheck(r) ? pass : { answer: { answer: 20, proof: null } };
  });
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kind, { x: 5 });
  expect(out.kind).toBe("ok");
  expect(claude.requests.map((r) => r.model)).toEqual(["claude-sonnet-5-5", "claude-haiku-5-5", "claude-haiku-5-5"]);
  expect(db.rows[0]?.finish?.fallbackModel).toBe("claude-haiku-5-5");
  const refused = fakeClaude({ refuse: true });
  expect(await runAgent(ctx(fakeDb(), refused), kind, { x: 5 })).toMatchObject({ kind: "failed", reason: "refused", words: "refused" });
  expect(refused.requests.length).toBe(1);
});

test("a check that times out keeps the draft and logs", async () => {
  const claude = fakeClaude((r) => (isCheck(r) ? { fail: "timeout" } : { answer: { answer: 20, proof: null } }));
  const db = fakeDb();
  expect(await runAgent(ctx(db, claude), kind, { x: 5 })).toMatchObject({ kind: "ok", repaired: false });
  expect(db.rows.map((r) => r.finish?.status)).toEqual(["ok", "failed"]);
});

test("a replayed key answers the kept output and pays nothing; a key still running is pending", async () => {
  const kept = JSON.stringify({ answer: 20, proof: null });
  const claude = fakeClaude({ answer: {} });
  const done = await runAgent(ctx(fakeDb({ replays: { k: { id: "g1", status: "ok", output: kept } } }), claude), kind, { x: 5 });
  expect(done).toEqual({ kind: "ok", id: "g1", parsed: { answer: 20, proof: null }, costPaise: 0, repaired: false, replay: true });
  expect(await runAgent(ctx(fakeDb({ replays: { k: { id: "g1", status: "pending", output: null } } }), claude), kind, { x: 5 })).toEqual({ kind: "pending" });
  expect(claude.requests.length).toBe(0);
});

test("with no time left for a repair the findings refuse the draft at once", async () => {
  let clock = 0;
  const claude = fakeClaude((r) => {
    clock += 50_000;
    return isCheck(r) ? { answer: { pass: false, findings: [{ item: "1", problem: "wrong" }] } } : { answer: { answer: 21, proof: null } };
  });
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude, { now: () => clock, budgetMs: 110_000 }), kind, { x: 5 });
  expect(out).toMatchObject({ kind: "failed", reason: "check:1" });
  expect(db.rows.map((r) => r.agentStep)).toEqual(["draft", "check"]);
});

test("an empty answer is refused without a check; a kind with no rubric is drafted alone", async () => {
  const empty: Kind<{ x: number }, Answer> = { ...kind, empty: (draft) => draft.answer === 0 };
  const claude = fakeClaude({ answer: { answer: 0, proof: null } });
  const db = fakeDb();
  expect(await runAgent(ctx(db, claude), empty, { x: 5 })).toMatchObject({ kind: "failed", reason: "refused", words: "refused" });
  expect(db.rows.length).toBe(1);
  const alone: Kind<undefined, Answer> = { kind: "note", draft: () => ({ system: { shared: "s", own: "" }, version: "2", text: "t", schema: Answer }) };
  const db2 = fakeDb();
  expect(await runAgent(ctx(db2, fakeClaude({ answer: { answer: 1, proof: null } })), alone, undefined)).toMatchObject({ kind: "ok" });
  expect(db2.rows.map((r) => r.agentStep)).toEqual(["draft"]);
});

test("the check is told the request and the draft, and compares an answer with its proof (review focus 2)", async () => {
  const claude = fakeClaude((r) => (isCheck(r) ? pass : { answer: { answer: 20, proof: { expression: "3*5+5", equals: 20 } } }));
  await runAgent(ctx(fakeDb(), claude), kind, { x: 5 });
  const check = claude.requests[1];
  expect(check?.system.shared).toContain("The rubric:\nThe answer is right.");
  expect(check?.system.shared).toContain("an answer that does not agree with its proof is a finding");
  expect(check?.text).toContain("Solve 3x + 5 = 20.");
  expect(check?.text).toContain('"expression":"3*5+5"');
});

test("every call's deadline is whole milliseconds: Node's AbortSignal.timeout refuses a fraction (a Vercel function runs on Node)", async () => {
  let clock = 0;
  const claude = fakeClaude((r) => (isCheck(r) ? pass : { answer: { answer: 20, proof: null } }));
  // performance.now() is fractional, and each read is later than the last.
  await runAgent(ctx(fakeDb(), claude, { now: () => (clock += 0.467) }), kind, { x: 5 });
  expect(claude.requests.map((r) => Number.isInteger(r.deadlineMs))).toEqual([true, true]);
});

test("a repaired answer that holds nothing is refused in words, not kept (the review's finding 2)", async () => {
  const empty: Kind<{ x: number }, Answer> = { ...kind, empty: (draft) => draft.answer === 0 };
  let drafts = 0;
  const claude = fakeClaude((r) => {
    if (isCheck(r)) return pass;
    drafts += 1;
    return { answer: drafts === 1 ? { answer: 20, proof: { expression: "3*6+5", equals: 20 } } : { answer: 0, proof: null } };
  });
  const db = fakeDb();
  expect(await runAgent(ctx(db, claude), empty, { x: 5 })).toMatchObject({ kind: "failed", reason: "refused", words: "refused" });
  expect(db.rows[0]?.finish).toMatchObject({ status: "failed", errorReason: "refused" });
});

test("the check names the call's student as the repair does, so a personal kind's check passes the consent gate (finding 6)", async () => {
  const personal: Kind<{ x: number }, Answer> = { ...kind, student: () => ({ id: "s1" }) };
  const claude = fakeClaude((r) => (isCheck(r) ? pass : { answer: { answer: 20, proof: { expression: "3*5+5", equals: 20 } } }));
  const db = fakeDb();
  await runAgent(ctx(db, claude), personal, { x: 5 });
  expect(db.started.map((s) => (s as { student?: string }).student)).toEqual(["s1", "s1"]);
});
