import type { Tone } from "@/components/parts";
import type { JobRow, JobStep } from "@/lib/data/types";
import { rupees, seconds, short, shortId, time } from "@/lib/format";
import { family } from "./models";

/** A job's state as its chip (P19-Jobs, P19-Centre): done in ok, waiting and running in due, failed in overdue. */
export function stateChip(job: JobRow, withMade: boolean): { tone: Tone; text: string } {
  switch (job.state) {
    case "done": {
      const made = withMade && job.made !== null ? ` · ${job.made} of ${job.made + (job.not_made ?? 0)} made` : "";
      return { tone: "ok", text: `done${made}` };
    }
    case "failed":
      return { tone: "overdue", text: "failed" };
    case "running":
      return { tone: "due", text: job.step ? `running · ${job.step}` : "running" };
    case "waiting":
    case "queued":
      return { tone: "due", text: "waiting" };
    case "cancelled":
      return { tone: "neutral", text: "cancelled" };
  }
}

/** When it ended (or will run): "05:31 · 56 s", "05:33 · 3 tries", "runs at 16:00", "since 07:02". */
export function finished(job: JobRow, now: Date): string {
  if (job.state === "waiting" || job.state === "queued") return `runs at ${time(job.run_at)}`;
  if (job.state === "running") return job.started_at ? `since ${time(job.started_at)}` : "running";
  if (!job.finished_at) return "—";
  const at = short(job.finished_at, now);
  if (job.state === "failed") return `${at} · ${job.attempts} ${job.attempts === 1 ? "try" : "tries"}`;
  if (job.state === "done" && job.seconds !== null && at.length <= 5) return `${at} · ${seconds(job.seconds)}`;
  return at;
}

/** The jobs page's words (P19-Jobs). */
export const JOBS = {
  title: "Jobs",
  lead: "Every job and its steps: queued, running, waiting, done, failed, cancelled. A failed job can be retried from its failed step; a queued or running one cancelled. Both are written to the audit.",
  state: "State",
  states: {
    queued: "queued",
    running: "running",
    waiting: "waiting",
    done: "done",
    failed: "failed",
    cancelled: "cancelled",
  },
  kind: "Kind",
  kinds: ["plan", "note_day", "pdf", "export", "reminder_sweep", "sweep", "alerts", "artefact"],
  centre: "Centre",
  day: "Day",
  days: { today: "Today", yesterday: "Yesterday", all: "All days" },
  all: "All",
  tiles: {
    today: (day: string) => (day === "all" ? "jobs" : day === "today" ? "jobs today" : "jobs yesterday"),
    failed: "failed",
    running: "running",
    waiting: "waiting",
  },
  list: (day: string) => `${day === "all" ? "Every day" : day === "today" ? "Today" : "Yesterday"}, newest first`,
  listLead: (open: { state: string; kind: string } | null) =>
    open
      ? `The ${open.state} ${open.kind} is open: its steps${open.state === "failed" ? ", the error, Retry and Cancel" : ""}.`
      : "A job opens with its steps; a failed one can be retried, a live one cancelled.",
  head: {
    kind: "Kind",
    centre: "Centre",
    subject: "Subject",
    state: "State",
    when: "When",
    tries: "Tries",
    cost: "Cost",
  },
  stepHead: { step: "Step", try: "Try", state: "State", note: "Note", cost: "Cost" },
  error: "Error: ",
  retry: "Retry from the failed step",
  cancel: "Cancel",
  done: {
    retried: "Queued again",
    cancelled: "Cancelled",
    refused: "Nothing changed: the job is no longer in that state",
  },
  byTutor: (at: string) => `by the tutor at ${at}`,
  at: (at: string) => `at ${at}`,
} as const;

/** When a job ran, for the list: "05:30 to 05:38", "05:31", "10:05 · 1 s", "runs at 16:00", "since 07:02". */
export function span(job: JobRow, now: Date): string {
  if (job.state === "waiting" || job.state === "queued") return `runs at ${time(job.run_at)}`;
  if (job.state === "running") return job.started_at ? `since ${time(job.started_at)}` : "running";
  if (job.state === "cancelled")
    return job.finished_at ? (job.by_member ? JOBS.byTutor : JOBS.at)(time(job.finished_at)) : "cancelled";
  if (!job.started_at || !job.finished_at) return job.finished_at ? short(job.finished_at, now) : "—";
  const start = short(job.started_at, now);
  const end = short(job.finished_at, now);
  if (start !== end) return start.length <= 5 && end.length <= 5 ? `${start} to ${end}` : end;
  return job.seconds !== null && job.seconds > 0 && job.seconds < 60 ? `${end} · ${seconds(job.seconds)}` : end;
}

/** A step's note (P19-Jobs): the call's kind, model and outcome for a paid step; the time and seconds for the rest. */
export function stepNote(step: JobStep): string {
  const c = step.call;
  if (c) {
    const head = `${c.kind} · ${family(c.model)}`;
    if (c.replayed) return `${head} · replayed`;
    if (c.status === "ok") return `${head} · ${rupees(step.cost_paise)}`;
    const why = c.error_reason ?? "failed";
    return step.attempt > 1 ? `${head} · ${why} on ${step.attempt} tries` : `${head} · ${why}`;
  }
  if (step.error?.reason)
    return step.error.message ? `${step.error.reason} · ${step.error.message}` : step.error.reason;
  return `${time(step.created_at, true)} · ${seconds(step.seconds)}`;
}

/** A job's input in one line, ids cut: "{class_id: 9e3d…0001, date: 2026-10-13}". */
export function inputLine(input: { [key: string]: unknown }): string {
  const parts = Object.entries(input).map(([k, v]) => `${k}: ${typeof v === "string" ? cutIds(v) : JSON.stringify(v)}`);
  return `{${parts.join(", ")}}`;
}

/** Every UUID in a text cut as the boards cut it. */
export function cutIds(text: string): string {
  return text.replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, (id) => shortId(id));
}
