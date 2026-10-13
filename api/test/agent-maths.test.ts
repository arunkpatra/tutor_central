import { afterEach, expect, test } from "bun:test";
import { z } from "zod";
import { type AgentContext, type Kind, runAgent } from "../src/agents/agent.js";
import { mathsFindings, mathsProblem } from "../src/agents/maths.js";
import type { ClaudeRequest } from "../src/claude.js";
import { fakeClaude, type FakeScript } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";

// D102: the maths kinds write their formulae in LaTeX between dollars; a draft whose maths is not closed is a free
// finding, repaired once like any other, so no tutor sees a stray dollar or a half-drawn formula.
test("closed maths passes; a lone dollar or an open brace is a problem", () => {
  expect(mathsProblem("Solve $\\frac{x}{4} - 2 = 1$.")).toBeNull();
  expect(mathsProblem("$$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$")).toBeNull();
  expect(mathsProblem("A pen costs \\$5; find $x$.")).toBeNull();
  expect(mathsProblem("48 mangoes, 360 km")).toBeNull();
  expect(mathsProblem("Solve $3x + 5 = 20.")).toBe("a formula opens with $ and never closes");
  expect(mathsProblem("Solve $\\frac{x}{4 - 2 = 1$.")).toBe("a formula's braces do not close");
  expect(mathsProblem("$$x = 1$")).toBe("a formula opens with $ and never closes");
});

test("every string of a draft is held to the rule, named by where it is", () => {
  const draft = { title: "Equations", questions: [{ number: 1, text: "Solve $x + 1 = 2$.", answer: "$x = 1" }], proof: null };
  expect(mathsFindings(draft)).toEqual([{ item: "questions 1 answer", problem: "a formula opens with $ and never closes" }]);
});

const Answer = z.object({ text: z.string() });
type Answer = z.infer<typeof Answer>;
const kind: Kind<Record<string, never>, Answer> = {
  kind: "sheet",
  classLevel: () => "8",
  maths: true,
  draft: () => ({ system: { shared: "You solve.", own: "" }, version: "3", text: "Write one question.", schema: Answer }),
  rubric: "The question is right.",
};
const isCheck = (r: ClaudeRequest<unknown>) => r.system.shared.includes("You check");
const pass: FakeScript = { answer: { pass: true, findings: [] } };
const ctx = (db: ReturnType<typeof fakeDb>, claude: ReturnType<typeof fakeClaude>): AgentContext => ({
  db,
  claude,
  token: "t",
  requestId: "r",
  centre: "c1",
  key: "k",
  inputHash: "h",
});
let stop: (() => void) | null = null;
afterEach(() => {
  stop?.();
  stop = null;
});

test("a draft with an unclosed formula is repaired once with the finding quoted", async () => {
  let drafts = 0;
  const claude = fakeClaude((r) => {
    if (isCheck(r)) return pass;
    drafts += 1;
    return { answer: { text: drafts === 1 ? "Solve $3x + 5 = 20." : "Solve $3x + 5 = 20$." } };
  });
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kind, {});
  expect(out).toMatchObject({ kind: "ok", repaired: true, parsed: { text: "Solve $3x + 5 = 20$." } });
  expect(claude.requests.find((r) => r.system.own.includes("Fix these"))?.system.own).toContain(
    "text: a formula opens with $ and never closes",
  );
});
