import { expect, test } from "bun:test";
import { fakeClaude, kindOf, SAMPLE, isCheckRequest, localAnswer, PASS } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { installModelTable } from "../src/models.js";
import { fakeModelSource } from "../src/models-db.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { type PlanRead, type PlanRecordSource, planJob } from "../src/jobs/kinds/plan.js";
import type { Job, StepContext, StepOutcome } from "../src/jobs/types.js";
import type { Skill } from "../src/plan/types.js";
import { costPaise } from "../src/price.js";

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

type Kept = { id: string; kind: string; key: string; title: string; content: Record<string, unknown>; plan: string; groupNo: number; student?: string; itemKind: string; schoolItem?: string };
/** A record source in memory: what it read, what it was asked to write, keep, link and queue. A keep by a key already
 *  kept answers the first artefact and links the plan's lines again (keep_artefact). */
function source(r: PlanRead | (() => PlanRead), options: { failKeepOnce?: boolean; users?: { user: string; planReady: boolean; notesReady: boolean }[] } = {}) {
  const made: unknown[] = [];
  const chapters: unknown[] = [];
  const skills: unknown[] = [];
  const kept: Kept[] = [];
  const links: { plan: string; groupNo: number; itemKind: string; artefact: string }[] = [];
  const notified: { user: string; key: string; kind: string; title?: string; body?: string; background?: boolean }[] = [];
  let reads = 0;
  let failKeep = options.failKeepOnce ?? false;
  let plans = 0;
  const s: PlanRecordSource & {
    made: unknown[];
    chapters: unknown[];
    skills: unknown[];
    kept: Kept[];
    keeps: number;
    links: typeof links;
    notified: typeof notified;
    reads: () => number;
  } = {
    made,
    chapters,
    skills,
    kept,
    keeps: 0,
    links,
    notified,
    reads: () => reads,
    async keep(_centre, artefact, place, key) {
      if (failKeep) {
        failKeep = false;
        throw new Error("the keep did not reach the database");
      }
      s.keeps += 1;
      const found = kept.find((k) => k.key === key);
      if (found) {
        links.push({ plan: place.plan, groupNo: place.groupNo, itemKind: place.itemKind, artefact: found.id });
        return found.id;
      }
      const row = { id: `art-${kept.length + 1}`, kind: artefact.kind, key, title: artefact.title, content: artefact.content, ...place };
      kept.push(row);
      links.push({ plan: place.plan, groupNo: place.groupNo, itemKind: place.itemKind, artefact: row.id });
      return row.id;
    },
    async link(_centre, plan, groupNo, itemKind, artefact) {
      links.push({ plan, groupNo, itemKind, artefact });
    },
    async mockFor(_centre, item) {
      return kept.find((k) => k.kind === "mock" && k.schoolItem === item)?.id ?? null;
    },
    async pushUsers() {
      return options.users ?? [{ user: "u1", planReady: true, notesReady: true }];
    },
    async notify(_centre, user, rows) {
      for (const row of rows) notified.push({ user, key: row.key, kind: row.kind, title: row.title, body: row.body, background: row.background });
    },
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
      plans += 1;
      return (draft as { classID: string }).classID === CLASS ? "plan-1" : "plan-2";
    },
  };
  return s;
}

