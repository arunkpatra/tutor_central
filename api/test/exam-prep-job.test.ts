import { expect, test } from "bun:test";
import { fakeClaude, localAnswer } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { type ExamRead, type ExamSource, examPrep } from "../src/jobs/kinds/exam-prep.js";
import type { Job, StepContext, StepOutcome } from "../src/jobs/types.js";
import type { MockOutput } from "../src/schemas.js";

// Exam preparation as one job (D106): the split written on the item, a wait to the mock day's morning, the mock made
// once by its key, then each quarter hour a gap report for each student newly marked (kept used) and today's open plan
// asked again; done on the exam day. A tutor's Try again (a wake) retries a mock that was not made.
const CENTRE = "c0000000-0000-4000-8000-0000000000aa";
const ITEM = "item-1";
const DEV = "a0000000-0000-4000-8000-000000000001";
const MEHER = "a0000000-0000-4000-8000-000000000002";
const BATCH = "batch-1";

const ist = (day: string, time = "10:00") => Date.parse(`${day}T${time}:00+05:30`);
const mockContent: MockOutput = {
  title: "Science unit test 3",
  durationMinutes: 40,
  sections: [{ name: "Section A", marksEach: 1, questions: [1, 2, 3, 4].map((n) => ({ number: n, text: "q", marks: 1, answer: "a", skill: n <= 2 ? "Balance a chemical equation" : "Types of reactions", proof: null })) }],
};

function read(over: Partial<ExamRead> = {}): ExamRead {
  return {
    item: { id: ITEM, kind: "exam", audience: { school: "s1", classLevel: "8" }, title: "Science unit test 3", subject: "Science", date: "2026-10-16", portions: "Chemical reactions", receivedAt: "2026-10-05T10:00:00+05:30" },
    students: [
      { id: DEV, name: "Dev Kumar", classLevel: "8", schoolID: "s1", classId: BATCH },
      { id: MEHER, name: "Meher Shah", classLevel: "8", schoolID: "s1", classId: BATCH },
    ],
    batches: [{ classId: BATCH, meetingDays: [1, 2, 3, 4, 5], openPlanToday: true }],
    chapters: { [DEV]: [{ id: "ch1", subject: "Science", position: 1, name: "Chemical reactions" }] },
    skills: { [DEV]: [{ id: "sk1", chapterID: "ch1", position: 1, name: "Balance a chemical equation", state: "taught", stateAt: "2026-10-01T10:00:00Z" }] },
    holidays: [],
    mock: null,
    marks: [],
    reports: [],
    ...over,
  };
}

function source(r: () => ExamRead) {
  const kept: { kind: string; student?: string; key: string; content: Record<string, unknown> }[] = [];
  const preparation: unknown[][] = [];
  const planReplaced: { classId: string; date: string }[] = [];
  const s: ExamSource & { kept: typeof kept; preparation: unknown[][]; planReplaced: typeof planReplaced } = {
    kept,
    preparation,
    planReplaced,
    async read() {
      return r();
    },
    async writePreparation(_centre, _item, days) {
      preparation.push(days);
    },
    async keep(_centre, artefact, place, key) {
      if (!kept.some((k) => k.key === key)) kept.push({ kind: artefact.kind, student: place.student, key, content: artefact.content });
      return `art-${kept.length}`;
    },
    async replacePlan(_centre, classId, date) {
      planReplaced.push({ classId, date });
    },
  };
  return s;
}

function harness(now: number, r: () => ExamRead) {
  const clock = fakeClock(now);
  const db = fakeDb();
  const ctx: StepContext = { db, jobs: fakeJobsDb(clock), claude: fakeClaude((q) => ({ answer: localAnswer(q) })), clock, requestId: "r", worker: "w" };
  const s = source(r);
  return { ctx, db, s, handler: examPrep(s) };
}
const job = (step: Record<string, unknown> = {}): Job => ({ id: "job-1", centreId: CENTRE, kind: "exam_prep", attempts: 1, step, input: { item_id: ITEM }, leaseUntil: "" });

test("split writes the days on the item, then waits for the mock day's morning", async () => {
  const { ctx, s, handler } = harness(ist("2026-10-07"), () => read());
  const one = await handler.step(job(), ctx);
  expect(one).toMatchObject({ kind: "continue", name: "split" });
  const days = s.preparation[0] as { day: string; kind: string }[];
  expect(days.map((d) => d.kind)).toContain("mock");
  expect(days.at(-1)).toMatchObject({ day: "2026-10-16", kind: "exam" });
  expect(Object.keys(days[0] as object).sort()).toEqual(["day", "index", "kind", "skill_ids", "skills", "title"]);
  const two = await handler.step(job((one as Extract<StepOutcome, { kind: "continue" }>).step), ctx);
  expect(two).toMatchObject({ kind: "wait", name: "wait" });
  expect((two as Extract<StepOutcome, { kind: "wait" }>).runAt.toISOString()).toBe("2026-10-13T23:30:00.000Z");
});

