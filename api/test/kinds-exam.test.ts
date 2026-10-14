import { expect, test } from "bun:test";
import { runAgent } from "../src/agents/agent.js";
import { checkPaper, gapReport, mock, readMarks } from "../src/agents/kinds/index.js";
import { fakeClaude, localAnswer } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import type { DecodedImage } from "../src/images.js";
import { schemeQuestions } from "../src/prompts/check-paper.js";
import { type GapReportInput, MakeInput, type MockInput, type MockOutput } from "../src/schemas.js";

// Phase 21 (D73): the exam's kinds on their agents: the mock's marks sum, its numbers run on and its skills are two to
// six; a gap report has a line a day left; marking answers every scheme question once within its marks; read marks keep
// a score within its maximum and an ISO date.
const centreId = "22222222-2222-2222-2222-222222222222";
const studentId = "a0000000-0000-4000-8000-000000000001";
const page: DecodedImage = { mediaType: "image/png", base64: "iVBORw0KGgo=", bytes: 8 };
const ctx = (db = fakeDb()) => ({ db, claude: fakeClaude((r) => ({ answer: localAnswer(r) })), token: "t", requestId: "r", centre: centreId, key: "k", inputHash: "h" });

const mockInput = (pattern: MockInput["pattern"] = { marks: 25, durationMinutes: 40 }) =>
  MakeInput.parse({ centreId, kind: "mock", classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"], pattern }) as MockInput;
const mockDraft = (marks: number[], skills = ["Balance a chemical equation", "Types of reactions"]): MockOutput => ({
  title: "Science unit test 3",
  durationMinutes: 40,
  sections: [{ name: "Section A", marksEach: 1, questions: marks.map((m, i) => ({ number: i + 1, text: `Question ${i + 1}`, marks: m, answer: "a", skill: skills[i % skills.length] as string, proof: null })) }],
});
const gapInput = (daysLeft: number) =>
  MakeInput.parse({ centreId, kind: "gap_report", studentId, classLevel: "8", subject: "Science", daysLeft, bySkill: [{ skill: "Balance a chemical equation", right: 3, of: 10 }] }) as GapReportInput;

test("a mock whose marks do not sum, whose numbers skip or whose skills exceed six is a finding", () => {
  const input = mockInput();
  const good = mockDraft([1, 1, 1, 3, 3, 5, 5, 6]);
  expect(mock.verify?.(input, good)).toEqual([]);
  expect(mock.verify?.(input, mockDraft([1, 1, 1, 3, 3, 5, 5, 5])).map((f) => f.problem)).toEqual(["the marks sum to 24, not 25"]);
  const skipped = { ...good, sections: [{ ...good.sections[0], questions: good.sections[0]?.questions.map((q, i) => ({ ...q, number: i + 2 })) ?? [] }] } as MockOutput;
  expect(mock.verify?.(input, skipped).map((f) => f.item)).toContain("numbering");
  expect(mock.verify?.(input, mockDraft([1, 1, 1, 3, 3, 5, 5, 6], ["a", "b", "c", "d", "e", "f", "g", "h"])).map((f) => f.item)).toContain("skills");
  expect(mock.verify?.(input, mockDraft([1, 1, 1, 3, 3, 5, 5, 6], ["a"])).map((f) => f.item)).toContain("skills");
});

test("a mock in a pattern with sections keeps each section's count and marks", () => {
  const input = mockInput({ marks: 7, durationMinutes: 20, sections: [{ name: "Section A", questions: 2, marksEach: 2 }, { name: "Section B", questions: 1, marksEach: 3 }] });
  const draft: MockOutput = {
    title: "t",
    durationMinutes: 20,
    sections: [
      { name: "Section A", marksEach: 2, questions: [1, 2].map((n) => ({ number: n, text: "q", marks: 2, answer: "a", skill: n === 1 ? "x" : "y", proof: null })) },
      { name: "Section B", marksEach: 3, questions: [{ number: 3, text: "q", marks: 3, answer: "a", skill: "x", proof: null }] },
    ],
  };
  expect(mock.verify?.(input, draft)).toEqual([]);
  const wrong = { ...draft, sections: [draft.sections[0], { ...draft.sections[1], questions: [{ number: 3, text: "q", marks: 2, answer: "a", skill: "x", proof: null }] }] } as MockOutput;
  expect(mock.verify?.(input, wrong).map((f) => f.problem)).toContain("Section B: question 3 has 2 marks, not 3");
});

test("a gap report has one line per day left", () => {
  expect(gapReport.verify?.(gapInput(2), { summary: "s", days: [{ title: "Thursday", line: "l" }] }).map((f) => f.problem)).toEqual(["2 days left, 1 line"]);
  expect(gapReport.verify?.(gapInput(1), { summary: "s", days: [{ title: "Thursday", line: "x".repeat(190) }] }).map((f) => f.item)).toEqual(["Thursday"]);
  expect(gapReport.student?.(gapInput(1))?.id).toBe(studentId);
});

test("marking answers every scheme question once, within its marks", () => {
  const input = { pages: [page], scheme: "Q1 (2 marks) … Q2 (3 marks) …", schemeQuestions: [{ number: 1, marks: 2 }, { number: 2, marks: 3 }], studentName: "Dev Kumar" };
  expect(checkPaper.verify?.(input, { questions: [{ number: 1, text: "t", note: "n", marks: 2, of: 2 }, { number: 2, text: "t", note: "n", marks: 4, of: 3 }], summary: "s" }).map((f) => f.problem)).toEqual(["question 2: 4 marks of 3"]);
  expect(checkPaper.verify?.(input, { questions: [{ number: 1, text: "t", note: "n", marks: 2, of: 2 }], summary: "s" }).map((f) => f.problem)).toEqual(["question 2 of the scheme is not marked"]);
  expect(checkPaper.verify?.(input, { questions: [{ number: 1, text: "t", note: "n", marks: 2, of: 2 }, { number: 2, text: "t", note: "n", marks: 1, of: 2 }], summary: "s" }).map((f) => f.problem)).toEqual(["question 2 is out of 3 in the scheme, not 2"]);
  // A typed scheme gives no structure: a mark is held to its own maximum alone.
  expect(checkPaper.verify?.({ ...input, schemeQuestions: [] }, { questions: [{ number: 1, text: "t", note: "n", marks: 3, of: 2 }], summary: "s" }).map((f) => f.problem)).toEqual(["question 1: 3 marks of 2"]);
  expect(checkPaper.student?.({ ...input, studentId })).toEqual({ id: studentId, name: "Dev Kumar" });
});

test("a stored paper's or mock's questions and marks are the scheme's", () => {
  const stored: MockOutput = mockDraft([1, 3]);
  expect(schemeQuestions(stored, "mock")).toEqual([{ number: 1, marks: 1 }, { number: 2, marks: 3 }]);
  expect(schemeQuestions({ title: "t", instructions: null, questions: [] }, "homework")).toEqual([]);
});

test("read marks keeps a score within its maximum and an ISO date", () => {
  const input = { pages: [page], studentName: "Hemanth Reddy", studentId, subjects: ["Mathematics"] };
  expect(readMarks.verify?.(input, { marks: [{ subject: "Maths", test: "Unit test 2", date: "16/10/2026", score: 18, max: 20 }] }).map((f) => f.item)).toEqual(["Maths · Unit test 2"]);
  expect(readMarks.verify?.(input, { marks: [{ subject: "Maths", test: "Unit test 2", date: null, score: 21, max: 20 }] }).map((f) => f.problem)).toEqual(["21 of 20"]);
  expect(readMarks.verify?.(input, { marks: [{ subject: "Maths", test: "Unit test 2", date: "2026-10-16", score: 18, max: 20 }] })).toEqual([]);
  expect(readMarks.empty?.({ marks: [] })).toBe(true);
});

test("the four kinds keep the fake's known-good answer without a repair", async () => {
  const bodies = [
    [mock, mockInput()],
    [gapReport, gapInput(2)],
    [checkPaper, { pages: [page], scheme: "Q1 …", schemeQuestions: [], studentName: "Dev Kumar" }],
    [readMarks, { pages: [page], studentName: "Hemanth Reddy", studentId, subjects: [] }],
  ] as const;
  for (const [spec, input] of bodies) {
    const db = fakeDb();
    // biome-ignore lint/suspicious/noExplicitAny: each kind takes its own input.
    const out = await runAgent(ctx(db), spec as any, input);
    expect({ kind: spec.kind, outcome: out.kind, steps: db.rows.map((r) => r.agentStep) }).toEqual({ kind: spec.kind, outcome: "ok", steps: ["draft", "check"] });
  }
});
