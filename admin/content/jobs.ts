import type { Tone } from "@/components/parts";
import type { JobRow } from "@/lib/data/types";
import { seconds, short, time } from "@/lib/format";

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