test("on the mock day the mock is made once by its key, kept with the exam, and the job waits for marks", async () => {
  const { ctx, db, s, handler } = harness(ist("2026-10-14", "05:01"), () => read());
  const out = await handler.step(job({ at: "mock", mockDay: "2026-10-14" }), ctx);
  expect(out).toMatchObject({ kind: "wait", name: "mock", step: { at: "marks" } });
  expect(db.rows.map((r) => r.key)).toEqual([`mock:${ITEM}`, `mock:${ITEM}:check`]);
  expect(s.kept.map((k) => [k.kind, k.key])).toEqual([["mock", `mock:${ITEM}`]]);
  expect(s.kept[0]?.content).toMatchObject({ school_item_id: ITEM, title: "Science unit test 3" });
});

test("a mock kept already (the plan's) is not made again", async () => {
  const { ctx, db, handler } = harness(ist("2026-10-14", "05:01"), () => read({ mock: { id: "m1", content: mockContent } }));
  const out = await handler.step(job({ at: "mock", mockDay: "2026-10-14" }), ctx);
  expect(out).toMatchObject({ kind: "wait", name: "mock" });
  expect(db.rows).toHaveLength(0);
});

test("a saved mark makes that student's gap report, kept used, and asks today's open plan again; a second tick makes no second", async () => {
  let r = read({ mock: { id: "m1", content: mockContent }, marks: [{ student: DEV, questions: [{ number: 1, marks: 0, note: "Changed a subscript" }, { number: 2, marks: 1 }, { number: 3, marks: 1 }, { number: 4, marks: 1 }] }] });
  const { ctx, s, handler } = harness(ist("2026-10-14", "20:00"), () => r);
  const out = await handler.step(job({ at: "marks" }), ctx);
  expect(out).toMatchObject({ kind: "wait", name: "marks" });
  expect(s.kept.map((k) => [k.kind, k.student, k.key])).toEqual([["gap_report", DEV, `gap:${ITEM}:${DEV}`]]);
  expect(s.kept[0]?.content).toMatchObject({ school_item_id: ITEM, score: 3, max: 4, by_skill: [{ skill: "Balance a chemical equation", right: 1, of: 2, note: "Changed a subscript" }, { skill: "Types of reactions", right: 2, of: 2 }] });
  expect(typeof s.kept[0]?.content.used_at).toBe("string");
  expect((s.kept[0]?.content.days as unknown[]).length).toBe(2);
  expect(s.planReplaced).toEqual([{ classId: BATCH, date: "2026-10-14" }]);
  r = { ...r, reports: [DEV] };
  await handler.step(job({ at: "marks" }), ctx);
  expect(s.kept).toHaveLength(1);
});

test("a closed plan today is not asked again: the next morning's plan reads the report", async () => {
  const r = read({ batches: [{ classId: BATCH, meetingDays: [1, 2, 3, 4, 5], openPlanToday: false }], mock: { id: "m1", content: mockContent }, marks: [{ student: DEV, questions: [{ number: 1, marks: 1 }] }] });
  const { ctx, s, handler } = harness(ist("2026-10-14", "20:00"), () => r);
  await handler.step(job({ at: "marks" }), ctx);
  expect(s.kept).toHaveLength(1);
  expect(s.planReplaced).toEqual([]);
});

test("a mock not made waits for marks; a tutor's Try again (a wake) makes it", async () => {
  const { ctx, db, s, handler } = harness(ist("2026-10-14", "09:00"), () => read());
  const waiting = await handler.step(job({ at: "marks", mockFailed: true }), ctx);
  expect(waiting).toMatchObject({ kind: "wait", name: "marks" });
  expect(db.rows).toHaveLength(0);
  const woken = await handler.step(job({ at: "marks", mockFailed: true, woken: true }), ctx);
  expect(woken).toMatchObject({ kind: "wait", name: "mock", step: { at: "marks" } });
  expect(s.kept.map((k) => k.kind)).toEqual(["mock"]);
});

test("the job ends on the exam day", async () => {
  const { ctx, handler } = harness(ist("2026-10-16", "06:00"), () => read({ mock: { id: "m1", content: mockContent } }));
  expect(await handler.step(job({ at: "marks" }), ctx)).toMatchObject({ kind: "done", result: { item_id: ITEM, mock: true, reports: 0 } });
});

test("an exam gone, or past, ends the job at its first step", async () => {
  const gone = harness(ist("2026-10-07"), () => null as unknown as ExamRead);
  expect(await gone.handler.step(job(), gone.ctx)).toMatchObject({ kind: "done", result: { item_id: ITEM, reason: "gone" } });
  const past = harness(ist("2026-10-17"), () => read());
  expect(await past.handler.step(job(), past.ctx)).toMatchObject({ kind: "done", result: { reason: "past" } });
});