const job = (step: Record<string, unknown> = {}): Job => ({ id: "job-1", centreId: CENTRE, kind: "plan", attempts: 1, step, input: { class_id: CLASS, date: "2026-10-07" }, leaseUntil: "" });
const ctx = (db = fakeDb(), claude = fakeClaude({ answer: { groups: [{ groupNo: 1, chapter: "Exploring Forces", skill: "Tell a push from a pull" }, { groupNo: 2, chapter: "Plants", skill: "Parts of a plant" }] } })): StepContext => {
  // 00:05 in India on 7 October, when schedule_plans queues the day's jobs (D108).
  const clock = fakeClock(Date.parse("2026-10-06T18:35:00Z"));
  return { db, jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" };
};
async function walk(handler: ReturnType<typeof planJob>, c: StepContext, start: Record<string, unknown> = {}) {
  const seen: StepOutcome[] = [];
  let current = job(start);
  for (let i = 0; i < 40; i++) {
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

test("a batch that no longer meets on the day (its days changed after the job was queued) is done with no write and no call (the review's R-db-7)", async () => {
  const s = source(taught({ classroom: { id: CLASS, subject: "Science", patterns: {}, name: "Evening batch", meetingDays: [2, 4], start: "17:00:00", end: "18:30:00" } }));
  expect(await planJob(s).step(job(), ctx())).toMatchObject({ kind: "done", name: "read", result: { plan_id: null, reason: "not_meeting" } });
});

test("a batch with no active member, a closed session, or a plan already made is done with no write", async () => {
  expect(await planJob(source(read({ members: [] }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: null, reason: "no_members" } });
  expect(await planJob(source(read({ closed: true }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: null, reason: "closed" } });
  expect(await planJob(source(read({ existingPlan: { id: "plan-0", closed: false } }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: "plan-0", reason: "made" } });
  expect(await planJob(source(read({ existingPlan: { id: "plan-0", closed: true } }))).step(job(), ctx())).toMatchObject({ kind: "done", result: { plan_id: "plan-0", reason: "closed" } });
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
  expect(steps.slice(0, 4).map((o) => [o.name, o.kind])).toEqual([["read", "continue"], ["groups", "continue"], ["name", "continue"], ["write", "continue"]]);
  expect(db.rows.filter((r) => r.kind === "plan").map((r) => [r.agentStep, r.key])).toEqual([["draft", "job-1:name"], ["check", "job-1:name:check"]]);
  expect(db.started[0]).toMatchObject({ centre: CENTRE, kind: "plan", key: "job-1:name", job: "job-1", requestId: "r1" });
  expect((db.started[0] as { input: { month: number; groups: unknown[] } }).input).toMatchObject({ month: 10, classId: CLASS, date: "2026-10-07" });
  expect(db.rows[0]?.finish).toMatchObject({ status: "ok", costPaise: 138 });
  // The step's cost is every row's: the draft's and its check's.
  expect(steps[2]).toMatchObject({ generationId: "gen-1", costPaise: 138 + (db.rows[1]?.finish?.costPaise ?? 0) });
  expect(s.chapters).toHaveLength(2);
  const plan = s.made[0] as { groups: { chapter: string; skill: string }[]; lines: { studentID?: string; kind: string; skillID?: string; words: string }[] };
  expect(plan.groups.map((g) => g.skill)).toEqual(["Tell a push from a pull", "Parts of a plant"]);
  expect(plan.lines.find((l) => l.studentID === DEV && l.kind === "teach")).toMatchObject({ words: "Teach: Tell a push from a pull", skillID: `skill-of-${DEV}` });
  expect(steps.at(-1)).toMatchObject({ kind: "done", result: { plan_id: "plan-1" } });
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
  const output = JSON.stringify({ groups: [{ groupNo: 1, chapter: "Exploring Forces", skill: "Tell a push from a pull" }] });
  const claude = fakeClaude({ answer: {} });
  const db = fakeDb({ replays: { "job-1:name": { id: "gen-old", status: "ok", output } } });
  const s = source(read());
  const steps = await walk(planJob(s), ctx(db, claude), { at: "groups", record: read() });
  expect(kinds(claude).filter((k) => k === "plan")).toHaveLength(0);
  expect((s.made[0] as { groups: { skill: string }[] }).groups[0]?.skill).toBe("Tell a push from a pull");
  expect(steps.find((o) => o.name === "name")).toMatchObject({ generationId: "gen-old" });
});

test("write never replaces a plan the phone made meanwhile", async () => {
  let existing: { id: string; closed: boolean } | null = null;
  const s = source(() => read({ existingPlan: existing }));
  const steps = await walk(planJob(s), ctx(), { at: "groups", record: read() });
  expect(steps.at(-1)).toMatchObject({ result: { plan_id: "plan-1" } });
  existing = { id: "plan-phone", closed: false };
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
  expect(db.started.filter((c) => (c as { kind: string }).kind === "plan")).toEqual([]);
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

// ---- Phase 18: the material, exam weeks and holidays, replacing, Plan ready (plan/phase-18-plan.md Task 12) ----

const CLASS2 = "c0000000-0000-4000-8000-000000000002";
const SCHOOL = "f0000000-0000-4000-8000-000000000001";
/** Two chapters of two skills in Science, the first chapter practising (taught 6 and 5 October). */
function book(prefix: string) {
  const chapters = [1, 2].map((p) => ({ id: `b${prefix}000000-0000-4000-8000-00000000000${p}`, subject: "Science", position: p, name: `Chapter ${p}` }));
  const skills = chapters.flatMap((c, i) =>
    [1, 2].map((p) => ({
      id: `d${prefix}${i}${p}0000-0000-4000-8000-000000000001`,
      chapterID: c.id,
      position: p,
      name: `Science ${i + 1}.${p}`,
      state: (i === 0 ? "practising" : "not_started") as Skill["state"],
      stateAt: `2026-10-0${6 - p}T11:30:00Z`,
    })),
  );
  return { chapters, skills };
}
/** Dev and Riya at class 6 with their books: one named group, no brief, no figure. */
function taught(over: Partial<PlanRead> = {}): PlanRead {
  const dev = book("1");
  const riya = book("2");
  return read({
    classroom: { id: CLASS, subject: "Science", patterns: {}, name: "Evening batch", meetingDays: [1, 3, 5], start: "17:00:00", end: "18:30:00" },
    members: [
      { id: DEV, name: "Dev", classLevel: "6", trackStatus: "on_track", schoolId: SCHOOL },
      { id: RIYA, name: "Riya", classLevel: "6", trackStatus: "on_track", schoolId: SCHOOL },
    ],
    chapters: { [DEV]: dev.chapters, [RIYA]: riya.chapters },
    skills: { [DEV]: dev.skills, [RIYA]: riya.skills },
    ...over,
  });
}
const answers = (over: Partial<Record<string, unknown>> = {}) => fakeClaude((r) => ({ answer: isCheckRequest(r) ? PASS : (over[kindOf(r)] ?? localAnswer(r)) }));
const planJobFor = (classId = CLASS, date = "2026-10-07", extra: Record<string, unknown> = {}): Job => ({ ...job(), input: { class_id: classId, date, ...extra } });

/** Every step of a job to its end, a wait taken again at once (the worker's later claim). */
async function drainAll(handler: ReturnType<typeof planJob>, start: Job, c: StepContext) {
  const seen: StepOutcome[] = [];
  let current = start;
  for (let i = 0; i < 80; i++) {
    let outcome: StepOutcome;
    try {
      outcome = await handler.step(current, c);
    } catch (e) {
      throw e;
    }
    seen.push(outcome);
    if (outcome.kind === "continue") current = { ...current, step: outcome.step };
    else if (outcome.kind === "wait") current = { ...current, step: outcome.step };
    else if (outcome.kind === "fail" && outcome.retry) continue;
    else break;
    await Promise.resolve();
  }
  return seen;
}
/** A gate that remembers its keys, as start_ai_call does: a finished key replays its answer, a running one is pending. */
function rememberingDb() {
  const base = fakeDb();
  const byKey = new Map<string, { id: string; status: "pending" | "ok"; output: string | null }>();
  const keyOf = new Map<string, string>();
  return {
    ...base,
    started: base.started,
    finished: base.finished,
    async startCall(token: string, args: Parameters<typeof base.startCall>[1]) {
      const prior = args.key ? byKey.get(args.key) : undefined;
      if (prior) return { ...prior, replay: true };
      // Held before any await, as the gate's advisory lock holds a centre's calls in turn.
      const held = { id: "", status: "pending" as const, output: null };
      if (args.key) byKey.set(args.key, held);
      const s = await base.startCall(token, args);
      if (args.key) {
        held.id = s.id;
        keyOf.set(s.id, args.key);
      }
      return s;
    },
    async finish(token: string, id: string, result: Parameters<typeof base.finish>[2]) {
      await base.finish(token, id, result);
      const key = keyOf.get(id);
      if (!key) return;
      if (result.status === "ok") byKey.set(key, { id, status: "ok", output: result.output });
      else byKey.delete(key);
    },
  };
}
/** The kinds of the drafts asked (an agent's checks left out). */
const kinds = (claude: { requests: { text: string }[] }) =>
  (claude as unknown as { requests: Parameters<typeof kindOf>[0][] }).requests.filter((r) => !isCheckRequest(r)).map(kindOf);

test("after the write, the budget's drafts go as one batch and their checks as a second, each kept by its key; the job ends by notifying (D108)", async () => {
  const s = source(taught());
  const claude = answers();
  const out = await drainAll(planJob(s), planJobFor(), ctx(fakeDb(), claude));
  expect(out.map((o) => o.name)).toEqual(["read", "groups", "name", "write", "budget", "make:submit", "make:wait", "make:wait", "make:keep:0", "make:keep:1", "make:keep:2", "make:keep:3", "notify"]);
  expect(claude.batches.map((b) => b.map((i) => i.customId))).toEqual([
    ["make_0", "make_1", "make_2", "make_3"],
    ["make_0__check", "make_1__check", "make_2__check", "make_3__check"],
  ]);
  expect(s.kept.map((k) => [k.kind, k.key, k.itemKind])).toEqual([
    ["check", "job-1:make:0", "check"],
    ["sheet", "job-1:make:1", "practise"],
    ["sheet", "job-1:make:2", "homework"],
    ["worked_example", "job-1:make:3", "worked_example"],
  ]);
  expect(s.kept.every((k) => k.plan === "plan-1" && k.groupNo === 1 && k.student === undefined)).toBe(true);
  // The job's id in the keys: a plan made again after Plan ready was sent pushes again (the outbox rewrites no sent row,
  // the review's R-db-4); a retaken notify step of the same job writes the same rows.
  expect(s.notified.map((n) => n.key)).toEqual([`plan_ready:${CLASS}:2026-10-07:job-1`, `plan_fetch:${CLASS}:2026-10-07:job-1`]);
  expect(s.notified[0]).toMatchObject({ title: "Evening batch: today’s plan is ready", body: "17:00–18:30 · 1 group. Tap to see it." });
  expect(s.notified[1]).toMatchObject({ kind: "plan_fetch", background: true });
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { plan_id: "plan-1", made: 4, not_made: 0 } });
});

test("the material is kept in the app's shape: snake-case keys, the check's skill rows, the sheet's set or homework", async () => {
  const s = source(taught());
  await drainAll(planJob(s), planJobFor(), ctx(fakeDb(), answers()));
  const check = s.kept[0] as Kept;
  const rows = (check.content as { questions: { skill_id: string; skill: string }[] }).questions;
  expect(rows.every((q) => typeof q.skill_id === "string" && q.skill_id.length === 36)).toBe(true);
  expect(check.title).toBe("Checks · Science 1.1");
  expect(s.kept[1]).toMatchObject({ title: "Science 1.1 · set 1", content: { for_homework: false, light: false } });
  expect(s.kept[2]).toMatchObject({ title: "Science 1.1 · sheet 1", content: { for_homework: true, light: false } });
  expect(Object.keys(s.kept[3]?.content ?? {}).sort()).toEqual(["problem", "proof", "slip", "slip_proof", "steps"]);
});

test("a material step retaken after its call keeps once and pays once", async () => {
  const claude = answers();
  const s = source(taught(), { failKeepOnce: true });
  const out = await drainAll(planJob(s), planJobFor(), ctx(rememberingDb() as never, claude));
  expect(out.find((o) => o.name === "make:keep:0" && o.kind === "fail")).toMatchObject({ retry: true });
  expect(kinds(claude).filter((k) => k === "check")).toHaveLength(1);
  expect(s.kept.filter((k) => k.kind === "check")).toHaveLength(1);
});

test("a failed call leaves its mark not made and the job goes on", async () => {
  const claude = fakeClaude((r) => (!isCheckRequest(r) && kindOf(r) === "sheet" ? { fail: "timeout" } : { answer: localAnswer(r) }));
  const s = source(taught());
  const out = await drainAll(planJob(s), planJobFor(), ctx(fakeDb(), claude));
  expect(s.kept.map((k) => k.kind)).toEqual(["check", "worked_example"]);
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { made: 2, not_made: 2 } });
});

/** The Science unit test on Friday 6 November, come on 23 October, for class 8 at the school; the batch meets Mon, Wed, Fri. */
const unitTest = { id: "e0000000-0000-4000-8000-000000000301", kind: "exam" as const, audience: { school: SCHOOL, classLevel: "8" }, title: "Science unit test", subject: "Science", date: "2026-11-06", portions: "Chapter 1 · Chapter 2", receivedAt: "2026-10-23T10:00:00+05:30" };
function examBatch(classId: string, over: Partial<PlanRead> = {}): PlanRead {
  const r = taught(over);
  return {
    ...r,
    classroom: { ...r.classroom, id: classId },
    members: r.members.map((m) => ({ ...m, classLevel: "8" as const })),
    items: [unitTest],
    ...over,
  };
}
/** A mock whose marks are the class 8 pattern's 40 (the sample's are not). */
function mockOf40() {
  const sample = SAMPLE.mock as { sections: { questions: { marks: number }[] }[] };
  const sum = sample.sections.flatMap((x) => x.questions).reduce((n, q) => n + q.marks, 0);
  const copy = JSON.parse(JSON.stringify(sample)) as typeof sample;
  (copy.sections[0]?.questions[0] as { marks: number }).marks += 40 - sum;
  return copy;
}

test("an exam week is planned on the server: revision lines, no exam_mode", async () => {
  const s = source(examBatch(CLASS));
  const out = await drainAll(planJob(s), planJobFor(CLASS, "2026-11-02"), ctx(fakeDb(), answers()));
  const draft = s.made[0] as { groups: { examItemID?: string }[]; lines: { kind: string; words: string }[] };
  expect(draft.groups[0]?.examItemID).toBe(unitTest.id);
  expect(draft.lines.find((l) => l.kind === "teach")?.words).toStartWith("Revise: ");
  expect(s.kept.map((k) => k.kind)).toEqual(["check", "sheet", "sheet"]);
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { plan_id: "plan-1" } });
});

test("two plan jobs on the mock day share one mock call and one artefact", async () => {
  const db = rememberingDb();
  const claude = answers({ mock: mockOf40() });
  const s = source(() => examBatch(CLASS));
  const s2: typeof s = Object.assign(Object.create(s), { read: async () => examBatch(CLASS2), existingPlan: async () => null });
  await Promise.all([
    drainAll(planJob(s), { ...planJobFor(CLASS, "2026-11-04"), id: "job-1" }, ctx(db as never, claude)),
    drainAll(planJob(s2), { ...planJobFor(CLASS2, "2026-11-04"), id: "job-2" }, ctx(db as never, claude)),
  ]);
  expect(kinds(claude).filter((k) => k === "mock")).toHaveLength(1);
  const mocks = s.kept.filter((k) => k.kind === "mock");
  expect(mocks).toHaveLength(1);
  expect(mocks[0]).toMatchObject({ key: `mock:${unitTest.id}`, schoolItem: unitTest.id, itemKind: "practise" });
  expect(new Set(s.links.filter((l) => l.artefact === mocks[0]?.id).map((l) => l.plan))).toEqual(new Set(["plan-1", "plan-2"]));
});

test("a mock made before (by the phone) is linked to the set lines, not made again", async () => {
  const claude = answers({ mock: mockOf40() });
  const s = source(examBatch(CLASS, { mocks: { [unitTest.id]: "art-phone" } }));
  await drainAll(planJob(s), planJobFor(CLASS, "2026-11-04"), ctx(fakeDb(), claude));
  expect(kinds(claude)).not.toContain("mock");
  expect(s.links).toContainEqual({ plan: "plan-1", groupNo: 1, itemKind: "practise", artefact: "art-phone" });
});

test("a holiday covering the whole batch ends the job done with reason holiday", async () => {
  const holiday = { id: "h1", kind: "holiday" as const, audience: { school: SCHOOL }, title: "Diwali", date: "2026-11-01", endDate: "2026-11-08", receivedAt: "2026-10-20T10:00:00+05:30" };
  const s = source(taught({ items: [holiday] }));
  const out = await drainAll(planJob(s), planJobFor(CLASS, "2026-11-04"), ctx(fakeDb(), answers()));
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { plan_id: null, reason: "holiday" } });
  expect(s.made).toEqual([]);
});

