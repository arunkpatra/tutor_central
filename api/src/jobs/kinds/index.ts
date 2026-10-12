import type { JobHandler, JobKind } from "../types.js";
import { type NoteSource, noteDay } from "./note-day.js";
import { type PlanRecordSource, planJob } from "./plan.js";
import { type ReminderSource, reminderSweep } from "./reminder-sweep.js";
import { sweep } from "./sweep.js";

/** The sources the kinds read, each given by the entry (a test gives what it runs). */
export type Sources = { record?: PlanRecordSource; reminders?: ReminderSource; notes?: NoteSource };

/** The kinds the worker runs. A job of a kind not here fails at once, without a retry. */
export function makeHandlers(sources: Sources = {}): Partial<Record<JobKind, JobHandler>> {
  return {
    sweep,
    ...(sources.record ? { plan: planJob(sources.record) } : {}),
    ...(sources.reminders ? { reminder_sweep: reminderSweep(sources.reminders) } : {}),
    ...(sources.notes ? { note_day: noteDay(sources.notes) } : {}),
  };
}
