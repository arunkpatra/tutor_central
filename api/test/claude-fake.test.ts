import { expect, test } from "bun:test";
import { z } from "zod";
import { fakeClaude, kindOf, localScript, SAMPLE } from "../src/claude-fake.js";
import { request as briefRequest } from "../src/prompts/brief.js";
import { request as checkRequest } from "../src/prompts/check.js";
import { request as figureRequest } from "../src/prompts/figure.js";
import { request as placementRequest } from "../src/prompts/placement.js";
import { request as planRequest } from "../src/prompts/plan.js";
import { request as sheetRequest } from "../src/prompts/sheet.js";
import { request as workedExampleRequest } from "../src/prompts/worked-example.js";
import { PaperOutput } from "../src/schemas.js";
import { request as gapReportRequest } from "../src/prompts/gap-report.js";
import { request as mockRequest } from "../src/prompts/mock.js";
import { request as parseSchoolRequest } from "../src/prompts/parse-school.js";
import { request as testTomorrowRequest } from "../src/prompts/test-tomorrow.js";

const request = { model: "claude-sonnet-5-5" as const, effort: "medium" as const, system: "s", text: "t", schema: PaperOutput };

test("the fake answers what its script says and records the request", async () => {
  const ok = fakeClaude({ answer: SAMPLE.paper });
  const r = await ok.complete(request);
  expect(r.kind).toBe("ok");
  if (r.kind === "ok") expect(r.parsed.title).toBe("Quadratic equations");
  expect(ok.requests).toHaveLength(1);
  expect((await fakeClaude({ refuse: true }).complete(request)).kind).toBe("refused");
  const failed = await fakeClaude({ fail: "timeout" }).complete(request);
  expect(failed).toEqual({ kind: "failed", reason: "timeout" });
});

test("the fake's sample answers fit their schemas", () => {
  expect(PaperOutput.safeParse(SAMPLE.paper).success).toBe(true);
  expect(z.object({ note: z.string() }).safeParse(SAMPLE.progress_note).success).toBe(true);
});

test("a script can depend on the request", async () => {
  const byModel = fakeClaude((r) => (r.model === "claude-opus-5-5" ? { answer: SAMPLE.scan_register } : { refuse: true }));
  expect((await byModel.complete({ ...request, model: "claude-opus-5-5", schema: z.any() })).kind).toBe("ok");
  expect((await byModel.complete(request)).kind).toBe("refused");
});

test("a local run answers one check or placement question per name the request gives", () => {
  const checks = localScript(checkRequest("8", "Science", ["Name the reactants", "Read a thermometer"])).answer as { questions: { skill: string; question: string }[] };
  expect(checks.questions.map((q) => q.skill)).toEqual(["Name the reactants", "Read a thermometer"]);
  expect(checks.questions[0]?.question).toBe("In magnesium burning in air, what are the reactants?");
  const chapters = ["The Fish Tale", "Shapes and Angles", "How Many Squares?", "Parts and Wholes", "Does it Look the Same?"];
  const placement = localScript(placementRequest("5", "Mathematics", chapters)).answer as { questions: { chapter: string }[] };
  expect(placement.questions.map((q) => q.chapter)).toEqual(chapters);
});

// ---- Phase 12 ----
const centreId = "22222222-2222-2222-2222-222222222222";

test("kindOf tells the plan's five kinds apart and localScript answers each", () => {
  const sheetReq = sheetRequest({ kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], questions: 8, forHomework: false });
  expect(kindOf(sheetReq)).toBe("sheet");
  expect(kindOf(workedExampleRequest("8", "Science", "Balance a chemical equation"))).toBe("worked_example");
  expect(kindOf(figureRequest("fraction_bar", "5", "Mathematics", "Compare simple fractions"))).toBe("figure");
  expect(kindOf(briefRequest("8", "Science", "Chemical reactions"))).toBe("brief");
  expect(kindOf(planRequest({ centreId, classId: null, date: "2026-10-07", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }))).toBe("plan");
  const figure = localScript(figureRequest("number_line", "3", "Mathematics", "Count on a number line"));
  expect((figure.answer as { figure: { kind: string } }).figure.kind).toBe("number_line");
});

test("kindOf tells the school kinds apart", () => {
  expect(kindOf(parseSchoolRequest({ text: "x", image: null, today: "2026-10-07", schools: [], classLevels: [] }))).toBe("parse_school");
  expect(kindOf(parseSchoolRequest({ text: null, image: { mediaType: "image/jpeg", base64: "AAAA", bytes: 3 }, today: "2026-10-07", schools: [], classLevels: [] }))).toBe("parse_school");
  expect(kindOf(mockRequest({ kind: "mock", centreId: "c", classLevel: "8", subject: "Science", title: "T", portions: ["x"], pattern: { marks: 25, durationMinutes: 40 } }))).toBe("mock");
  expect(kindOf(gapReportRequest({ kind: "gap_report", centreId: "c", studentId: "s", classLevel: "8", subject: "Science", daysLeft: 1, bySkill: [{ skill: "x", right: 1, of: 2 }] }))).toBe("gap_report");
  expect(kindOf(testTomorrowRequest({ kind: "test_tomorrow", centreId: "c", studentId: "s", studentName: "D", tutorName: "M", centreName: "B", language: "hi", subject: "Science", title: "T", date: "2026-10-08" }))).toBe("test_tomorrow");
});

test("the local script reads a photo as two exams and a message as the board's three items", () => {
  const photo = localScript(parseSchoolRequest({ text: null, image: { mediaType: "image/jpeg", base64: "AAAA", bytes: 3 }, today: "2026-10-07", schools: [], classLevels: [] }));
  expect((photo.answer as { items: { kind: string }[] }).items.map((i) => i.kind)).toEqual(["exam", "exam"]);
  const text = localScript(parseSchoolRequest({ text: "Dear Parents", image: null, today: "2026-10-07", schools: [], classLevels: [] }));
  expect((text.answer as { items: { kind: string }[] }).items.map((i) => i.kind)).toEqual(["exam", "homework", "holiday"]);
});

test("the local mock's marks sum to the pattern asked for", () => {
  const r = mockRequest({ kind: "mock", centreId: "c", classLevel: "8", subject: "Science", title: "T", portions: ["x"], pattern: { marks: 40, durationMinutes: 60 } });
  const made = localScript(r).answer as { sections: { questions: { marks: number }[] }[] };
  expect(made.sections.flatMap((s) => s.questions).reduce((n, q) => n + q.marks, 0)).toBe(40);
});
