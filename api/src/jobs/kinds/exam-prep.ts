import type { Kind } from "../../agents/agent.js";
import { makeAgent } from "../../make.js";
import { defaultPattern } from "../../plan/budget.js";
import { istDay } from "../../plan/dates.js";
import { examDays, type PrepDay, type PrepItem, type PrepStudent, portionsOf, prepStart } from "../../plan/exam-prep.js";
import { tallies } from "../../plan/gap.js";
import type { KeptArtefact } from "../../plan/material.js";
import type { Chapter, Skill } from "../../plan/types.js";
import { type ClassLevel, MakeInput, type MockOutput } from "../../schemas.js";
import { recordedCall } from "../call.js";
import type { Job, JobHandler, StepContext, StepOutcome } from "../types.js";

/** What the exam job reads of an exam item (D106): the item, the students it reaches with their batch, each batch's
 *  meeting days and whether today's plan is made and open, the students' chapters and skills (the split), the
 *  holidays, the mock kept for it, the marks saved on it with their questions, the students with a gap report kept. */
export type ExamRead = {
  item: PrepItem;
  students: (PrepStudent & { classId: string | null })[];
  batches: { classId: string; meetingDays: number[]; openPlanToday: boolean }[];
  chapters: Record<string, Chapter[]>;
  skills: Record<string, Skill[]>;
  holidays: PrepItem[];
  mock: { id: string; content: MockOutput } | null;
  marks: { student: string; questions: { number: number; marks: number; note?: string | null }[] }[];
  reports: string[];
};

export type ExamSource = {
  /** The exam as of `today`, by the job's own centre; null when the item is gone or is not an exam. */
  read(centre: string, item: string, today: string): Promise<ExamRead | null>;
  /** The split on the item: `preparation` the first batch's (build 31 reads it), `preparations` each batch's by its id
   *  (D118: the page and the plan read their student's batch's). */
  writePreparation(
    centre: string,
    item: string,
    days: Record<string, unknown>[],
    byBatch: Record<string, Record<string, unknown>[]>,
  ): Promise<void>;
  /** keep_artefact with the exam (and the student for a gap report), once by its key. */
  keep(centre: string, artefact: KeptArtefact, place: { student?: string; schoolItem: string }, key: string): Promise<string>;
  /** The batch's plan for the day asked again (`request_plan` with choices: a replace), so its lines read the report. */
  replacePlan(centre: string, classId: string, date: string): Promise<void>;
};

/** What the split was made from: a change to any of them (the trigger wakes the job) splits again. */
type Basis = { date: string; portions: string | null; windowDays: number | null };
type Step = (
  | { at?: undefined }
  | { at: "wait"; mockDay: string }
  | { at: "mock"; mockDay?: string; woken?: boolean }
  | { at: "marks"; mockFailed?: boolean; woken?: boolean; failed?: string[] }
) & { basis?: Basis };

