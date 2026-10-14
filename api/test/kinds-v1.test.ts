import { expect, test } from "bun:test";
import { runAgent } from "../src/agents/agent.js";
import { homework, paper, progressNote, scanRegister, worksheet } from "../src/agents/kinds/index.js";
import { fakeClaude, localAnswer } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import type { DecodedImage } from "../src/images.js";
import { type PlannedSection, sectionPlan } from "../src/prompts/paper.js";
import { GenerateInput, type HomeworkInput, type NoteInput, type PaperInput, type PaperOutput, type QuestionSetOutput, type WorksheetInput } from "../src/schemas.js";

// Phase 21 Task 9: Make's V1 kinds on their agents (D99): a paper follows its section plan, homework and a worksheet have
// the questions asked, a progress note is four to six sentences with no sign-off, a register's rows are tidy.
const common = { subject: "Mathematics", classLevel: "Class 10" };
const paperInput = (over: { questions: number; marks: number }) => GenerateInput.parse({ kind: "paper", ...common, topic: "Quadratic equations", ...over }) as PaperInput;
const homeworkInput = (over: { questions: number }) => GenerateInput.parse({ kind: "homework", ...common, topic: "Cells", ...over }) as HomeworkInput;
const worksheetInput = (over: { questions: number }) => GenerateInput.parse({ kind: "worksheet", ...common, topic: "Linear equations", ...over }) as WorksheetInput;
const noteInput = () =>
  GenerateInput.parse({ kind: "progress_note", ...common, studentId: "a0000000-0000-4000-8000-000000000011", studentName: "Hemanth Reddy", parentName: "Lakshmi Reddy", observations: "Careful with signs now.", tutorName: "Meera", centreName: "Bright Minds" }) as NoteInput;
const page: DecodedImage = { mediaType: "image/png", base64: "iVBORw0KGgo=", bytes: 8 };
const scanInput = () => ({ image: page });

/** A paper in sections of the counts given, numbered through, every answer given. */
function paperDraft(plan: PlannedSection[]): PaperOutput {
  let n = 0;
  return {
    title: "Quadratic equations",
    sections: plan.map((s) => ({
      title: s.title,
      marksEach: s.marksEach,
      questions: Array.from({ length: s.count }, () => ({ number: ++n, text: `Question ${n}`, marks: s.marksEach, answer: "x = 3" })),
    })),
  };
}
const setDraft = (count: number): QuestionSetOutput => ({ title: "t", instructions: null, questions: Array.from({ length: count }, (_, i) => ({ number: i + 1, text: `Q${i + 1}`, answer: "a" })) });

test("a paper follows the section plan it was given", () => {
  const input = paperInput({ questions: 10, marks: 20 });
  const plan = sectionPlan(10, 20);
  expect(plan.map((s) => [s.count, s.marksEach])).toEqual([[4, 1], [4, 2], [2, 4]]);
  expect(paper.verify?.(input, paperDraft(plan))).toEqual([]);
  const [a, b, c] = plan as [PlannedSection, PlannedSection, PlannedSection];
  expect(paper.verify?.(input, paperDraft([{ ...a, count: 5 }, b, { ...c, count: 1 }])).map((f) => f.problem)).toEqual(["Section A has 5 questions, not 4", "Section C has 1 question, not 2"]);
});

test("a paper's numbers run 1 to n through it, every question has its answer and its section's marks", () => {
  const input = paperInput({ questions: 10, marks: 20 });
  const draft = paperDraft(sectionPlan(10, 20));
  const broken = structuredClone(draft);
  const first = broken.sections[0]?.questions[0] as { number: number; answer: string; marks: number };
  first.number = 7;
  first.answer = " ";
  first.marks = 3;
  expect(paper.verify?.(input, broken).map((f) => f.problem)).toEqual(["number the questions 1 to n in order through the paper", "question 7 has no answer", "Section A: question 7 has 3 marks, not 1"]);
  expect(paper.verify?.(input, { ...draft, sections: draft.sections.slice(0, 2) }).map((f) => f.problem)).toEqual(["2 sections, not 3"]);
});

