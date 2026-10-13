import { expect, test } from "bun:test";
import { runAgent } from "../src/agents/agent.js";
import { brief, check, figure, parseSchool, parseTextbook, placement, plan, sheet, workedExample } from "../src/agents/kinds/index.js";
import { fakeClaude, localAnswer, PASS, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import type { DecodedImage } from "../src/images.js";
import { MakeInput, type SheetInput } from "../src/schemas.js";

// The nine kinds on their agents (D99, plan decision 13): each kind's free rules, then the agent around them.
const centreId = "22222222-2222-2222-2222-222222222222";
const ctx = (claude: ReturnType<typeof fakeClaude>, db = fakeDb()) => ({ db, claude, token: "t", requestId: "r", centre: centreId, key: "k", inputHash: "h" });
const image: DecodedImage = { mediaType: "image/png", base64: "iVBORw0KGgo=", bytes: 8 };
const sheetInput = (questions: number) => MakeInput.parse({ centreId, kind: "sheet", classLevel: "8", subject: "Mathematics", skills: ["Solve a linear equation"], questions }) as SheetInput;
const q = (number: number, expression: string, equals = 20) => ({ number, text: "Solve 3x + 5 = 20.", answer: "x = 5", proof: { expression, equals } });

test("a sheet with a planted wrong proof is a finding; the count and the numbering are held", () => {
  const good = { title: "Linear equations", instructions: null, questions: [1, 2, 3, 4].map((n) => q(n, "3*5+5")) };
  expect(sheet.verify?.(sheetInput(4), good)).toEqual([]);
  expect(sheet.verify?.(sheetInput(4), { ...good, questions: [q(1, "3*6+5"), ...good.questions.slice(1)] })).toEqual([{ item: "question 1", problem: "its proof 3*6+5 does not equal 20" }]);
  expect(sheet.verify?.(sheetInput(5), good)?.[0]).toEqual({ item: "questions", problem: "there are 4 questions; exactly 5 were asked" });
  expect(sheet.verify?.(sheetInput(4), { ...good, questions: good.questions.map((x, i) => ({ ...x, number: i + 2 })) })?.[0]?.item).toBe("question 1");
});

test("a sheet still wrong after its repair is refused; the repair asked is quoted", async () => {
  const claude = fakeClaude((r) => (r.system.shared.startsWith("You check a draft") ? { answer: PASS } : { answer: { title: "t", instructions: null, questions: [1, 2, 3, 4].map((n) => q(n, "3*6+5")) } }));
  const out = await runAgent(ctx(claude), sheet, sheetInput(4));
  expect(out).toMatchObject({ kind: "failed", reason: "check:question 1", words: "refused" });
});

test("a figure of another template, or whose triangle sums to 190, is a finding", () => {
  const input = { figure: "triangle" as const, classLevel: "7" as const, subject: "Mathematics", skill: "Angle sum" };
  expect(figure.verify?.(input, { figure: { kind: "triangle", angles: [90, 50, 40], labels: ["a", "b", "c"] }, caption: "x" })).toEqual([]);
  expect(figure.verify?.(input, { figure: { kind: "triangle", angles: [100, 50, 40], labels: ["a", "b", "c"] }, caption: "x" })).toEqual([{ item: "figure", problem: "the angles sum to 180" }]);
  expect(figure.verify?.(input, { figure: { kind: "fraction_bar", parts: 4, shaded: 1, label: "1/4" }, caption: "x" })?.[0]?.problem).toContain("the template asked for is triangle");
});

test("a check with two skills and one question is a finding; a long answer is too", () => {
  const input = { classLevel: "8" as const, subject: "Science", skills: ["Balance a chemical equation", "Name the reactants"] };
  const one = { questions: [{ skill: "Balance a chemical equation", question: "Balance H2 + O2 → H2O.", answer: "2H2 + O2 → 2H2O" }] };
  expect(check.verify?.(input, one)?.[0]?.item).toBe("skills");
  const long = { questions: [...one.questions, { skill: "Name the reactants", question: "Name them.", answer: "the reactants are the substances that are present at the start of a reaction before anything changes at all" }] };
  expect(check.verify?.(input, long)).toEqual([{ item: "Name the reactants", problem: "the answer is longer than twelve words" }]);
  expect(placement.verify?.({ classLevel: "5", subject: "Mathematics", chapters: ["A", "B"] }, { questions: [{ chapter: "B", question: "q", answer: "a" }, { chapter: "A", question: "q", answer: "a" }] })?.[0]?.item).toBe("chapters");
});

test("a textbook page with no chapters is refused as empty without a check call", async () => {
  const claude = fakeClaude({ answer: { title: null, chapters: [] } });
  const db = fakeDb();
  expect(await runAgent(ctx(claude, db), parseTextbook, { image, classLevel: "8", subject: "Science" })).toMatchObject({ kind: "failed", reason: "refused" });
  expect(claude.requests).toHaveLength(1);
  expect(db.rows.map((r) => r.agentStep)).toEqual(["draft"]);
});

test("parse_school refuses a class not at the centre, a school not given and a date over 400 days old", () => {
  const source = { text: "x", image: null, today: "2026-10-13", schools: ["Vidya Niketan"], classLevels: ["8" as const] };
  const item = { kind: "exam" as const, title: "Science unit test", subject: "Science", date: "2026-10-16", endDate: null, classLevel: "8" as const, school: "Vidya Niketan", studentName: null, portions: null };
  expect(parseSchool.verify?.(source, { items: [item] })).toEqual([]);
  expect(parseSchool.verify?.(source, { items: [{ ...item, classLevel: "10" }] })).toEqual([{ item: "item 1", problem: "class 10 is not one of the centre's classes" }]);
  expect(parseSchool.verify?.(source, { items: [{ ...item, school: "St Mary's" }] })?.[0]?.problem).toContain("not one of the schools given");
  expect(parseSchool.verify?.(source, { items: [{ ...item, date: "2025-01-01" }] })?.[0]?.problem).toContain("more than 400 days before today");
});

test("the plan's naming asks one topic per unnamed group", () => {
  const input = { centreId, classId: null, date: "2026-10-13", month: 10, groups: [{ groupNo: 1, classLevel: "8" as const, subject: "Science" }, { groupNo: 3, classLevel: "8" as const, subject: "Mathematics" }] };
  expect(plan.verify?.(input, { groups: [{ groupNo: 1, chapter: "c", skill: "s" }, { groupNo: 3, chapter: "c", skill: "s" }] })).toEqual([]);
  expect(plan.verify?.(input, { groups: [{ groupNo: 1, chapter: "c", skill: "s" }] })).toEqual([{ item: "groups", problem: "one topic for each group asked: 1, 3" }]);
});

test("the fake's answers for the nine kinds pass their own rules (review focus 1: a known-good draft is kept unrepaired)", async () => {
  const bodies = {
    sheet: [sheet, sheetInput(8)],
    worked_example: [workedExample, { classLevel: "8", subject: "Science", skill: "Balance a chemical equation" }],
    figure: [figure, { figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "Compare simple fractions" }],
    brief: [brief, { classLevel: "8", subject: "Science", chapter: "Chemical reactions" }],
    check: [check, { classLevel: "8", subject: "Science", skills: ["Balance a chemical equation", "Name the reactants"] }],
    placement: [placement, { classLevel: "5", subject: "Mathematics", chapters: ["The Fish Tale", "Shapes and Angles"] }],
    plan: [plan, { centreId, month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }],
    parse_textbook: [parseTextbook, { image, classLevel: "5", subject: "Mathematics" }],
    parse_school: [parseSchool, { text: "Science unit test 3 on Friday 16 October.", image: null, today: "2026-10-13", schools: ["Vidya Niketan"], classLevels: ["8"] }],
  } as const;
  for (const [kind, [spec, input]] of Object.entries(bodies)) {
    const claude = fakeClaude((r) => ({ answer: localAnswer(r) }));
    const db = fakeDb();
    // biome-ignore lint/suspicious/noExplicitAny: each kind takes its own input.
    const out = await runAgent(ctx(claude, db), spec as any, input);
    expect({ kind, outcome: out.kind, repaired: (out as { repaired?: boolean }).repaired, steps: db.rows.map((r) => r.agentStep) }).toEqual({ kind, outcome: "ok", repaired: false, steps: ["draft", "check"] });
  }
  expect(SAMPLE.figure.figure.kind).toBe("fraction_bar");
});
