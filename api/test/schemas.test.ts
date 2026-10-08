import { expect, test } from "bun:test";
import { CheckOutput, CheckPaperInput, GenerateInput, PaperOutput, ScanOutput, ScanRegisterInput } from "../src/schemas.js";

test("GenerateInput accepts each kind and rejects an unknown one", () => {
  expect(GenerateInput.safeParse({ kind: "paper", subject: "Maths", classLevel: "Class 10", topic: "Trigonometry", marks: 40, questions: 10 }).success).toBe(true);
  expect(GenerateInput.safeParse({ kind: "homework", subject: "Maths", classLevel: "Class 8", topic: "Fractions" }).success).toBe(true);
  expect(GenerateInput.safeParse({ kind: "worksheet", subject: "Science", classLevel: "Class 6", topic: "Plants" }).success).toBe(true);
  expect(GenerateInput.safeParse({ kind: "progress_note", studentName: "Dev", subject: "Maths", classLevel: "Class 8", observations: "Improving", tutorName: "Meera Nair", centreName: "Bright Minds" }).success).toBe(true);
  expect(GenerateInput.safeParse({ kind: "poem", subject: "Maths", classLevel: "Class 10", topic: "x" }).success).toBe(false);
});

test("GenerateInput fills defaults and bounds the numbers", () => {
  const r = GenerateInput.parse({ kind: "paper", subject: "Maths", classLevel: "Class 10", topic: "Algebra" });
  expect(r).toMatchObject({ marks: 20, questions: 10 });
  expect(GenerateInput.safeParse({ kind: "paper", subject: "Maths", classLevel: "Class 10", topic: "Algebra", marks: 1000 }).success).toBe(false);
  expect(GenerateInput.safeParse({ kind: "homework", subject: "", classLevel: "Class 8", topic: "Fractions" }).success).toBe(false);
});

test("image inputs limit size and type", () => {
  const ok = { imageBase64: "AAAA", mediaType: "image/jpeg" };
  expect(ScanRegisterInput.safeParse(ok).success).toBe(true);
  expect(ScanRegisterInput.safeParse({ ...ok, mediaType: "image/gif" }).success).toBe(false);
  expect(ScanRegisterInput.safeParse({ ...ok, imageBase64: "" }).success).toBe(false);
  const scheme = { kind: "typed", text: "Q1 5 marks" };
  expect(CheckPaperInput.safeParse({ pages: [ok], scheme, studentName: "Dev" }).success).toBe(true);
  expect(CheckPaperInput.safeParse({ pages: [], scheme, studentName: "Dev" }).success).toBe(false);
  expect(CheckPaperInput.safeParse({ pages: Array(7).fill(ok), scheme, studentName: "Dev" }).success).toBe(false);
  expect(ScanRegisterInput.safeParse({ ...ok, imageBase64: "A".repeat(4_000_001) }).success).toBe(false);
});

test("GenerateInput takes the level, the worksheet's answer switch and the note's context", () => {
  const paper = GenerateInput.parse({ kind: "paper", subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" });
  expect(paper).toMatchObject({ level: "medium", marks: 20, questions: 10 });
  expect(GenerateInput.safeParse({ kind: "paper", subject: "M", classLevel: "C", topic: "T", level: "brutal" }).success).toBe(false);
  expect(GenerateInput.parse({ kind: "worksheet", subject: "M", classLevel: "C", topic: "T" })).toMatchObject({ withAnswers: true, questions: 10 });
  const note = GenerateInput.parse({
    kind: "progress_note",
    subject: "Mathematics",
    classLevel: "Class 10 Maths",
    studentName: "Hemanth Reddy",
    parentName: "Lakshmi Reddy",
    observations: "Improving",
    attendanceLine: "2 of 3 classes attended",
    tutorName: "Meera Nair",
    centreName: "Bright Minds Tuition",
  });
  expect(note).toMatchObject({ tone: "warm" });
  const long = { kind: "progress_note", subject: "M", classLevel: "C", studentName: "H", observations: "x".repeat(2001), tutorName: "M", centreName: "B" };
  expect(GenerateInput.safeParse(long).success).toBe(false);
});

test("CheckPaperInput takes a typed scheme or a paper's id, and caps the pages together", () => {
  const page = { imageBase64: "A".repeat(1_000_000), mediaType: "image/jpeg" };
  const id = "fbc6ae19-2769-4934-bf10-c830207fd6a3";
  expect(CheckPaperInput.safeParse({ pages: [page], scheme: { kind: "typed", text: "Q1 (1) b" }, studentName: "Hemanth Reddy" }).success).toBe(true);
  expect(CheckPaperInput.safeParse({ pages: [page], scheme: { kind: "paper", generationId: id }, studentName: "H" }).success).toBe(true);
  expect(CheckPaperInput.safeParse({ pages: [page], scheme: { kind: "paper", generationId: "not-a-uuid" }, studentName: "H" }).success).toBe(false);
  expect(CheckPaperInput.safeParse({ pages: Array(5).fill(page), scheme: { kind: "typed", text: "x" }, studentName: "H" }).success).toBe(false);
  const tiny = { ...page, imageBase64: "A" };
  expect(CheckPaperInput.safeParse({ pages: Array(7).fill(tiny), scheme: { kind: "typed", text: "x" }, studentName: "H" }).success).toBe(false);
});

test("the outputs hold Claude to the shape the app decodes", () => {
  const question = { number: 1, text: "q", marks: 1, answer: "a" };
  expect(PaperOutput.safeParse({ title: "T", sections: [{ title: "A", marksEach: 1, questions: [question] }] }).success).toBe(true);
  expect(PaperOutput.safeParse({ title: "T", sections: [] }).success).toBe(false);
  expect(ScanOutput.safeParse({ rows: [{ name: "Aarav Mehta", phone: null, fee: null }] }).success).toBe(true);
  // A mark over its maximum is clamped by the app, not refused here.
  expect(CheckOutput.safeParse({ questions: [{ number: 1, text: "q", note: "n", marks: 2, of: 1 }], summary: "s" }).success).toBe(true);
});
