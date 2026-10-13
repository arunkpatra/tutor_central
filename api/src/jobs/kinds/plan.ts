import { plan as planKind } from "../../agents/kinds/index.js";
import { makeAgent } from "../../make.js";
import type { PlanInput as TopicsInput } from "../../schemas.js";
import { type BudgetInput, budget, type MaterialRequest } from "../../plan/budget.js";
import { type GapReport, nearestExam, type PrepItem, type PrepStudent, revisionLines } from "../../plan/exam-prep.js";
import { type KeptArtefact, artefactOf, materialInput, placementGroups, placeOf } from "../../plan/material.js";
import { weekday } from "../../plan/dates.js";
import { MOCK_LINE } from "../../plan/exam.js";
import { addingBriefs, naming, planRules } from "../../plan/rules.js";
import {
  CLASS_LEVELS,
  type Chapter,
  type ClassLevel,
  type Hint,
  type LineKind,
  type PlanDraft,
  type PlanInput,
  type Revision,
  type Session,
  type Skill,
  type Student,
} from "../../plan/types.js";
import type { NotificationRow } from "../../push/db.js";
import { recordedCall } from "../call.js";
import type { Job, JobHandler, StepContext, StepOutcome } from "../types.js";

/** What the job reads of a batch for a day (as PlanMaker.read did): the batch with its days and times, its active
 *  members, their chapters and skills, this month's and last month's sessions, the centre's school items, the gap
 *  reports used for an exam and the mocks made, whether the day's session is closed, the plan already made for the day,
 *  and the chapters the tutor had briefs made for. */
export type PlanRead = {
  classroom: PlanInput["classroom"] & { name?: string; meetingDays?: number[]; start?: string | null; end?: string | null };
  members: (Student & { schoolId?: string | null })[];
  chapters: Record<string, Chapter[]>;
  skills: Record<string, Skill[]>;
  sessions: Session[];
  items: PrepItem[];
  closed: boolean;
  /** The day's plan, if any, and whether its session closed it. */
  existingPlan: { id: string; closed: boolean } | null;
  briefChapters: string[];
  /** By student: the gap report used for their exam. */
  gapReports?: Record<string, GapReport>;
  /** By exam: the mock made for it. */
  mocks?: Record<string, string>;
};

/** The record as the job reaches it: through the service role, the centre always the job's own (D83). */
export type PlanRecordSource = {
  read(centre: string, classId: string, date: string): Promise<PlanRead>;
  /** The plan already made for the batch and day, if any (the phone's, made meanwhile). */
  existingPlan(centre: string, classId: string, date: string): Promise<{ id: string; closed: boolean } | null>;
  /** A new chapter at the end of the subject with one skill; the skill's id. */
  addChapter(centre: string, student: string, subject: string, name: string, skill: string): Promise<string>;
  /** A new skill at the end of the chapter; its id. */
  addSkill(centre: string, chapter: string, student: string, name: string): Promise<string>;
  /** make_plan, with the parameters SupabasePlansRepository.makeParams builds; the plan's id. */
  makePlan(centre: string, draft: PlanDraft): Promise<string>;
  /** keep_artefact: the artefact kept once by its key and linked to the plan's lines of its place; its id. */
  keep(centre: string, artefact: KeptArtefact, place: { plan: string; groupNo: number; student?: string; itemKind: LineKind; schoolItem?: string }, key: string): Promise<string>;
  /** The plan's group lines of a kind take an artefact kept before (a mock another plan or the phone made). */
  link(centre: string, plan: string, groupNo: number, itemKind: LineKind, artefact: string): Promise<void>;
  /** The mock kept for an exam, if any. */
  mockFor(centre: string, schoolItem: string): Promise<string | null>;
  /** The centre's members reachable by a push, and whether each wants Plan ready. */
  pushUsers(centre: string): Promise<{ user: string; planReady: boolean; notesReady: boolean }[]>;
  /** Rows queued in a user's outbox (nothing of theirs cancelled). */
  notify(centre: string, user: string, rows: NotificationRow[]): Promise<void>;
};

/** A naming call or a mock still running: the next try, half a minute on. */
const KEY_WAIT_MS = 30_000;