test("a member on holiday is left out; the rest are planned", async () => {
  const away = { id: "h2", kind: "holiday" as const, audience: { student: RIYA }, title: "Away", date: "2026-10-07", receivedAt: "2026-10-01T10:00:00+05:30" };
  const s = source(taught({ items: [away] }));
  await drainAll(planJob(s), planJobFor(), ctx(fakeDb(), answers()));
  const draft = s.made[0] as { leftOut: string[]; groups: { memberIDs: string[] }[] };
  expect(draft.groups.flatMap((g) => g.memberIDs)).toEqual([DEV]);
});

test("a replacing job writes over an open plan with today's choices, never a closed one", async () => {
  const open = source(taught({ existingPlan: { id: "plan-1", closed: false } }));
  const out = await drainAll(planJob(open), planJobFor(CLASS, "2026-10-07", { replace: true, choices: { groups: 1, subjects: { "1": "Mathematics" } } }), ctx(fakeDb(), answers()));
  expect(open.made).toHaveLength(1);
  expect((open.made[0] as { groups: { subject: string }[] }).groups.map((g) => g.subject)).toEqual(["Mathematics"]);
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { plan_id: "plan-1" } });
  const closed = source(taught({ existingPlan: { id: "plan-1", closed: true } }));
  const shut = await drainAll(planJob(closed), planJobFor(CLASS, "2026-10-07", { replace: true }), ctx(fakeDb(), answers()));
  expect(shut.at(-1)).toMatchObject({ kind: "done", result: { plan_id: "plan-1", reason: "closed" } });
  expect(closed.made).toEqual([]);
});

