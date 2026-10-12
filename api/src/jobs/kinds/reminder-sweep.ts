import { istDay } from "../../plan/dates.js";
import type { NotificationRow } from "../../push/db.js";
import { notificationsFor, type ReminderClass, type ReminderEvent } from "../../reminders/planner.js";
import type { ReminderSettings } from "../../reminders/settings.js";
import type { JobHandler } from "../types.js";

/** What the reminder plan reads for a centre: its active batches with their member counts, the next two weeks' events,
 *  this month's fees still due, and each member who can be reached (a live token) with their own settings. */
export type ReminderRead = {
  classes: ReminderClass[];
  memberCounts: Record<string, number>;
  events: ReminderEvent[];
  dueFees: { count: number; total: number } | null;
  users: { user: string; settings: ReminderSettings }[];
  today: string;
};
export type ReminderSource = {
  read(centre: string, today: string): Promise<ReminderRead>;
  /** `replace_notifications` for one user: the count written. */
  replace(centre: string, user: string, kinds: string[], from: string, rows: NotificationRow[]): Promise<number>;
};

export const REMINDER_KINDS = ["class", "event", "fees"];

/** The `reminder_sweep` job (plan decision 7): one step, `plan`. Each member with a live token gets the next 26 hours of
 *  their reminders written to the outbox by their own settings, replacing their unsent rows of those kinds from now in
 *  one transaction (a batch moved at 16:00 loses its 16:45 reminder and gets its new one). The centre is the job's own. */
export function reminderSweep(source: ReminderSource): JobHandler {
  return {
    async step(job, ctx) {
      const centre = job.centreId;
      if (!centre) return { kind: "fail", name: "plan", error: { reason: "no_centre" }, retry: false };
      const now = new Date(ctx.clock.now());
      const read = await source.read(centre, istDay(now));
      let rows = 0;
      for (const { user, settings } of read.users) {
        const written = notificationsFor({ ...read, settings }, now.toISOString());
        await source.replace(centre, user, REMINDER_KINDS, now.toISOString(), written);
        rows += written.length;
      }
      return { kind: "done", name: "plan", result: { users: read.users.length, rows } };
    },
  };
}