type Made = { made: number; notMade: number };
type Step =
  | { at?: undefined }
  | { at: "groups"; record: PlanRead }
  | { at: "name"; record: PlanRead; draft: PlanDraft; revisions: Record<string, Revision> }
  | { at: "write"; record: PlanRead; draft: PlanDraft; revisions: Record<string, Revision> }
  | { at: "budget"; record: PlanRead; draft: PlanDraft; revisions: Record<string, Revision>; plan: string }
  | ({ at: "make"; n: number; record: PlanRead; draft: PlanDraft; plan: string; requests: MaterialRequest[] } & Made)
  | ({ at: "notify"; record: PlanRead; draft: PlanDraft; plan: string } & Made);

type Choices = { groups?: number; subjects?: Record<string, string> };
type Input = { classId: string; date: string; replace: boolean; choices?: Choices };

/** The day's plan for a batch, made on the server (D70; plan/phase-18-plan.md decisions 10, 11): read; the groups by
 *  the rules with the exam weeks and holidays; a name for the groups the record leaves unnamed (one `plan` call); the
 *  plan written; the budget's material made one request a step, each kept and linked; then Plan ready and the plan's
 *  background fetch queued for the batch's tutors. It never replaces a plan unless asked (Make the plan again), and
 *  never a closed one. */
export function planJob(source: PlanRecordSource): JobHandler {
  return {
    async step(job, ctx) {
      const raw = job.input as { class_id?: unknown; date?: unknown; replace?: unknown; choices?: unknown };
      const classId = typeof raw.class_id === "string" ? raw.class_id : null;
      const date = typeof raw.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(raw.date) ? raw.date : null;
      if (!job.centreId || !classId || !date) {
        return { kind: "fail", name: "start", error: { reason: "input", message: "a plan job names a centre, a class and a day" }, retry: false };
      }
      const input: Input = { classId, date, replace: raw.replace === true, choices: (raw.choices ?? undefined) as Choices | undefined };
      const step = job.step as Step;
      const centre = job.centreId;
      switch (step.at) {
        case undefined:
          return read(source, centre, input);
        case "groups":
          return groups(step.record, input);
        case "name":
          return name(job, ctx, source, centre, step);
        case "write":
          return write(source, centre, input, step);
        case "budget":
          return material(source, centre, ctx, step);
        case "make":
          return make(job, ctx, source, centre, step);
        case "notify":
          return notify(source, centre, input, job.id, step, ctx);
      }
    },
  };
}

