import type { AlertsSource } from "../../alerts/db.js";
import type { Sender } from "../../alerts/resend.js";
import type { JobHandler, JobKind } from "../types.js";
import { alertsJob } from "./alerts.js";
import { evalRun } from "./eval-run.js";
import { type ExportSource, exportJob } from "./export.js";
import { type NoteSource, noteDay } from "./note-day.js";
import { type PdfSource, pdfJob } from "./pdf.js";
import { type PlanRecordSource, planJob } from "./plan.js";
import { type ReminderSource, reminderSweep } from "./reminder-sweep.js";
import { makeSweep, type SweepSource } from "./sweep.js";

/** The sources the kinds read, each given by the entry (a test gives what it runs). */
export type Sources = {
  record?: PlanRecordSource;
  reminders?: ReminderSource;
  notes?: NoteSource;
  files?: PdfSource;
  exports?: ExportSource;
  storage?: SweepSource;
  alerts?: { source: AlertsSource; sender: Sender; email: string };
  /** The nightly evals (D101): their calls are the Smoke centre's. */
  evals?: { smokeCentre: string };
};

/** The kinds the worker runs. A job of a kind not here fails at once, without a retry. */
export function makeHandlers(sources: Sources = {}): Partial<Record<JobKind, JobHandler>> {
  return {
    sweep: makeSweep(sources.storage),
    ...(sources.record ? { plan: planJob(sources.record) } : {}),
    ...(sources.reminders ? { reminder_sweep: reminderSweep(sources.reminders) } : {}),
    ...(sources.notes ? { note_day: noteDay(sources.notes) } : {}),
    ...(sources.files ? { pdf: pdfJob(sources.files) } : {}),
    ...(sources.exports ? { export: exportJob(sources.exports) } : {}),
    ...(sources.alerts ? { alerts: alertsJob(sources.alerts.source, sources.alerts.sender, sources.alerts.email) } : {}),
    ...(sources.evals ? { eval_run: evalRun(sources.evals) } : {}),
  };
}
