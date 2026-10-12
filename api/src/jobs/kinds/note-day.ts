import { makeRequest } from "../../make.js";
import { addDays, weekday } from "../../plan/dates.js";
import type { NotificationRow } from "../../push/db.js";
import { MakeInput } from "../../schemas.js";
import { canDoFacts, isLadderNote, type NoteRecord, noteFacts, type Week } from "../../notes/week.js";
import { recordedCall } from "../call.js";
import type { Job, JobHandler, StepContext, StepOutcome } from "../types.js";

/** A student the note day writes for: their name and their parent's, their class and the parent's language. */
export type NoteStudent = { id: string; name: string; parentName?: string; classLevel?: string; language: string };
/** What the note day reads (NoteDayStore and NoteRecordReader): the centre's name, and each student with a parent's
 *  number, their week (Monday to the note day), their record, and whether their note for the week is kept already. */
export type NoteRead = { centreName: string; students: { student: NoteStudent; week: Week; record: NoteRecord; kept: boolean }[] };
export type NoteSource = {
  read(centre: string, input: { classId: string; date: string } | { studentId: string; week: string }): Promise<NoteRead>;
  /** keep_artefact for a student (no plan): the note kept once by its key; its id. */
  keep(centre: string, student: string, artefact: { kind: string; source: "made"; title: string; content: Record<string, unknown>; generation_id?: string }, key: string): Promise<string>;
  pushUsers(centre: string): Promise<{ user: string; planReady: boolean; notesReady: boolean }[]>;
  notify(centre: string, user: string, rows: NotificationRow[]): Promise<void>;
};

/** The note day's week (NoteDay.week(ending:)): from the Monday of the day before the note day, at most seven days. */
export function weekEnding(noteDay: string): Week {
  const before = addDays(noteDay, -1);
  const monday = addDays(before, -(weekday(before) - 1));
  const earliest = addDays(noteDay, -6);
  return { from: monday > earliest ? monday : earliest, to: noteDay };
}

const WAIT_MS = 30_000;
type Counts = { made: number; held: string[]; kept: number; failed: number };
type Step = { at?: undefined } | ({ at: "note"; i: number; read: NoteRead } & Counts) | ({ at: "notify"; read: NoteRead } & Counts);

const firstName = (name: string) => name.trim().split(/\s+/)[0] ?? name;

/** A note's content as the app keeps it (NoteContent, snake-case keys): the week's Monday is an ISO day, as the app writes
 *  and reads it. The contract's `kept_note` sample is made here, so the app's decoder reads this very shape (ContractTests). */
export function noteContent(parts: { message: string; english?: string; language: string; monday: string; facts: { label: string; fact: string; symbol: string }[]; generationId: string }) {
  return {
    message: parts.message,
    ...(parts.language === "en" || parts.english === undefined ? {} : { english: parts.english }),
    language: parts.language,
    week_monday: parts.monday,
    facts: parts.facts,
    generation_id: parts.generationId,
  };
}

/** The note day's job (plan decision 13): input `{class_id, date}` (every member with a parent's number on the batch's
 *  note day) or `{student_id, week}` (a note the job did not write, asked for from the app). One step per student: the
 *  week's note, or a young student's can-now-do, made as the phone made it on Read (a recorded call naming the student,
 *  so the gate refuses a student without consent, held and never paid) and kept by `note:<student>:<week>`; a note kept
 *  already is not made again. Then, for the batch, Notes ready for each tutor who wants it. */
