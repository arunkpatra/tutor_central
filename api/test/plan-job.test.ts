import { expect, test } from "bun:test";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { type PlanRead, type PlanRecordSource, planJob } from "../src/jobs/kinds/plan.js";
import type { Job, StepContext, StepOutcome } from "../src/jobs/types.js";

const CENTRE = "c0000000-0000-4000-8000-0000000000aa";
const CLASS = "c0000000-0000-4000-8000-000000000001";
const DEV = "a0000000-0000-4000-8000-000000000001";
const RIYA = "a0000000-0000-4000-8000-000000000002";

function read(over: Partial<PlanRead> = {}): PlanRead {
  return {
    classroom: { id: CLASS, subject: "Science", patterns: {} },
    members: [
      { id: DEV, name: "Dev", classLevel: "8", trackStatus: "on_track" },
      { id: RIYA, name: "Riya", classLevel: "5", trackStatus: "on_track" },
    ],
    chapters: {},
    skills: {},
    sessions: [],
    items: [],
    closed: false,
    existingPlan: null,
    briefChapters: [],
    ...over,
  };
}

/** A record source in memory: what it read, what it was asked to write. */
function source(r: PlanRead | (() => PlanRead)) {
  const made: unknown[] = [];
  const chapters: unknown[] = [];
  const skills: unknown[] = [];
  let reads = 0;
  const s: PlanRecordSource & { made: unknown[]; chapters: unknown[]; skills: unknown[]; reads: () => number } = {
    made,
    chapters,
    skills,
    reads: () => reads,
    async read() {
      reads += 1;
      return typeof r === "function" ? r() : r;
    },
    async existingPlan() {
      return (typeof r === "function" ? r() : r).existingPlan;
    },
    async addChapter(_centre, student, subject, name, skill) {
      chapters.push({ student, subject, name, skill });
      return `skill-of-${student}`;
    },
    async addSkill(_centre, chapter, student, name) {
      skills.push({ chapter, student, name });
      return `added-${student}`;
    },
    async makePlan(_centre, draft) {
      made.push(draft);
      return "plan-1";
    },
  };
  return s;
}

