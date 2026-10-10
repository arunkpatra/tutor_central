import { expect, test } from "bun:test";
import {
  CheckOutput,
  CheckPaperInput,
  GenerateInput,
  MakeInput,
  PaperOutput,
  ParseSchoolInput,
  ParseTextbookInput,
  PlanInput,
  ScanOutput,
  ScanRegisterInput,
  Scheme,
} from "../src/schemas.js";

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

test("lengths count code points, as the app and Postgres do (D48)", () => {
  const note = { kind: "progress_note", subject: "M", classLevel: "C", studentName: "H", tutorName: "M", centreName: "B" };
  // 1,500 code points but 3,000 UTF-16 units: the app and Postgres accept it, so the API must.
  expect(GenerateInput.safeParse({ ...note, observations: "😀".repeat(1500) }).success).toBe(true);
  expect(GenerateInput.safeParse({ ...note, observations: "क्ष".repeat(700) }).success).toBe(false); // 2,100
  expect(GenerateInput.safeParse({ ...note, observations: "क्ष".repeat(600) }).success).toBe(true); // 1,800
  const page = { imageBase64: "AAAA", mediaType: "image/jpeg" };
  const typed = (text: string) => CheckPaperInput.safeParse({ pages: [page], scheme: { kind: "typed", text }, studentName: "H" });
  expect(typed("👩‍🏫".repeat(1000)).success).toBe(true); // 3,000 code points, 5,000 UTF-16 units
  expect(typed("👩‍🏫".repeat(1400)).success).toBe(false); // 4,200 code points
  expect(GenerateInput.safeParse({ kind: "homework", subject: "गणित".repeat(20), classLevel: "C", topic: "T" }).success).toBe(true);
});

const centre = { centreId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718" };
const studentId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719";

test("PlanInput takes a batch and a day", () => {
  expect(PlanInput.safeParse({ ...centre, classId: null, date: "2026-10-12" }).success).toBe(true);
  expect(PlanInput.safeParse({ ...centre, classId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60730", date: "2026-10-12" }).success).toBe(true);
  expect(PlanInput.safeParse({ ...centre, classId: null, date: "12/10/2026" }).success).toBe(false);
});

test("MakeInput accepts each kind with its fields and nothing else", () => {
  const c = centre;
  expect(MakeInput.safeParse({ ...c, kind: "sheet", classLevel: "5", subject: "Mathematics", skills: ["Halves"], questions: 10, forHomework: true }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "worked_example", classLevel: "9", subject: "Mathematics", skill: "Rationalising denominators" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "figure", figure: "fraction_bar", classLevel: "4", subject: "Mathematics", skill: "Quarters" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "figure", figure: "pie_chart", classLevel: "4", subject: "Mathematics", skill: "Quarters" }).success).toBe(false);
  expect(MakeInput.safeParse({ ...c, kind: "brief", classLevel: "10", subject: "Mathematics", chapter: "Trigonometry" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "check", classLevel: "6", subject: "Science", skills: ["Cells", "Tissues", "Organs"] }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "check", classLevel: "6", subject: "Science", skills: ["Cells"] }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "check", classLevel: "6", subject: "Science", skills: [] }).success).toBe(false);
  expect(MakeInput.safeParse({ ...c, kind: "check", classLevel: "6", subject: "Science", skills: ["A", "B", "C", "D"] }).success).toBe(false);
  expect(MakeInput.safeParse({ ...c, kind: "placement", classLevel: "7", subject: "English", chapters: ["Chapter 1", "Chapter 2"] }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "mock", classLevel: "10", subject: "Science", portions: ["Light", "Electricity"], pattern: { marks: 40, durationMinutes: 90 } }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "note", studentId, studentName: "Dev", language: "kn", week: { taught: ["Halves"], right: ["Halves"], practise: ["Quarters"], coming: [] }, tutorName: "Meera" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "can_do", studentId, studentName: "Anu", language: "en", ladder: { reading: "words", writing: "letters", numbers: "to_99" }, tutorName: "Meera" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "test_tomorrow", studentId, studentName: "Anu", language: "hinglish", subject: "Science", date: "2026-11-02", portions: "Chapters 1 to 3", tutorName: "Meera" }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "gap_report", studentId, marking: [{ question: 1, marks: 2, max: 5, note: "Sign error" }] }).success).toBe(true);
  expect(MakeInput.safeParse({ ...c, kind: "note", studentId, studentName: "Dev", language: "ta", week: { taught: [], right: [], practise: [], coming: [] }, tutorName: "Meera" }).success).toBe(false);
  expect(MakeInput.safeParse({ ...c, kind: "sheet", classLevel: "11", subject: "Mathematics", skills: ["Halves"] }).success).toBe(false);
  expect(MakeInput.safeParse({ ...c, kind: "poem", classLevel: "5" }).success).toBe(false);
});

test("a sheet takes its defaults", () => {
  expect(MakeInput.parse({ ...centre, kind: "sheet", classLevel: "3", subject: "English", skills: ["Rhyming words"] })).toMatchObject({ questions: 10, forHomework: false });
});

test("the parsers take text or a photo, and a contents photo with its class and subject", () => {
  const img = { imageBase64: "AAAA", mediaType: "image/jpeg" };
  const c = centre;
  expect(ParseSchoolInput.safeParse({ ...c, text: "Science test on 2 Nov, ch 1-3" }).success).toBe(true);
  expect(ParseSchoolInput.safeParse({ ...c, image: img }).success).toBe(true);
  expect(ParseSchoolInput.safeParse({ ...c }).success).toBe(false);
  expect(ParseTextbookInput.safeParse({ ...c, image: img, classLevel: "5", subject: "Mathematics" }).success).toBe(true);
  expect(ParseTextbookInput.safeParse({ ...c, image: img, classLevel: "11", subject: "Mathematics" }).success).toBe(false);
});

test("Scheme accepts a mock's key", () => {
  expect(Scheme.safeParse({ kind: "mock", artefactId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60720" }).success).toBe(true);
  expect(Scheme.safeParse({ kind: "mock", artefactId: "nope" }).success).toBe(false);
});

test("a mock takes the board's blueprint as the syllabus data writes it", async () => {
  for (const file of ["cbse/10/social-science.json", "cbse/10/science.json", "karnataka/10/english.json"]) {
    const { blueprint } = await Bun.file(`${import.meta.dir}/../../supabase/syllabi/${file}`).json();
    const parsed = MakeInput.safeParse({ ...centre, kind: "mock", classLevel: "10", subject: "Science", portions: ["All"], pattern: blueprint });
    expect({ file, ok: parsed.success }).toEqual({ file, ok: true });
  }
});