async function read(source: PlanRecordSource, centre: string, input: Input): Promise<StepOutcome> {
  let record: PlanRead;
  try {
    record = await source.read(centre, input.classId, input.date);
  } catch (e) {
    return { kind: "fail", name: "read", error: { reason: "read_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
  const plan = record.existingPlan;
  if (plan?.closed || record.closed) return { kind: "done", name: "read", result: { plan_id: plan?.id ?? null, reason: "closed" } };
  if (plan && !input.replace) return { kind: "done", name: "read", result: { plan_id: plan.id, reason: "made" } };
  if (record.members.length === 0) return { kind: "done", name: "read", result: { plan_id: null, reason: "no_members" } };
  // The job was queued at midnight for the day; the batch's days may have changed since (the review's R-db-7). A plan
  // asked for after the batch began is still wanted, so the start is not checked.
  const days = record.classroom.meetingDays;
  if (days && !days.includes(weekday(input.date))) return { kind: "done", name: "read", result: { plan_id: null, reason: "not_meeting" } };
  return { kind: "continue", name: "read", step: { at: "groups", record } };
}

const prepStudent = (m: PlanRead["members"][number]): PrepStudent => ({ id: m.id, name: m.name, classLevel: m.classLevel, schoolID: m.schoolId ?? undefined });

/** Each member's nearest exam with a subject, for the rules' subject choice (SchoolItemRules.hints). */
export function hintsOf(record: PlanRead, date: string): Hint[] {
  return record.members.flatMap((m) => {
    const exam = nearestExam(prepStudent(m), record.items, date);
    return exam?.subject ? [{ studentID: m.id, subject: exam.subject, date: exam.date }] : [];
  });
}

function groups(record: PlanRead, input: Input): StepOutcome {
  const { revisions, holidays } = revisionLines({
    members: record.members.map(prepStudent),
    items: record.items,
    meetingDays: record.classroom.meetingDays ?? [],
    date: input.date,
    chapters: record.chapters,
    skills: record.skills,
    gapReports: record.gapReports ?? {},
  });
  // Every member on holiday: no plan (the phone's `.holiday`).
  if (holidays.length === record.members.length) return { kind: "done", name: "groups", result: { plan_id: null, reason: "holiday" } };
  const draft = planRules(planInput(record, input, { revisions, holidays, hints: hintsOf(record, input.date) }));
  return { kind: "continue", name: "groups", step: { at: "name", record, draft, revisions } };
}

/** The rules' input (PlanMaker.input): the batch, the record, the exam lines and holidays, the hints and today's choices. */
export function planInput(record: PlanRead, input: Pick<Input, "date" | "choices">, exams: { revisions: Record<string, Revision>; holidays: string[]; hints: Hint[] }): PlanInput {
  const { name: _name, meetingDays: _days, start: _start, end: _end, ...classroom } = record.classroom;
  return {
    classroom,
    date: input.date,
    students: record.members.map(({ schoolId: _, ...student }) => student),
    chapters: record.chapters,
    skills: record.skills,
    sessions: record.sessions,
    hints: exams.hints,
    ...(input.choices?.groups !== undefined ? { groupCount: input.choices.groups } : {}),
    subjects: input.choices?.subjects ?? {},
    revisions: exams.revisions,
    holidays: exams.holidays,
  };
}

async function name(job: Job, ctx: StepContext, source: PlanRecordSource, centre: string, step: Extract<Step, { at: "name" }>): Promise<StepOutcome> {
  const { record, draft, revisions } = step;
  const next = (named: PlanDraft) => ({ at: "write" as const, record, draft: named, revisions });
  const unnamed = draft.groups.filter((g) => g.skill === "" && g.examItemID === undefined);
  // As the phone: a member with no chapter in a named group's subject gets its chapter and skill, whoever named it.
  if (unnamed.length === 0) return { kind: "continue", name: "name", step: next(await writeNamedSkills(draft, record, source, centre)) };
  const levels = new Map(record.members.map((m) => [m.id, m.classLevel]));
  const highest = (ids: string[]): ClassLevel => {
    const known = ids.flatMap((id) => levels.get(id) ?? []);
    return known.length ? (CLASS_LEVELS[Math.max(...known.map((l) => CLASS_LEVELS.indexOf(l)))] as ClassLevel) : "5";
  };
  const asked: TopicsInput = {
    centreId: centre,
    classId: draft.classID,
    date: draft.date,
    month: Number(draft.date.slice(5, 7)),
    groups: unnamed.map((g) => ({ groupNo: g.number, classLevel: highest(g.memberIDs), subject: g.subject })),
  };
  const call = await recordedCall(ctx, { centre, spec: planKind, input: asked, job: job.id, step: "name" });
  if (call.kind === "pending") return { kind: "wait", name: "name", step, runAt: new Date(ctx.clock.now() + KEY_WAIT_MS) };
  if (call.kind === "paused" || call.kind === "failed") {
    // The groups stay unnamed and the plan is written; their material waits for a name.
    const spent = call.kind === "failed" ? { generationId: call.id, costPaise: call.costPaise } : {};
    return { kind: "continue", name: "name", step: next(await writeNamedSkills(draft, record, source, centre)), ...spent };
  }
  const topics = new Map<number, { chapter: string; skill: string }>();
  for (const t of call.parsed.groups) if (!topics.has(t.groupNo)) topics.set(t.groupNo, { chapter: t.chapter, skill: t.skill });
  const named = await writeNamedSkills(naming(draft, topics), record, source, centre);
  return { kind: "continue", name: "name", step: next(named), generationId: call.id, costPaise: call.costPaise };
}

/** Each member of a named group with no skill in its subject gets the group's chapter and skill in their own record, and
 *  their teach and check lines take it (PlanMaker.writeNamedSkills); a write that fails leaves the line as it was. */
export async function writeNamedSkills(draft: PlanDraft, record: PlanRead, source: PlanRecordSource, centre: string): Promise<PlanDraft> {
  const own = new Map<string, string>();
  for (const group of draft.groups) {
    if (group.examItemID || group.skill === "") continue;
    for (const member of group.memberIDs) {
      const chapters = (record.chapters[member] ?? []).filter((c) => c.subject === group.subject);
      const skills = record.skills[member] ?? [];
      if (skills.some((s) => chapters.some((c) => c.id === s.chapterID))) continue;
      try {
        const chapter = chapters.find((c) => c.name.toLowerCase() === group.chapter.toLowerCase());
        const existing = chapter ? skills.find((s) => s.chapterID === chapter.id && s.name === group.skill) : undefined;
        const id = existing?.id ?? (chapter ? await source.addSkill(centre, chapter.id, member, group.skill) : await source.addChapter(centre, member, group.subject, group.chapter, group.skill));
        own.set(member, id);
      } catch {
        // As the phone: the student's line keeps the group's skill; the close matches it by name.
      }
    }
  }
  if (own.size === 0) return draft;
  return {
    ...draft,
    lines: draft.lines.map((line) => {
      const id = line.studentID ? own.get(line.studentID) : undefined;
      return id && (line.kind === "teach" || line.kind === "check") ? { ...line, skillID: id } : line;
    }),
  };
}

async function write(source: PlanRecordSource, centre: string, input: Input, step: Extract<Step, { at: "write" }>): Promise<StepOutcome> {
  try {
    // The phone may have made the day's plan meanwhile: make_plan would replace it and its material's links. A replacing
    // job writes over an open plan, never a closed one.
    const existing = await source.existingPlan(centre, input.classId, input.date);
    if (existing?.closed) return { kind: "done", name: "write", result: { plan_id: existing.id, reason: "closed" } };
    if (existing && !input.replace) return { kind: "done", name: "write", result: { plan_id: existing.id, reason: "made" } };
    const draft = addingBriefs(step.draft, new Set(step.record.briefChapters));
    const plan = await source.makePlan(centre, draft);
    return { kind: "continue", name: "write", step: { at: "budget", record: step.record, draft, revisions: step.revisions, plan } };
  } catch (e) {
    return { kind: "fail", name: "write", error: { reason: "write_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
}

/** The budget's requests (ArtefactBudget), after linking a mock made before to its exam group's set lines. */
async function material(source: PlanRecordSource, centre: string, ctx: StepContext, step: Extract<Step, { at: "budget" }>): Promise<StepOutcome> {
  const { record, draft, plan, revisions } = step;
  const mocks = record.mocks ?? {};
  for (const group of draft.groups) {
    const mock = group.examItemID ? mocks[group.examItemID] : undefined;
    const onMockDay = draft.lines.some((l) => l.groupNo === group.number && l.kind === "practise" && l.words === MOCK_LINE);
    if (mock && onMockDay) await source.link(centre, plan, group.number, "practise", mock);
  }
  const input: BudgetInput = {
    students: record.members.map(({ schoolId: _, ...student }) => student),
    chapters: record.chapters,
    skills: record.skills,
    revisions,
    now: new Date(ctx.clock.now()).toISOString(),
    briefsMade: record.briefChapters,
    mocksMade: Object.keys(mocks),
  };
  const requests = budget(draft, input);
  if (requests.length === 0) return { kind: "continue", name: "budget", step: { at: "notify", record, draft, plan, made: 0, notMade: 0 } };
  return { kind: "continue", name: "budget", step: { at: "make", n: 0, record, draft, plan, requests, made: 0, notMade: 0 } };
}

/** One request made and kept, or marked not made; the job goes on. A retaken step replays its call by its key and keeps
 *  once by the same key (review focus 5). A mock is keyed by its exam, so two batches' plans share one call and one
 *  artefact (review focus 3). */
async function make(job: Job, ctx: StepContext, source: PlanRecordSource, centre: string, step: Extract<Step, { at: "make" }>): Promise<StepOutcome> {
  const { n, requests, draft, plan, record } = step;
  const req = requests[n] as MaterialRequest;
  const name = `make:${n}`;
  const after = (made: boolean, extra: { generationId?: string; costPaise?: number; error?: { reason: string } } = {}): StepOutcome => {
    const counts = { made: step.made + (made ? 1 : 0), notMade: step.notMade + (made ? 0 : 1) };
    const next: Step = n + 1 < requests.length ? { ...step, ...counts, n: n + 1 } : { at: "notify", record, draft, plan, ...counts };
    return { kind: "continue", name, step: next, ...extra };
  };
  const wait = (): StepOutcome => ({ kind: "wait", name, step, runAt: new Date(ctx.clock.now() + KEY_WAIT_MS) });
  const place = placeOf(req, draft);
  const keep = async (artefact: KeptArtefact, key: string) => source.keep(centre, artefact, { plan, ...place }, key);
  try {
    if (req.kind === "placement") {
      const groups = placementGroups(record.chapters[req.student] ?? [], record.skills[req.student] ?? []);
      const questions: Record<string, unknown>[] = [];
      let cost = 0;
      for (const [i, group] of groups.entries()) {
        const body = { kind: "placement" as const, centreId: centre, classLevel: req.classLevel, subject: group.title, chapters: group.items.map((item) => item.name) };
        const call = await recordedCall(ctx, { centre, input: body, job: job.id, step: name, key: `${job.id}:${name}:${i}`, ...madeCall(body) });
        if (call.kind === "pending") return wait();
        if (call.kind === "paused") return after(false, { costPaise: cost, error: { reason: "paused" } });
        if (call.kind === "failed") return after(false, { costPaise: cost + (call.costPaise ?? 0) });
        cost += call.costPaise;
        const answered = (call.parsed as { questions: { question: string; answer: string }[] }).questions;
        group.items.forEach((item, q) => {
          const made = answered[q];
          if (made) questions.push({ skill_id: item.skillID, skill: item.skill, question: made.question, answer: made.answer });
        });
      }
      if (questions.length === 0) return after(false, { costPaise: cost });
      await keep({ kind: "placement", source: "made", title: "Placement", content: { questions, placement: true } }, `${job.id}:${name}`);
      return after(true, { costPaise: cost });
    }
    if (req.kind === "mock") {
      const kept = await source.mockFor(centre, req.item);
      if (kept) {
        await source.link(centre, plan, place.groupNo, "practise", kept);
        return after(true);
      }
    }
    const body = materialInput(req, centre);
    if (!body) return after(false);
    const key = req.kind === "mock" ? `mock:${req.item}` : undefined;
    const call = await recordedCall(ctx, { centre, input: body, job: job.id, step: name, key, ...madeCall(body) });
    if (call.kind === "pending") return wait();
    // A kind switched off (D100): not made, nothing paid, the reason on the step.
    if (call.kind === "paused") return after(false, { error: { reason: "paused" } });
    // Another plan's mock for the same exam asked at another class level: its mock is linked at the next try.
    if (call.kind === "failed" && call.reason === "key_reused") return wait();
    if (call.kind === "failed") return after(false, { generationId: call.id, costPaise: call.costPaise });
    await keep(artefactOf(req, call.parsed, call.id), key ?? `${job.id}:${name}`);
    return after(true, { generationId: call.id, costPaise: call.costPaise });
  } catch (e) {
    // A keep or a link that did not reach the database: the step is taken again, its call replayed by its key.
    return { kind: "fail", name, error: { reason: "keep_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
}

/** The call for a body, as `recordedCall` takes it (no student: the plan's material names none, D62). */
function madeCall(body: Parameters<typeof makeAgent>[0]) {
  return { spec: makeAgent(body) };
}

/** "17:00–18:30 · 3 groups. Tap to see it." (P18-Notification-PlanReady), the times left out when the batch has none. */
export function planReadyBody(record: PlanRead, groups: number): string {
  const { start, end } = record.classroom;
  const times = start && end ? `${start.slice(0, 5)}–${end.slice(0, 5)} · ` : start ? `${start.slice(0, 5)} · ` : "";
  return `${times}${groups} ${groups === 1 ? "group" : "groups"}. Tap to see it.`;
}

/** Plan ready for each reachable tutor who wants it, and the plan's background fetch for every one (decisions 7, 17).
 *  The keys carry the job: the outbox rewrites no sent row, so a plan made again after Plan ready was sent needs its own
 *  rows (the review's R-db-4); a retaken step of the same job writes the same ones. */
async function notify(source: PlanRecordSource, centre: string, input: Input, job: string, step: Extract<Step, { at: "notify" }>, ctx: StepContext): Promise<StepOutcome> {
  const { record, draft, plan } = step;
  const now = new Date(ctx.clock.now()).toISOString();
  const ready: NotificationRow = {
    kind: "plan_ready",
    key: `plan_ready:${input.classId}:${input.date}:${job}`,
    due_at: now,
    title: `${record.classroom.name ?? "Your batch"}: today’s plan is ready`,
    body: planReadyBody(record, draft.groups.length),
    link: "tutorcentral://today",
  };
  const fetch: NotificationRow = { kind: "plan_fetch", key: `plan_fetch:${input.classId}:${input.date}:${job}`, due_at: now, background: true };
  try {
    for (const user of await source.pushUsers(centre)) await source.notify(centre, user.user, user.planReady ? [ready, fetch] : [fetch]);
  } catch (e) {
    return { kind: "fail", name: "notify", error: { reason: "notify_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
  return { kind: "done", name: "notify", result: { plan_id: plan, made: step.made, not_made: step.notMade } };
}