test("Plan ready is not queued for a tutor who turned it off; the fetch still is", async () => {
  const s = source(taught(), { users: [{ user: "u1", planReady: false, notesReady: true }, { user: "u2", planReady: true, notesReady: true }] });
  await drainAll(planJob(s), planJobFor(), ctx(fakeDb(), answers()));
  expect(s.notified.map((n) => [n.user, n.kind])).toEqual([["u1", "plan_fetch"], ["u2", "plan_ready"], ["u2", "plan_fetch"]]);
});

test("a make step whose draft is repaired keeps the repaired artefact and sums the cost of its rows (D99)", async () => {
  let sheets = 0;
  const claude = fakeClaude((r) => {
    if (isCheckRequest(r) || kindOf(r) !== "sheet") return { answer: localAnswer(r) };
    sheets += 1;
    const answer = localAnswer(r) as { questions: { proof: unknown }[] };
    // The first sheet's first draft carries a key that does not add up; its repair carries the right one.
    const proof = { expression: sheets === 1 ? "2*2" : "2*2+1", equals: 5 };
    return { answer: { ...answer, questions: answer.questions.map((q, i) => (i === 0 ? { ...q, proof } : q)) } };
  });
  const db = fakeDb();
  const s = source(taught());
  const out = await drainAll(planJob(s), planJobFor(), ctx(db, claude));
  const step = out.find((o) => o.name === "make:keep:1") as { costPaise: number };
  const rows = db.rows.filter((r) => r.key?.startsWith("job-1:make:1"));
  expect(rows.map((r) => r.agentStep)).toEqual(["draft", "check", "repair", "check"]);
  // The draft, its check, the repair and its check each went in a batch at half (D111).
  expect(rows.map((r) => r.finish?.batched === true)).toEqual([true, true, true, true]);
  expect(claude.batches.map((b) => b.map((i) => i.customId))).toEqual([
    ["make_0", "make_1", "make_2", "make_3"],
    ["make_0__check", "make_1__check", "make_2__check", "make_3__check"],
    ["make_1__repair"],
    ["make_1__recheck"],
  ]);
  expect(step.costPaise).toBe(rows.reduce((n, r) => n + (r.finish?.costPaise ?? 0), 0));
  const kept = s.kept.find((k) => k.kind === "sheet") as unknown as { content: { questions: { proof: { expression: string } }[] } };
  expect(kept.content.questions[0]?.proof.expression).toBe("2*2+1");
});

