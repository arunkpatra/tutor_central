import { expect, test } from "bun:test";
import { request as check, schemeText } from "../src/prompts/check-paper.js";
import { request as paper, sectionPlan } from "../src/prompts/paper.js";
import { request as textbookRequest } from "../src/prompts/parse-textbook.js";
import { request as note } from "../src/prompts/progress-note.js";
import { normalisePhone, request as scan } from "../src/prompts/scan-register.js";
import { GenerateInput } from "../src/schemas.js";

test("a paper asks Sonnet at medium effort for sections, marks and answers that add up", () => {
  const input = GenerateInput.parse({ kind: "paper", subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" });
  if (input.kind !== "paper") throw new Error("kind");
  const r = paper(input);
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.effort).toBe("medium");
  expect(r.text).toContain("Quadratic equations");
  expect(r.text).toContain("20 marks");
  expect(r.system).toContain("Indian");
  expect(r.images).toBeUndefined();
});

test("a progress note is written to the parent in the tutor's voice, with the attendance line when given", () => {
  const input = GenerateInput.parse({
    kind: "progress_note",
    subject: "Mathematics",
    classLevel: "Class 10 Maths",
    studentName: "Hemanth Reddy",
    parentName: "Lakshmi Reddy",
    observations: "Careless with signs",
    attendanceLine: "2 of 3 classes attended",
    tutorName: "Meera Nair",
    centreName: "Bright Minds Tuition",
  });
  if (input.kind !== "progress_note") throw new Error("kind");
  const r = note(input);
  expect(r.text).toContain("Lakshmi");
  expect(r.text).toContain("2 of 3 classes attended");
  expect(r.system).toContain("no signature");
});

test("a scan asks Opus at high effort with the page first, and phones are normalised to +91", () => {
  const r = scan({ mediaType: "image/jpeg", base64: "AAAA", bytes: 3 });
  expect(r.model).toBe("claude-opus-5-5");
  expect(r.effort).toBe("high");
  expect(r.images?.[0]?.base64).toBe("AAAA");
  expect(normalisePhone("98765 43210")).toBe("+919876543210");
  expect(normalisePhone("+91 98848 43831")).toBe("+919884843831");
  expect(normalisePhone("919884843831")).toBe("+919884843831");
  expect(normalisePhone("4321")).toBeNull();
  expect(normalisePhone(null)).toBeNull();
  // A trunk 0 and 0091 (Phase 6's minor 6), as the app's PhoneNumber reads them; a mobile starts 6 to 9.
  expect(normalisePhone("09876543210")).toBe("+919876543210");
  expect(normalisePhone("0091 98765 43210")).toBe("+919876543210");
  expect(normalisePhone("0987654321")).toBeNull();
  expect(normalisePhone("1234567890")).toBeNull();
});

test("a check sends every page in order with the scheme text; a paper's output becomes a scheme", () => {
  const pages = [1, 2].map((n) => ({ mediaType: "image/png" as const, base64: `P${n}`, bytes: 2 }));
  const r = check(pages, "Q1 (1) b", "Hemanth Reddy");
  expect(r.images?.map((i) => i.base64)).toEqual(["P1", "P2"]);
  expect(r.text).toContain("Q1 (1) b");
  const stored = JSON.stringify({
    title: "Quadratic equations",
    sections: [{ title: "Section A", marksEach: 1, questions: [{ number: 1, text: "Which…", marks: 1, answer: "b" }] }],
  });
  expect(schemeText(JSON.parse(stored), "paper")).toBe("Quadratic equations\nQ1 (1 mark) Which… → b");
  expect(schemeText({ title: "H", instructions: null, questions: [{ number: 1, text: "q", answer: "a" }] }, "homework")).toBe("H\nQ1 q → a");
  expect(schemeText({ note: "x" }, "progress_note")).toBeNull();
});

test("a paper's sections are planned by the API so the marks always add up", () => {
  for (const [questions, marks] of [[10, 20], [10, 40], [5, 5], [1, 20], [50, 100], [7, 23], [12, 50], [3, 100]] as const) {
    const plan = sectionPlan(questions, marks);
    expect({ questions, marks, q: plan.reduce((n, s) => n + s.count, 0), m: plan.reduce((n, s) => n + s.count * s.marksEach, 0) }).toEqual({ questions, marks, q: questions, m: marks });
    expect(plan.every((s) => s.count > 0 && s.marksEach > 0)).toBe(true);
  }
  expect(sectionPlan(10, 20)).toEqual([
    { title: "Section A", count: 4, marksEach: 1 },
    { title: "Section B", count: 4, marksEach: 2 },
    { title: "Section C", count: 2, marksEach: 4 },
  ]);
  const input = GenerateInput.parse({ kind: "paper", subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" });
  if (input.kind !== "paper") throw new Error("kind");
  expect(paper(input).text).toContain("Section C: 2 questions of 4 marks each");
});

test("the textbook prompt asks for chapter names and short skills, never the book's text", () => {
  const r = textbookRequest({ mediaType: "image/jpeg", base64: "AAAA", bytes: 3 }, "5", "Mathematics");
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.system).toContain("chapter names as printed");
  expect(r.system).toContain("never copy");
  expect(r.text).toContain("class 5");
});
