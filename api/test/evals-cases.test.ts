import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { runAgent } from "../src/agents/agent.js";
import { kindFor, rubrics } from "../src/agents/kinds/index.js";
import { fakeClaude, localAnswer } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { agentFor, EVAL_KINDS, evaluate, evalsDir, kindsOnDisk, loadCases, pageWords } from "../src/evals/cases.js";

// The golden sets (D74, plan decision 10): five cases a kind, the seed's names, no real page, each input the route's.
const BANNED = [/\+91\s?\d/, /\b\d{10}\b/, /[\w.+-]+@[\w-]+\.\w+/];

test("every kind on its agent has a golden set of five cases, and no other set exists", () => {
  expect(kindsOnDisk()).toEqual([...EVAL_KINDS].sort());
  for (const kind of EVAL_KINDS) expect({ kind, cases: loadCases([kind]).length }).toEqual({ kind, cases: 5 });
  expect(new Set(loadCases().map((c) => c.id)).size).toBe(45);
});

test("every case's input is the route's: it satisfies the kind's input schema", () => {
  for (const c of loadCases()) expect(() => agentFor(c)).not.toThrow();
});

test("no case holds a phone number or an email", () => {
  for (const kind of EVAL_KINDS) {
    const text = readFileSync(join(evalsDir(), kind, "cases.json"), "utf8");
    for (const pattern of BANNED) expect({ kind, found: pattern.test(text) }).toEqual({ kind, found: false });
  }
});

test("each kind's rubric.md is its agent's rubric, word for word (one text for the check and the graders)", () => {
  for (const kind of EVAL_KINDS) expect({ kind, rubric: readFileSync(join(evalsDir(), kind, "rubric.md"), "utf8") }).toEqual({ kind, rubric: `${rubrics()[kind]}\n` });
});

test("a known-good draft passes the check without a repair, and scores on every case (review focus 1)", async () => {
  for (const c of loadCases()) {
    const { spec, input } = agentFor(c);
    const claude = fakeClaude((r) => ({ answer: localAnswer(r) }));
    const db = fakeDb();
    const outcome = await runAgent({ db, claude, token: "", requestId: "evals", centre: "c", key: c.id, inputHash: "h" }, spec, input);
    if (c.expect.refused) continue;
    expect({ id: c.id, outcome: outcome.kind, repaired: (outcome as { repaired?: boolean }).repaired }).toEqual({ id: c.id, outcome: "ok", repaired: false });
    const scored = evaluate(c, input, outcome);
    expect({ id: c.id, schema: scored.schema, verify: scored.verify }).toEqual({ id: c.id, schema: true, verify: true });
  }
  expect(kindFor("sheet")).not.toBeNull();
});

test("evaluate scores a refusal against a case that expects one, and names what an answer misses", () => {
  const preface = loadCases(["parse_textbook"]).find((c) => c.expect.refused)!;
  const { input } = agentFor(preface);
  expect(evaluate(preface, input, { kind: "failed", id: "g", costPaise: 1, reason: "refused", words: "refused" }).expect).toBe(true);
  expect(evaluate(preface, input, { kind: "ok", id: "g", parsed: { title: null, chapters: [] }, costPaise: 1, repaired: false, replay: false }).expect).toBe(false);
  const sheet = loadCases(["sheet"])[0]!;
  const sheetInput = agentFor(sheet).input;
  const answer = { title: "Linear", instructions: null, questions: [{ number: 1, text: "Solve x + 1 = 2.", answer: "x = 1 Hemanth", proof: { expression: "1+1", equals: 3 } }] };
  const scored = evaluate(sheet, sheetInput, { kind: "ok", id: "g", parsed: answer, costPaise: 1, repaired: false, replay: false });
  expect(scored.verify).toBe(false);
  expect(scored.expect).toBe(false);
  expect(scored.reasons).toContain('"Hemanth" present');
  expect(scored.reasons).toContain("count 1, expected 6");
});

test("the grader is told what a case's page prints, so a photo's answer is judged against the page, not the whole book", () => {
  const page = loadCases(["parse_textbook"]).find((c) => c.id === "textbook-8-science");
  const words = pageWords(page!);
  expect(words).toContain("CONTENTS");
  expect(words).toContain("1 Exploring the Investigative World of Science (Asking questions; Making a fair test), page 1");
  expect(pageWords(loadCases(["plan"])[0]!)).toBe("");
});