test("a paused kind is not made and not paid; the plan ends done with it counted not made (D100, review focus 5)", async () => {
  const t = installModelTable(fakeModelSource([{ kind: "sheet_from_6", step: "draft", model: "claude-sonnet-5-5", effort: "medium", fallbackModel: null, enabled: false }]));
  await t.refresh();
  try {
    const db = fakeDb();
    const s = source(taught());
    const out = await drainAll(planJob(s), planJobFor(), ctx(db, answers()));
    const paused = out.filter((o) => o.kind === "continue" && (o as { error?: { reason: string } }).error?.reason === "paused");
    expect(paused.map((o) => o.name)).toEqual(["make:1", "make:2"]);
    expect(paused.every((o) => !(o as { costPaise?: number }).costPaise)).toBe(true);
    expect(db.rows.filter((r) => r.kind === "sheet")).toHaveLength(0);
    expect(s.kept.map((k) => k.kind)).not.toContain("sheet");
    const done = out.at(-1) as unknown as { kind: string; result: { not_made: number } };
    expect(done.kind).toBe("done");
    expect(done.result.not_made).toBe(2);
  } finally {
    t.stop();
  }
});

test("the batch's rows are priced at half and marked batched; a job's calls ask the hour's cache (D108)", async () => {
  const db = fakeDb();
  const claude = answers();
  await drainAll(planJob(source(taught())), planJobFor(), ctx(db, claude));
  const drafts = db.rows.filter((r) => /^job-1:make:\d$/.test(r.key ?? ""));
  expect(drafts.map((r) => r.key)).toEqual(["job-1:make:0", "job-1:make:1", "job-1:make:2", "job-1:make:3"]);
  const made = db.rows.filter((r) => r.key?.startsWith("job-1:make"));
  expect(made.every((r) => r.finish?.batched === true)).toBe(true);
  const first = drafts[0]?.finish;
  expect(first?.costPaise).toBe(costPaise(first?.model ?? "", 812, 1460, 0, 0, 0.5));
  expect(claude.batches.flat().every((i) => i.request.system.ttl === "1h")).toBe(true);
  // The naming call, live, asks the hour too.
  expect(claude.requests.filter((r) => kindOf(r) === "plan").every((r) => r.system.ttl === "1h")).toBe(true);
});