export function noteDay(source: NoteSource): JobHandler {
  return {
    async step(job, ctx) {
      const raw = job.input as { class_id?: unknown; date?: unknown; student_id?: unknown; week?: unknown };
      const day = (v: unknown) => (typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : null);
      const forBatch = typeof raw.class_id === "string" && day(raw.date) ? { classId: raw.class_id, date: day(raw.date) as string } : null;
      const forStudent = typeof raw.student_id === "string" && day(raw.week) ? { studentId: raw.student_id, week: day(raw.week) as string } : null;
      if (!job.centreId || !(forBatch ?? forStudent)) {
        return { kind: "fail", name: "start", error: { reason: "input", message: "a note day names a batch and a day, or a student and a week" }, retry: false };
      }
      const centre = job.centreId;
      const step = job.step as Step;
      switch (step.at) {
        case undefined: {
          let read: NoteRead;
          try {
            read = await source.read(centre, (forBatch ?? forStudent) as { classId: string; date: string });
          } catch (e) {
            return { kind: "fail", name: "read", error: { reason: "read_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
          }
          const counts: Counts = { made: 0, held: [], kept: 0, failed: 0 };
          if (read.students.length === 0) return { kind: "done", name: "read", result: { made: 0, held: 0, kept: 0, reason: "no_students" } };
          return { kind: "continue", name: "read", step: { at: "note", i: 0, read, ...counts } };
        }
        case "note":
          return note(job, ctx, source, centre, step);
        case "notify":
          return notify(source, centre, forBatch, step, ctx);
      }
    },
  };
}

async function note(job: Job, ctx: StepContext, source: NoteSource, centre: string, step: Extract<Step, { at: "note" }>): Promise<StepOutcome> {
  const { read, i } = step;
  const entry = read.students[i] as NoteRead["students"][number];
  const { student, week, record } = entry;
  // The step's name is the student's place in the read (as the plan's make:<n>): job_steps.step holds 40 characters.
  const name = `note:${i + 1}`;
  const go = (counts: Partial<Counts>, extra: { generationId?: string; costPaise?: number } = {}): StepOutcome => {
    const next = { ...step, ...counts };
    const following: Step = i + 1 < read.students.length ? { ...next, i: i + 1 } : { at: "notify", read, made: next.made, held: next.held, kept: next.kept, failed: next.failed };
    return { kind: "continue", name, step: following, ...extra };
  };
  if (entry.kept) return go({ kept: step.kept + 1 });
  const ladder = isLadderNote(record.student, record.chapters);
  const common = {
    centreId: centre,
    studentId: student.id,
    studentName: student.name,
    ...(student.parentName ? { parentName: student.parentName } : {}),
    centreName: read.centreName,
    language: student.language,
    classLevel: student.classLevel ?? "8",
  };
  let facts: { label: string; fact: string; symbol: string }[];
  let body: unknown;
  if (ladder) {
    const can = canDoFacts(record.chapters, record.skills, week);
    facts = can.rows;
    body = { ...common, kind: "can_do", ladder: { movedUp: can.movedUp, canDo: can.canDo, atHome: can.atHome, next: can.next } };
  } else {
    const f = noteFacts(record, week);
    facts = f.rows;
    // Held to the API's limits as the app holds them (NoteRequest.Week).
    body = {
      ...common,
      kind: "note",
      week: {
        monday: week.from,
        taught: f.taught.slice(0, 6).map((t) => [...t].slice(0, 200).join("")),
        ...(f.right ? { right: [...f.right].slice(0, 120).join("") } : {}),
        practise: f.practise.slice(0, 3).map((t) => [...t].slice(0, 200).join("")),
        coming: f.coming.slice(0, 3).map((t) => [...t].slice(0, 200).join("")),
        ...(f.attendance ? { attendance: [...f.attendance].slice(0, 80).join("") } : {}),
      },
    };
  }
  const parsed = MakeInput.safeParse(body);
  if (!parsed.success) return go({ failed: step.failed + 1 });
  const made = makeRequest(parsed.data);
  const key = `note:${student.id}:${week.from}`;
  const call = await recordedCall<{ message: string; english: string }>(ctx, {
    centre,
    input: parsed.data,
    job: job.id,
    step: name,
    key,
    kind: made.kind,
    request: made.request as never,
    student: made.student,
  });
  if (call.kind === "pending") return { kind: "wait", name, step, runAt: new Date(ctx.clock.now() + WAIT_MS) };
  if (call.kind === "failed") {
    // No consent (never given, or withdrawn while the job ran): held, nothing paid (review focus 4).
    if (call.reason === "student_consent") return go({ held: [...step.held, student.id] });
    return go({ failed: step.failed + 1 }, { generationId: call.id, costPaise: call.costPaise });
  }
  const content = noteContent({ message: call.parsed.message, english: call.parsed.english, language: student.language, monday: week.from, facts, generationId: call.id });
  const title = ladder ? `${firstName(student.name)} can now do` : `${firstName(student.name)}'s week`;
  try {
    await source.keep(centre, student.id, { kind: ladder ? "can_do" : "note", source: "made", title, content, generation_id: call.id }, key);
  } catch (e) {
    return { kind: "fail", name, error: { reason: "keep_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
  return go({ made: step.made + 1 }, { generationId: call.id, costPaise: call.costPaise });
}

async function notify(source: NoteSource, centre: string, batch: { classId: string; date: string } | null, step: Extract<Step, { at: "notify" }>, ctx: StepContext): Promise<StepOutcome> {
  const result = { made: step.made, held: step.held.length, kept: step.kept, failed: step.failed };
  const ready = step.made + step.kept;
  if (batch && ready > 0) {
    const row: NotificationRow = {
      kind: "notes_ready",
      key: `notes_ready:${batch.classId}:${batch.date}`,
      due_at: new Date(ctx.clock.now()).toISOString(),
      title: ready === 1 ? "1 weekly note is ready" : `${ready} weekly notes are ready`,
      body: "For the note day. Read each as the parent will, then send.",
      link: "tutorcentral://today?note-day",
    };
    try {
      for (const user of await source.pushUsers(centre)) if (user.notesReady) await source.notify(centre, user.user, [row]);
    } catch (e) {
      return { kind: "fail", name: "notify", error: { reason: "notify_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
    }
  }
  return { kind: "done", name: "notify", result };
}
