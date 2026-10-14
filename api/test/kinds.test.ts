import { expect, test } from "bun:test";
import { runAgent } from "../src/agents/agent.js";
import { brief, check, figure, parseSchool, parseTextbook, placement, plan, sheet, workedExample } from "../src/agents/kinds/index.js";
import { numberLineCaptionFindings } from "../src/agents/kinds/figure.js";
import { oneQuestionFindings } from "../src/agents/kinds/placement.js";
import { chapterInSyllabus } from "../src/agents/kinds/plan.js";
import { workedExampleFindings } from "../src/agents/kinds/worked-example.js";
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
  expect(plan.verify?.(input, { groups: [{ groupNo: 1, chapter: "Exploring Forces", skill: "s" }, { groupNo: 3, chapter: "Number Play", skill: "s" }] })).toEqual([]);
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

// ---- Phase 21, Task 1: the first nightly's failures (D105), each a free rule where it can be computed ----

test("a slip whose wrong answer does not follow from its working is a finding; a slip equal to the right answer too", () => {
  const example = { problem: "p", steps: [{ title: "a", working: "b" }, { title: "c", working: "d" }], slip: "A common slip here: 27 − 273 = 246.", proof: { expression: "27+273", equals: 300 }, slipProof: { expression: "27-273", equals: 246 } };
  expect(workedExampleFindings(example).map((f) => f.item)).toEqual(["slip"]);
  expect(workedExampleFindings({ ...example, slipProof: { expression: "27-273", equals: -246 } })).toEqual([]);
  expect(workedExampleFindings({ ...example, slipProof: { expression: "27+273", equals: 300 } }).map((f) => f.problem)).toContain("the slip's value equals the right answer");
});

test("a number line's caption names the landing and the jumps as drawn", () => {
  const drawn = { kind: "number_line" as const, from: 0, to: 20, step: 1, start: 3, jumps: [5] };
  expect(numberLineCaptionFindings(drawn, "Start at 3 and take 5 jumps to land on 8.").map((f) => f.problem)).toEqual(["the caption says 5 jumps; the figure draws 1"]);
  expect(numberLineCaptionFindings(drawn, "Start at 3 and jump 5 to land on 8.")).toEqual([]);
  expect(numberLineCaptionFindings(drawn, "Start at 3 and jump 5 to land on 9.").map((f) => f.problem)).toEqual(["the caption does not name the landing, 8"]);
  expect(numberLineCaptionFindings({ ...drawn, jumps: [2, 2, 2] }, "Three jumps of 2 from 3 land on nine.")).toEqual([]);
  const input = { figure: "number_line" as const, classLevel: "3" as const, subject: "Mathematics", skill: "Add on a number line" };
  expect(figure.verify?.(input, { figure: drawn, caption: "Start at 3 and jump 5 to land on 9." }).map((f) => f.item)).toEqual(["caption"]);
});

test("a placement question asks one thing", () => {
  expect(oneQuestionFindings([{ chapter: "Heat", question: "What measures temperature? And in what unit?", answer: "A thermometer, in degree Celsius" }]).map((f) => f.item)).toEqual(["Heat"]);
  expect(oneQuestionFindings([{ chapter: "Heat", question: "What do we measure temperature with?", answer: "A thermometer" }])).toEqual([]);
  // The evals' placement-5-maths: a title's own question mark, quoted, is not a second question.
  expect(oneQuestionFindings([{ chapter: "How Many Squares?", question: 'In "How Many Squares?", how do we find the area of a shape?', answer: "Count the unit squares" }])).toEqual([]);
  const input = { classLevel: "7" as const, subject: "Science", chapters: ["Heat"] };
  expect(placement.verify?.(input, { questions: [{ chapter: "Heat", question: "What measures temperature? And in what unit?", answer: "A thermometer" }] }).map((f) => f.item)).toEqual(["Heat"]);
});

test("the plan's chapter is one the syllabus lists, at the month's place in the year", () => {
  expect(chapterInSyllabus("8", "English", "Reported speech")).toEqual({ listed: false, count: expect.any(Number) });
  const light = chapterInSyllabus("8", "Science", "Light: Mirrors and Lenses");
  expect(light.listed).toBe(true);
  expect(chapterInSyllabus("8", "Science", "light")).toMatchObject({ listed: true });
  expect(chapterInSyllabus("8", "Maths", "Exploring forces")).toMatchObject({ listed: false });
  expect(chapterInSyllabus("8", "Maths", "Number Play")).toMatchObject({ listed: true, count: 14 });
  expect(plan.verify?.({ centreId: "x", classId: null, date: "2026-10-13", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }, { groups: [{ groupNo: 1, chapter: "Light: Mirrors and Lenses", skill: "s" }] }).map((f) => f.item)).toEqual(["group 1"]);
  expect(plan.verify?.({ centreId: "x", classId: null, date: "2026-10-13", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }, { groups: [{ groupNo: 1, chapter: "Exploring Forces", skill: "s" }] })).toEqual([]);
  expect(plan.verify?.({ centreId: "x", classId: null, date: "2026-10-13", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }, { groups: [{ groupNo: 1, chapter: "Chemical reactions", skill: "s" }] }).map((f) => f.item)).toEqual(["group 1"]);
  expect(plan.verify?.({ centreId: "x", classId: null, date: "2026-06-16", month: 6, groups: [{ groupNo: 1, classLevel: "5", subject: "EVS" }] }, { groups: [{ groupNo: 1, chapter: "Super Senses", skill: "s" }] })).toEqual([]);
});

test("a notice or a holiday carries no portions", () => {
  const input = { text: "PTM on Saturday 17 October, 9 am to 12 noon.", image: null, today: "2026-10-13", schools: [], classLevels: ["8" as const] };
  const item = { kind: "notice", title: "PTM", subject: null, date: "2026-10-17", endDate: null, classLevel: null, school: null, studentName: null, portions: "Saturday 9 am to 12 noon" } as const;
  expect(parseSchool.verify?.(input, { items: [item] }).map((f) => f.problem)).toEqual(["a notice has no portions"]);
  expect(parseSchool.verify?.(input, { items: [{ ...item, kind: "holiday" }] }).map((f) => f.problem)).toEqual(["a holiday has no portions"]);
  expect(parseSchool.verify?.(input, { items: [{ ...item, portions: null }] })).toEqual([]);
});