test("a batch not ended by its deadline is left and the rest made live, each draft row once (D108)", async () => {
  const db = fakeDb();
  const claude = fakeClaude((r) => ({ answer: isCheckRequest(r) ? PASS : localAnswer(r) }), { batchPolls: 1_000 });
  // 00:05 in India on the plan's day: the deadline is four hours on.
  const clock = fakeClock(Date.parse("2026-10-06T18:35:00Z"));
  const c: StepContext = { db, jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" };
  const s = source(taught());
  const handler = planJob(s);
  let current = planJobFor();
  let outcome: StepOutcome | undefined;
  for (let i = 0; i < 20; i++) {
    outcome = await handler.step(current, c);
    if (outcome.kind === "wait" && outcome.name === "make:wait") break;
    current = { ...current, step: (outcome as { step: Record<string, unknown> }).step };
  }
  expect(outcome).toMatchObject({ kind: "wait", name: "make:wait" });
  current = { ...current, step: (outcome as { step: Record<string, unknown> }).step };
  clock.advance(5 * 3_600_000);
  const rest = await drainAll(handler, current, c);
  expect(claude.cancelled).toEqual(["batch-1"]);
  expect(rest.map((o) => o.name)).toEqual(["make:wait", "make:0", "make:1", "make:2", "make:3", "notify"]);
  expect(s.kept.map((k) => k.key)).toEqual(["job-1:make:0", "job-1:make:1", "job-1:make:2", "job-1:make:3"]);
  const drafts = db.rows.filter((r) => /^job-1:make:\d$/.test(r.key ?? ""));
  expect(drafts).toHaveLength(4);
  // Made live on the batch's rows: the full price, not batched.
  expect(drafts.every((r) => r.finish?.status === "ok" && r.finish.batched !== true)).toBe(true);
  expect(rest.at(-1)).toMatchObject({ kind: "done", result: { made: 4, not_made: 0 } });
});

test("a batch's draft that comes back failed is not made and the job goes on", async () => {
  const claude = fakeClaude((r) => (!isCheckRequest(r) && kindOf(r) === "worked_example" ? { fail: "batch errored" } : { answer: localAnswer(r) }));
  const s = source(taught());
  const out = await drainAll(planJob(s), planJobFor(), ctx(fakeDb(), claude));
  expect(claude.batches[1]?.map((i) => i.customId)).toEqual(["make_0__check", "make_1__check", "make_2__check"]);
  expect(s.kept.map((k) => k.kind)).toEqual(["check", "sheet", "sheet"]);
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { made: 3, not_made: 1 } });
});

