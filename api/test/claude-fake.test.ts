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
