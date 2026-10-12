import { request as planRequest } from "../../prompts/plan.js";
import type { PlanInput as TopicsInput, PlanOutput } from "../../schemas.js";
import { addingBriefs, naming, planRules } from "../../plan/rules.js";
import { examMode, type SchoolItem } from "../../plan/school.js";
import { CLASS_LEVELS, type Chapter, type ClassLevel, type PlanDraft, type PlanInput, type Session, type Skill, type Student } from "../../plan/types.js";
import { recordedCall } from "../call.js";
import type { Job, JobHandler, StepContext, StepOutcome } from "../types.js";

/** What the job reads of a batch for a day (as PlanMaker.read does): the batch and its active members, their chapters
 *  and skills, this month's and last month's sessions, the centre's school items, whether the day's session is closed,
 *  the plan already made for the day, and the chapters the tutor had briefs made for. */
export type PlanRead = {
  classroom: PlanInput["classroom"];
  members: (Student & { schoolId?: string | null })[];
  chapters: Record<string, Chapter[]>;
  skills: Record<string, Skill[]>;
  sessions: Session[];
  items: SchoolItem[];
  closed: boolean;
  existingPlan: string | null;
  briefChapters: string[];
};

/** The record as the job reaches it: through the service role, the centre always the job's own (D83). */
export type PlanRecordSource = {
  read(centre: string, classId: string, date: string): Promise<PlanRead>;
  /** The plan already made for the batch and day, if any (the phone's, made meanwhile). */
  existingPlan(centre: string, classId: string, date: string): Promise<string | null>;
  /** A new chapter at the end of the subject with one skill; the skill's id. */
  addChapter(centre: string, student: string, subject: string, name: string, skill: string): Promise<string>;
  /** A new skill at the end of the chapter; its id. */
  addSkill(centre: string, chapter: string, student: string, name: string): Promise<string>;
  /** make_plan, with the parameters SupabasePlansRepository.makeParams builds; the plan's id. */
  makePlan(centre: string, draft: PlanDraft): Promise<string>;
};

/** A naming call still running: the next try, half a minute on. */
const KEY_WAIT_MS = 30_000;

type Step =
  | { at?: undefined }
  | { at: "groups"; record: PlanRead }
  | { at: "name"; record: PlanRead; draft: PlanDraft }
  | { at: "write"; record: PlanRead; draft: PlanDraft };

/** The day's plan for a batch, made on the server (D70; plan decision 20): read, the groups by the rules, a name for
 *  the groups the record leaves unnamed (one `plan` call), the plan written. The material stays the phone's `complete()`
 *  until Phase 18; so do days in exam mode (an exam or a holiday reaching a member). */
export function planJob(source: PlanRecordSource): JobHandler {
  return {
    async step(job, ctx) {
      const input = job.input as { class_id?: unknown; date?: unknown };
      const classId = typeof input.class_id === "string" ? input.class_id : null;
      const date = typeof input.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(input.date) ? input.date : null;
      if (!job.centreId || !classId || !date) {
        return { kind: "fail", name: "start", error: { reason: "input", message: "a plan job names a centre, a class and a day" }, retry: false };
      }
      const step = job.step as Step;
      const centre = job.centreId;
      switch (step.at) {
        case undefined:
          return read(source, centre, classId, date);
        case "groups":
          return { kind: "continue", name: "groups", step: { at: "name", record: step.record, draft: planRules(planInput(step.record, date)) } };
        case "name":
          return name(job, ctx, source, centre, step.record, step.draft);
        case "write":
          return write(source, centre, classId, date, step.record, step.draft);
      }
    },
  };
}

async function read(source: PlanRecordSource, centre: string, classId: string, date: string): Promise<StepOutcome> {
  let record: PlanRead;
  try {
    record = await source.read(centre, classId, date);
  } catch (e) {
    return { kind: "fail", name: "read", error: { reason: "read_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
  if (record.existingPlan) return { kind: "done", name: "read", result: { plan_id: record.existingPlan, reason: "made" } };
  if (record.closed) return { kind: "done", name: "read", result: { plan_id: null, reason: "closed" } };
  if (record.members.length === 0) return { kind: "done", name: "read", result: { plan_id: null, reason: "no_members" } };
  if (examMode(record.items, record.members, date)) return { kind: "done", name: "read", result: { plan_id: null, reason: "exam_mode" } };
  return { kind: "continue", name: "read", step: { at: "groups", record } };
}

/** The rules' input: no hints, no revisions, no holidays, since a day with any of them is the phone's this phase. */
export function planInput(record: PlanRead, date: string): PlanInput {
  return {
    classroom: record.classroom,
    date,
    students: record.members.map(({ schoolId: _, ...student }) => student),
    chapters: record.chapters,
    skills: record.skills,
    sessions: record.sessions,
    hints: [],
    subjects: {},
    revisions: {},
    holidays: [],
  };
}

async function name(job: Job, ctx: StepContext, source: PlanRecordSource, centre: string, record: PlanRead, draft: PlanDraft): Promise<StepOutcome> {
  const unnamed = draft.groups.filter((g) => g.skill === "");
  // As the phone: a member with no chapter in a named group's subject gets its chapter and skill, whoever named it.
  if (unnamed.length === 0) return { kind: "continue", name: "name", step: { at: "write", record, draft: await writeNamedSkills(draft, record, source, centre) } };
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
  const call = await recordedCall<PlanOutput>(ctx, { centre, kind: "plan", input: asked, request: planRequest(asked), job: job.id, step: "name" });
  if (call.kind === "pending") return { kind: "wait", name: "name", step: { at: "name", record, draft }, runAt: new Date(ctx.clock.now() + KEY_WAIT_MS) };
  if (call.kind === "failed") {
    // The groups stay unnamed and the plan is written: the phone's `complete()` names them on open, as today.
    const written = await writeNamedSkills(draft, record, source, centre);
    return { kind: "continue", name: "name", step: { at: "write", record, draft: written }, generationId: call.id, costPaise: call.costPaise };
  }
  const topics = new Map<number, { chapter: string; skill: string }>();
  for (const t of call.parsed.groups) if (!topics.has(t.groupNo)) topics.set(t.groupNo, { chapter: t.chapter, skill: t.skill });
  const named = await writeNamedSkills(naming(draft, topics), record, source, centre);
  return { kind: "continue", name: "name", step: { at: "write", record, draft: named }, generationId: call.id, costPaise: call.costPaise };
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
        // As the phone: the student's line keeps the group's skill; the next open writes it.
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

async function write(source: PlanRecordSource, centre: string, classId: string, date: string, record: PlanRead, draft: PlanDraft): Promise<StepOutcome> {
  try {
    // The phone may have made the day's plan meanwhile: make_plan would replace it and its material's links.
    const existing = await source.existingPlan(centre, classId, date);
    if (existing) return { kind: "done", name: "write", result: { plan_id: existing, reason: "made" } };
    const planId = await source.makePlan(centre, addingBriefs(draft, new Set(record.briefChapters)));
    return { kind: "done", name: "write", result: { plan_id: planId } };
  } catch (e) {
    return { kind: "fail", name: "write", error: { reason: "write_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
}