/** A quarter hour between reads of the marks; half a minute while a call with the same key runs. */
const TICK_MS = 15 * 60_000;
const KEY_WAIT_MS = 30_000;
const LEVELS: ClassLevel[] = ["lkg", "ukg", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
const highest = (levels: (string | undefined)[]): ClassLevel | undefined =>
  levels.filter((l): l is ClassLevel => LEVELS.includes(l as ClassLevel)).sort((a, b) => LEVELS.indexOf(b) - LEVELS.indexOf(a))[0];
/** 05:00 in India on a day, as an instant. */
const morning = (day: string) => new Date(Date.parse(`${day}T05:00:00+05:30`));
const daysBetween = (from: string, to: string) => Math.round((Date.parse(to) - Date.parse(from)) / 86_400_000);
const basisOf = (item: PrepItem): Basis => ({ date: item.date, portions: item.portions ?? null, windowDays: item.windowDays ?? null });
const sameBasis = (a: Basis, b: Basis) => a.date === b.date && a.portions === b.portions && a.windowDays === b.windowDays;
/** The basis carried into the job's next step. */
const carrying = (outcome: StepOutcome, basis: Basis): StepOutcome =>
  outcome.kind === "continue" || outcome.kind === "wait" ? { ...outcome, step: { ...outcome.step, basis } } : outcome;

/** Exam preparation as one job per exam item (D106, `exam:<item>`): `split` writes the days from the rules on the item,
 *  `wait` sleeps to the mock day's 05:00 in India, `mock` makes the mock once by its key `mock:<item>` (the plan's own
 *  key, so either makes it and both link it), `marks` each quarter hour to the exam day makes the gap report of each
 *  student newly marked (`gap:<item>:<student>`, kept used) and asks today's open plan again; done on the exam day. A
 *  mock not made is tried again only at the tutor's ask (the wake marks the step `woken`). The item is read by the job's
 *  own centre (the security review of #319). */
export function examPrep(source: ExamSource): JobHandler {
  return {
    async step(job, ctx) {
      const item = typeof job.input.item_id === "string" ? job.input.item_id : null;
      if (!job.centreId || !item) return { kind: "fail", name: "start", error: { reason: "input", message: "an exam job names its item" }, retry: false };
      const centre = job.centreId;
      const today = istDay(new Date(ctx.clock.now()));
      const step = job.step as Step;
      const read = await source.read(centre, item, today).catch((e: unknown) => e as Error);
      if (read instanceof Error) return { kind: "fail", name: step.at ?? "split", error: { reason: "read_failed", message: read.message }, retry: true };
      if (!read) return { kind: "done", name: step.at ?? "split", result: { item_id: item, reason: "gone" } };
      if (today >= read.item.date) {
        if (step.at === undefined) return { kind: "done", name: "split", result: { item_id: item, reason: "past" } };
        return { kind: "done", name: step.at, result: { item_id: item, mock: read.mock !== null, reports: read.reports.length } };
      }
      const basis = basisOf(read.item);
      if (step.at !== undefined && step.basis && !sameBasis(step.basis, basis)) {
        // The exam changed since its split: the days again, so the plan reads what the page shows. A mock made stays and
        // the marks go on; before it, the job waits for the new mock day.
        const again = await split(source, centre, item, read, today);
        if (!read.mock || again.kind === "fail") return carrying(again, basis);
      }
      return carrying(await next(job, ctx, source, centre, item, read, today, step), basis);
    },
  };
}

/** The step's own work, the exam unchanged since its split. */
async function next(job: Job, ctx: StepContext, source: ExamSource, centre: string, item: string, read: ExamRead, today: string, step: Step): Promise<StepOutcome> {
  switch (step.at) {
    case undefined:
      return split(source, centre, item, read, today);
    case "wait":
      return ctx.clock.now() >= morning(step.mockDay).getTime()
        ? mock(job, ctx, source, centre, item, read)
        : { kind: "wait", name: "wait", step: { at: "mock", mockDay: step.mockDay }, runAt: morning(step.mockDay) };
    case "mock":
      return mock(job, ctx, source, centre, item, read);
    case "marks":
      return marks(job, ctx, source, centre, item, read, today, step);
  }
}

/** The days for each batch the exam reaches, from its first reached student and that batch's meeting days, written on
 *  the item (D118); `preparation` stays the first batch's. Then the wait for the first batch's mock morning: the mock is
 *  one per exam, shared across the batches. */
async function split(source: ExamSource, centre: string, item: string, read: ExamRead, today: string): Promise<StepOutcome> {
  const reached = read.batches
    .map((batch) => ({ batch, student: read.students.find((s) => s.classId === batch.classId) }))
    .filter((r): r is { batch: ExamRead["batches"][number]; student: ExamRead["students"][number] } => r.student !== undefined)
    // The first batch is the first reached student's, as before (build 31's page reads it).
    .sort(
      (a, b) =>
        read.students.findIndex((s) => s.classId === a.batch.classId) -
        read.students.findIndex((s) => s.classId === b.batch.classId),
    );
  const first = reached[0];
  if (!first) return { kind: "done", name: "split", result: { item_id: item, reason: "no_students" } };
  const daysOf = ({ batch, student }: (typeof reached)[number]): PrepDay[] =>
    examDays(read.item, student, read.chapters[student.id] ?? [], read.skills[student.id] ?? [], {
      meetingDays: batch.meetingDays,
      start: prepStart(read.item, today),
      holidays: read.holidays,
    });
  const rows = (days: PrepDay[]) =>
    days.map((d) => ({ day: d.day, kind: d.kind, index: d.index ?? null, title: d.title, skills: d.skills, skill_ids: d.skillIDs }));
  const days = daysOf(first);
  const byBatch = Object.fromEntries(reached.map((r) => [r.batch.classId, rows(r === first ? days : daysOf(r))]));
  try {
    await source.writePreparation(centre, item, rows(days), byBatch);
  } catch (e) {
    return { kind: "fail", name: "split", error: { reason: "write_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
  const mockDay = days.find((d) => d.kind === "mock")?.day;
  // Fewer than three days to the exam: no mock day, so nothing to mark; the plan revises every day.
  if (!mockDay) return { kind: "done", name: "split", result: { item_id: item, mock: false, reports: 0, reason: "no_mock_day" } };
  return { kind: "continue", name: "split", step: { at: "wait", mockDay } };
}

/** The mock as the plan's budget asks it (the same body under the same key): the exam's title and portions, the
 *  highest class's default pattern. Kept with the exam; then the marks are read each quarter hour. */
async function mock(job: Job, ctx: StepContext, source: ExamSource, centre: string, item: string, read: ExamRead): Promise<StepOutcome> {
  const marksNext = (extra: Partial<Extract<StepOutcome, { kind: "wait" }>> = {}, failed = false): StepOutcome => ({
    kind: "wait",
    name: "mock",
    step: failed ? { at: "marks", mockFailed: true } : { at: "marks" },
    runAt: new Date(ctx.clock.now() + TICK_MS),
    ...extra,
  });
  if (read.mock) return marksNext();
  const level = highest(read.students.map((s) => s.classLevel)) ?? "8";
  const portions = portionsOf(read.item.portions ?? read.item.title).map((p) => p.slice(0, 200)).slice(0, 30);
  const parsed = MakeInput.safeParse({
    centreId: centre,
    kind: "mock",
    classLevel: level,
    subject: read.item.subject ?? "",
    title: read.item.title.slice(0, 120),
    portions: portions.length > 0 ? portions : [read.item.title.slice(0, 200)],
    pattern: defaultPattern(level),
  });
  if (!parsed.success || parsed.data.kind !== "mock") return marksNext({}, true);
  const body = parsed.data;
  const key = `mock:${item}`;
  const call = await recordedCall(ctx, { centre, spec: makeAgent(body) as Kind<unknown, MockOutput>, input: body, job: job.id, step: "mock", key });
  if (call.kind === "pending") return { kind: "wait", name: "mock", step: { at: "mock" }, runAt: new Date(ctx.clock.now() + KEY_WAIT_MS) };
  // The key held by another body (a plan's mock at another level, R-api-6): that plan keeps and links it; read again in a
  // quarter hour, not every half minute for the key's day.
  if (call.kind === "failed" && call.reason === "key_reused") return { kind: "wait", name: "mock", step: { at: "mock" }, runAt: new Date(ctx.clock.now() + TICK_MS) };
  if (call.kind === "paused") return marksNext({}, true);
  if (call.kind === "failed") return marksNext({ generationId: call.id, costPaise: call.costPaise }, true);
  try {
    await source.keep(centre, {
      kind: "mock",
      source: "made",
      title: body.title,
      content: {
        title: call.parsed.title,
        duration_minutes: call.parsed.durationMinutes,
        sections: call.parsed.sections.map((s) => ({ name: s.name, marks_each: s.marksEach, questions: s.questions })),
        pattern: { marks: body.pattern.marks, duration_minutes: body.pattern.durationMinutes },
        portions: body.portions,
        school_item_id: item,
      },
      generation_id: call.id,
    }, { schoolItem: item }, key);
  } catch (e) {
    return { kind: "fail", name: "mock", error: { reason: "keep_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
  return marksNext({ generationId: call.id, costPaise: call.costPaise });
}

/** One student's gap report a step: the tallies the app's arithmetic gives, the report kept used, today's open plan of
 *  their batch asked again. A report the service could not make is not tried again (it would pay each quarter hour). */
async function marks(job: Job, ctx: StepContext, source: ExamSource, centre: string, item: string, read: ExamRead, today: string, step: Extract<Step, { at: "marks" }>): Promise<StepOutcome> {
  // A tutor's Save (the wake) tries again a report the service could not make.
  const failed = step.woken ? [] : (step.failed ?? []);
  const later = (extra: { generationId?: string; costPaise?: number } = {}, notMade: string[] = failed): StepOutcome => ({
    kind: "wait",
    name: "marks",
    step: { at: "marks", ...(step.mockFailed ? { mockFailed: true } : {}), ...(notMade.length ? { failed: notMade } : {}) },
    runAt: new Date(ctx.clock.now() + TICK_MS),
    ...extra,
  });
  if (!read.mock) return step.woken ? mock(job, ctx, source, centre, item, read) : later();
  const pending = read.marks.filter((m) => m.questions.length > 0 && !read.reports.includes(m.student) && !failed.includes(m.student));
  const mark = pending[0];
  if (!mark) return later();
  const student = read.students.find((s) => s.id === mark.student);
  // Weakest first, the order the report's days take them in.
  const bySkill = tallies(mark.questions, read.mock.content)
    .sort((a, b) => a.right / Math.max(1, a.of) - b.right / Math.max(1, b.of))
    .slice(0, 12);
  const parsed = MakeInput.safeParse({
    centreId: centre,
    kind: "gap_report",
    studentId: mark.student,
    classLevel: student?.classLevel ?? highest(read.students.map((s) => s.classLevel)) ?? "8",
    subject: read.item.subject ?? "",
    daysLeft: Math.min(3, Math.max(1, daysBetween(today, read.item.date))),
    bySkill: bySkill.map((t) => ({ skill: t.skill.slice(0, 200), right: t.right, of: Math.max(1, t.of), ...(t.note ? { note: t.note.slice(0, 300) } : {}) })),
  });
  if (!parsed.success || parsed.data.kind !== "gap_report") return later({}, [...failed, mark.student]);
  const key = `gap:${item}:${mark.student}`;
  const call = await recordedCall(ctx, { centre, spec: makeAgent(parsed.data) as Kind<unknown, { summary: string; days: { title: string; line: string }[] }>, input: parsed.data, job: job.id, step: "gap", key });
  if (call.kind === "pending") return { kind: "wait", name: "marks", step, runAt: new Date(ctx.clock.now() + KEY_WAIT_MS) };
  if (call.kind !== "ok") return later(call.kind === "failed" ? { generationId: call.id, costPaise: call.costPaise } : {}, [...failed, mark.student]);
  const score = bySkill.reduce((n, t) => n + t.right, 0);
  const max = bySkill.reduce((n, t) => n + t.of, 0);
  try {
    await source.keep(centre, {
      kind: "gap_report",
      source: "made",
      title: `${(student?.name ?? "").split(/\s+/)[0] ?? ""}'s gap report`.trim(),
      content: {
        summary: call.parsed.summary,
        by_skill: bySkill.map((t) => ({ skill: t.skill, right: t.right, of: t.of, note: t.note ?? null })),
        days: call.parsed.days,
        used_at: new Date(ctx.clock.now()).toISOString(),
        score,
        max,
        school_item_id: item,
      },
      generation_id: call.id,
    }, { student: mark.student, schoolItem: item }, key);
    for (const batch of read.batches) {
      if (batch.openPlanToday && student?.classId === batch.classId) await source.replacePlan(centre, batch.classId, today);
    }
  } catch (e) {
    return { kind: "fail", name: "marks", error: { reason: "keep_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
  const costs = { generationId: call.id, costPaise: call.costPaise };
  return pending.length > 1 ? { kind: "continue", name: "marks", step: { at: "marks", ...(failed.length ? { failed } : {}) }, ...costs } : later(costs);
}

