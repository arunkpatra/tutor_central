import { expect, test } from "bun:test";
import { CheckPaperInput, GenerateInput, ScanRegisterInput } from "../src/schemas";

test("GenerateInput accepts each kind and rejects an unknown one", () => {
  expect(GenerateInput.safeParse({ kind: "paper", subject: "Maths", classLevel: "Class 10", topic: "Trigonometry", marks: 40, questions: 10 }).success).toBe(true);
  expect(GenerateInput.safeParse({ kind: "homework", subject: "Maths", classLevel: "Class 8", topic: "Fractions" }).success).toBe(true);
  expect(GenerateInput.safeParse({ kind: "worksheet", subject: "Science", classLevel: "Class 6", topic: "Plants" }).success).toBe(true);
  expect(GenerateInput.safeParse({ kind: "progress_note", studentName: "Dev", subject: "Maths", classLevel: "Class 8", observations: "Improving" }).success).toBe(true);
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
  expect(CheckPaperInput.safeParse({ pages: [ok], markingScheme: "Q1 5 marks" }).success).toBe(true);
  expect(CheckPaperInput.safeParse({ pages: [], markingScheme: "x" }).success).toBe(false);
  expect(CheckPaperInput.safeParse({ pages: Array(7).fill(ok), markingScheme: "x" }).success).toBe(false);
});