test("homework and a worksheet have exactly the questions asked", () => {
  expect(homework.verify?.(homeworkInput({ questions: 5 }), setDraft(4)).map((f) => f.problem)).toEqual(["4 questions, not 5"]);
  expect(worksheet.verify?.(worksheetInput({ questions: 10 }), setDraft(10))).toEqual([]);
  const skipped = { ...setDraft(3), questions: setDraft(3).questions.map((q) => ({ ...q, number: q.number + 1 })) };
  expect(worksheet.verify?.(worksheetInput({ questions: 3 }), skipped).map((f) => f.item)).toEqual(["numbering"]);
});

test("a progress note is four to six sentences to the parent about the student, with no sign-off", () => {
  expect(progressNote.verify?.(noteInput(), { note: "Hello Lakshmi. Hemanth is careful with signs now. He got most sums right. Keep it up at home. Regards, Meera" }).map((f) => f.item)).toEqual(["sign-off"]);
  expect(progressNote.verify?.(noteInput(), { note: "Hello Lakshmi. Hemanth is careful. Good." }).map((f) => f.problem)).toEqual(["3 sentences; four to six"]);
  expect(progressNote.verify?.(noteInput(), { note: "Hello. The student is careful with signs now. Most sums are right. Practise at home. Thank you." }).map((f) => f.item)).toEqual(["names"]);
  expect(progressNote.verify?.(noteInput(), { note: "Hello Lakshmi. Hemanth is careful with signs now. He got most sums right. Keep it up at home." })).toEqual([]);
  expect(progressNote.student?.(noteInput())?.name).toBe("Hemanth Reddy");
});

test("a register's rows are tidy: a name each, capitalised, a phone that is a number or none", () => {
  expect(scanRegister.verify?.(scanInput(), { rows: [{ name: "", phone: null, fee: null }] }).map((f) => f.problem)).toEqual(["row 1 has no name"]);
  expect(scanRegister.verify?.(scanInput(), { rows: [{ name: "aarav mehta", phone: "98765", fee: 1200 }] }).map((f) => f.problem)).toEqual([
    "row 1's name is not capitalised word by word",
    "row 1's phone is not a ten-digit number: null when it cannot be read",
  ]);
  expect(scanRegister.verify?.(scanInput(), { rows: [{ name: "Diya Pillai", phone: "99887 76655", fee: 1200 }, { name: "Kavya Nair", phone: "", fee: null }] })).toEqual([]);
  expect(scanRegister.keep?.({ rows: [{ name: "Diya Pillai", phone: "99887 76655", fee: 1200 }] }).rows[0]?.phone).toBe("+919988776655");
});

test("each V1 kind's local answer passes its own agent: a paper, homework, a worksheet, a note, a register", async () => {
  const centreId = "22222222-2222-2222-2222-222222222222";
  const ctx = { db: fakeDb(), claude: fakeClaude((r) => ({ answer: localAnswer(r) })), token: "t", requestId: "r", centre: centreId, key: "k", inputHash: "h" };
  const big: DecodedImage = { mediaType: "image/png", base64: "A".repeat(2000), bytes: 1500 };
  const runs = [
    await runAgent({ ...ctx, key: "p" }, paper, paperInput({ questions: 15, marks: 50 })),
    await runAgent({ ...ctx, key: "h" }, homework, homeworkInput({ questions: 7 })),
    await runAgent({ ...ctx, key: "w" }, worksheet, worksheetInput({ questions: 10 })),
    await runAgent({ ...ctx, key: "n" }, progressNote, noteInput()),
    await runAgent({ ...ctx, key: "s" }, scanRegister, { image: big }),
  ];
  expect(runs.map((r) => [r.kind, r.kind === "ok" ? r.repaired : null])).toEqual([["ok", false], ["ok", false], ["ok", false], ["ok", false], ["ok", false]]);
});