test("a plan asked too close to its batch's start makes its material live: no batch is sent (D108)", async () => {
  const claude = answers();
  // 16:00 in India, an hour before the batch: past its deadline already.
  const clock = fakeClock(Date.parse("2026-10-07T10:30:00Z"));
  const out = await drainAll(planJob(source(taught())), planJobFor(), { db: fakeDb(), jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" });
  expect(claude.batches).toHaveLength(0);
  expect(out.map((o) => o.name)).toEqual(["read", "groups", "name", "write", "budget", "make:submit", "make:0", "make:1", "make:2", "make:3", "notify"]);
});

test("a repair batch not ended by the deadline is given up and the repair made live on its row (D111)", async () => {
  let sheets = 0;
  let batches = 0;
  const base = fakeClaude((r) => {
    if (isCheckRequest(r) || kindOf(r) !== "sheet") return { answer: localAnswer(r) };
    sheets += 1;
    const answer = localAnswer(r) as { questions: { proof: unknown }[] };
    const proof = { expression: sheets === 1 ? "2*2" : "2*2+1", equals: 5 };
    return { answer: { ...answer, questions: answer.questions.map((q, i) => (i === 0 ? { ...q, proof } : q)) } };
  });
  // The third batch (the repairs) never ends.
  const claude = Object.assign(base, {
    async batch(items: Parameters<NonNullable<typeof base.batch>>[0]) {
      batches += 1;
      base.batches.push(items);
      return { id: `batch-${batches}` };
    },
    async batchResults(id: string, items: Parameters<NonNullable<typeof base.batchResults>>[1]) {
      if (id === "batch-3") return "running" as const;
      const answers = new Map();
      for (const item of items) answers.set(item.customId, await base.complete(item.request));
      return answers;
    },
  });
  const db = fakeDb();
  const clock = fakeClock(Date.parse("2026-10-06T18:35:00Z"));
  const c: StepContext = { db, jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" };
  const s = source(taught());
  const handler = planJob(s);
  let current = planJobFor();
  let outcome: StepOutcome | undefined;
  for (let i = 0; i < 20; i++) {
    outcome = await handler.step(current, c);
    current = { ...current, step: (outcome as { step: Record<string, unknown> }).step };
    if (outcome.kind === "wait") break;
  }
  expect(outcome).toMatchObject({ kind: "wait", name: "make:wait", step: { phase: "repairs" } });
  clock.advance(5 * 3_600_000);
  const rest = await drainAll(handler, current, c);
  expect(claude.cancelled).toEqual(["batch-3"]);
  expect(rest.at(-1)).toMatchObject({ kind: "done", result: { made: 4, not_made: 0 } });
  const repairs = db.rows.filter((r) => r.key === "job-1:make:1:repair");
  // The batch's repair row, then the live repair's: the real gate replays the pending row by its key.
  expect(repairs.at(-1)?.finish?.batched).not.toBe(true);
  const kept = s.kept.find((k) => k.kind === "sheet") as unknown as { content: { questions: { proof: { expression: string } }[] } };
  expect(kept.content.questions[0]?.proof.expression).toBe("2*2+1");
});