const job = (step: Record<string, unknown> = {}): Job => ({ id: "job-1", centreId: CENTRE, kind: "plan", attempts: 1, step, input: { class_id: CLASS, date: "2026-10-07" }, leaseUntil: "" });
const ctx = (db = fakeDb(), claude = fakeClaude({ answer: { groups: [{ groupNo: 1, chapter: "Crop production", skill: "Kinds of crops" }, { groupNo: 2, chapter: "Plants", skill: "Parts of a plant" }] } })): StepContext => {
  const clock = fakeClock();
  return { db, jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" };
};
async function walk(handler: ReturnType<typeof planJob>, c: StepContext, start: Record<string, unknown> = {}) {
  const seen: StepOutcome[] = [];
  let current = job(start);
  for (let i = 0; i < 6; i++) {
    const outcome = await handler.step(current, c);
    seen.push(outcome);
    if (outcome.kind !== "continue") break;
    current = { ...current, step: outcome.step };
  }
  return seen;
}

test("read gathers the batch and continues to groups", async () => {
  const s = source(read());
  const outcome = await planJob(s).step(job(), ctx());
  expect(outcome).toMatchObject({ kind: "continue", name: "read", step: { at: "groups" } });
  expect(s.reads()).toBe(1);
});

test("a batch with no active member, a closed session, or a plan already made is done with no write", async () => {
  expect(await planJob(source(read({ members: [] }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: null, reason: "no_members" } });
  expect(await planJob(source(read({ closed: true }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: null, reason: "closed" } });
  expect(await planJob(source(read({ existingPlan: "plan-0" }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: "plan-0", reason: "made" } });
});

test("an exam or a holiday that reaches a member leaves the day to the phone (exam mode is Phase 18's)", async () => {
  const exam = { kind: "exam", studentId: DEV, date: "2026-10-12", subject: "Science", title: "Science test" } as const;
  expect(await planJob(source(read({ items: [exam] }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: null, reason: "exam_mode" } });
  const holiday = { kind: "holiday", studentId: RIYA, date: "2026-10-06", endDate: "2026-10-08", title: "Diwali" } as const;
  expect(await planJob(source(read({ items: [holiday] }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { reason: "exam_mode" } });
  const far = { ...exam, date: "2026-11-30" };
  expect(await planJob(source(read({ items: [far] }))).step(job(), ctx())).toMatchObject({ kind: "continue" });
});

test("groups applies the rules and continues to name", async () => {
  const outcome = await planJob(source(read())).step(job({ at: "groups", record: read() }), ctx());
  expect(outcome).toMatchObject({ kind: "continue", name: "groups", step: { at: "name" } });
  const draft = (outcome as unknown as { step: { draft: { groups: { skill: string }[] } } }).step.draft;
  expect(draft.groups.map((g) => g.skill)).toEqual(["", ""]);
});

test("name calls plan once through start_ai_call with the key <job>:name and the job, writes the named skills, then continues to write", async () => {
  const db = fakeDb();
  const s = source(read());
  const steps = await walk(planJob(s), ctx(db));
  expect(steps.map((o) => [o.name, o.kind])).toEqual([["read", "continue"], ["groups", "continue"], ["name", "continue"], ["write", "done"]]);
  expect(db.started).toHaveLength(1);
  expect(db.started[0]).toMatchObject({ centre: CENTRE, kind: "plan", key: "job-1:name", job: "job-1", requestId: "r1" });
  expect((db.started[0] as { input: { month: number; groups: unknown[] } }).input).toMatchObject({ month: 10, classId: CLASS, date: "2026-10-07" });
  expect(db.finished[0]).toMatchObject({ status: "ok", costPaise: 138 });
  expect(steps[2]).toMatchObject({ generationId: "gen-1", costPaise: 138 });
  expect(s.chapters).toHaveLength(2);
  const plan = s.made[0] as { groups: { chapter: string; skill: string }[]; lines: { studentID?: string; kind: string; skillID?: string; words: string }[] };
  expect(plan.groups.map((g) => g.skill)).toEqual(["Kinds of crops", "Parts of a plant"]);
  expect(plan.lines.find((l) => l.studentID === DEV && l.kind === "teach")).toMatchObject({ words: "Teach: Kinds of crops", skillID: `skill-of-${DEV}` });
  expect(steps[3]).toMatchObject({ kind: "done", result: { plan_id: "plan-1" } });
});

test("a failed naming still writes the plan with the groups unnamed", async () => {
  const s = source(read());
  const steps = await walk(planJob(s), ctx(fakeDb(), fakeClaude({ fail: "timeout" })));
  expect(steps.at(-1)).toMatchObject({ kind: "done", result: { plan_id: "plan-1" } });
  const plan = s.made[0] as { groups: { skill: string }[] };
  expect(plan.groups.map((g) => g.skill)).toEqual(["", ""]);
  expect(s.chapters).toEqual([]);
});

test("a naming key still in progress waits thirty seconds at the same step", async () => {
  const db = fakeDb({ replays: { "job-1:name": { id: "gen-old", status: "pending", output: null } } });
  const c = ctx(db);
  const groups = await planJob(source(read())).step(job({ at: "groups", record: read() }), c);
  const outcome = await planJob(source(read())).step(job((groups as { step: Record<string, unknown> }).step), c);
  expect(outcome).toMatchObject({ kind: "wait", name: "name", step: { at: "name" } });
  expect((outcome as { runAt: Date }).runAt.getTime() - c.clock.now()).toBe(30_000);
});

test("a finished naming key replays: no second call, the named draft", async () => {
  const output = JSON.stringify({ groups: [{ groupNo: 1, chapter: "Crop production", skill: "Kinds of crops" }] });
  const claude = fakeClaude({ answer: {} });
  const db = fakeDb({ replays: { "job-1:name": { id: "gen-old", status: "ok", output } } });
  const s = source(read());
  const steps = await walk(planJob(s), ctx(db, claude), { at: "groups", record: read() });
  expect(claude.requests).toHaveLength(0);
  expect((s.made[0] as { groups: { skill: string }[] }).groups[0]?.skill).toBe("Kinds of crops");
  expect(steps.find((o) => o.name === "name")).toMatchObject({ generationId: "gen-old" });
});

test("write never replaces a plan the phone made meanwhile", async () => {
  let existing: string | null = null;
  const s = source(() => read({ existingPlan: existing }));
  const steps = await walk(planJob(s), ctx(), { at: "groups", record: read() });
  expect(steps.at(-1)).toMatchObject({ result: { plan_id: "plan-1" } });
  existing = "plan-phone";
  const again = await walk(planJob(s), ctx(), { at: "groups", record: read() });
  expect(again.at(-1)).toMatchObject({ kind: "done", result: { plan_id: "plan-phone", reason: "made" } });
  expect(s.made).toHaveLength(1);
});

test("a read that throws fails with a retry", async () => {
  const s = source(read());
  s.read = async () => {
    throw new Error("down");
  };
  expect(await planJob(s).step(job(), ctx())).toMatchObject({ kind: "fail", name: "read", error: { reason: "read_failed" }, retry: true });
});

test("a job without a class or a day fails without a retry", async () => {
  const bad = { ...job(), input: {} };
  expect(await planJob(source(read())).step(bad, ctx())).toMatchObject({ kind: "fail", error: { reason: "input" }, retry: false });
});

test("a member with no chapter in a group the record named gets the group's chapter and skill", async () => {
  const chapter = { id: "b0000000-0000-4000-8000-000000000001", subject: "Science", position: 1, name: "Crops" };
  const skill = { id: "d0000000-0000-4000-8000-000000000001", chapterID: chapter.id, position: 1, name: "Kinds of crops", state: "practising" as const, stateAt: "2026-10-06T11:30:00Z" };
  const both = read({
    members: [
      { id: DEV, name: "Dev", classLevel: "8", trackStatus: "on_track" },
      { id: RIYA, name: "Riya", classLevel: "8", trackStatus: "on_track" },
    ],
    chapters: { [DEV]: [chapter] },
    skills: { [DEV]: [skill] },
  });
  const db = fakeDb();
  const s = source(both);
  await walk(planJob(s), ctx(db), { at: "groups", record: both });
  expect(db.started).toEqual([]);
  expect(s.chapters).toEqual([{ student: RIYA, subject: "Science", name: "Crops", skill: "Kinds of crops" }]);
});

test("every table the record source reaches is reached for the job's centre alone (D83)", async () => {
  const source = await Bun.file(new URL("../src/jobs/record.ts", import.meta.url)).text();
  const reaches = [...source.matchAll(/\.from\("(\w+)"\)/g)];
  expect(reaches.length).toBeGreaterThan(0);
  for (const match of reaches) {
    const chain = source.slice(match.index, source.indexOf(";", match.index));
    expect({ table: match[1], centre: chain.includes("centre_id") }).toEqual({ table: match[1], centre: true });
  }
});

test("make_plan's parameters are the app's: the groups by PlanGroup's keys, items with their ids only when set", async () => {
  const { planParams } = await import("../src/jobs/record.js");
  const params = planParams(CENTRE, {
    classID: CLASS,
    date: "2026-10-07",
    groups: [{ number: 1, subject: "Science", chapter: "", skill: "", classLevels: ["8"], memberIDs: [DEV], skillID: undefined, examItemID: undefined }],
    lines: [
      { studentID: DEV, groupNo: 1, kind: "teach", skillID: undefined, words: "Teach: with the group", personalChecks: false },
      { studentID: undefined, groupNo: 1, kind: "brief", skillID: undefined, words: "Your brief", personalChecks: false },
    ],
    leftOut: [],
    personalCheckSkills: {},
  });
  expect(params).toEqual({
    p_centre: CENTRE,
    p_class: CLASS,
    p_date: "2026-10-07",
    p_groups: [{ number: 1, subject: "Science", chapter: "", skill: "", classLevels: ["8"], memberIDs: [DEV] }],
    p_subjects: { "1": "Science" },
    p_items: [
      { group_no: 1, kind: "teach", words: "Teach: with the group", student_id: DEV },
      { group_no: 1, kind: "brief", words: "Your brief" },
    ],
  });
});

test("the sessions read are last month's and this month's", async () => {
  const { sessionSpan } = await import("../src/jobs/record.js");
  expect(sessionSpan("2026-10-07")).toEqual({ from: "2026-09-01", to: "2026-10-31" });
  expect(sessionSpan("2026-01-15")).toEqual({ from: "2025-12-01", to: "2026-01-31" });
});
