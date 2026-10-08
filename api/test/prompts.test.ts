import { expect, test } from "bun:test";
import { request as check, schemeText } from "../src/prompts/check-paper.js";
import { request as paper } from "../src/prompts/paper.js";
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
