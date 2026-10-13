import type { AlertsSource } from "../../alerts/db.js";
import { alertsFor } from "../../alerts/lines.js";
import type { Sender } from "../../alerts/resend.js";
import { log } from "../../log.js";
import type { JobHandler } from "../types.js";

/** The portal's alerts page, named in the email. */
export const ALERTS_PAGE = "https://admin.tutorcentral.in/alerts";
/** The push's title: plain words on the owner's iPhone (D41's spirit). */
export const ALERT_TITLE = "Tutor Central needs a look";

/** The alerts job (D95), one step each ten minutes: the facts, the four lines, each alert raised once by its key; a new
 *  one is emailed to ALERT_EMAIL and pushed to each admin's tutor account. An email or a push that fails is logged and the
 *  step still ends done: the alert row stands (Phase 22 retries). */
export function alertsJob(source: AlertsSource, sender: Sender, alertEmail: string): JobHandler {
  return {
    async step(job, ctx) {
      const now = new Date(ctx.clock.now());
      const alerts = alertsFor(await source.facts(now), now);
      const targets = await source.targets();
      let raised = 0;
      let emailed = 0;
      let pushed = 0;
      for (const alert of alerts) {
        if (!(await source.raise(alert))) continue;
        raised += 1;
        try {
          await sender.send(alertEmail, `Tutor Central alert: ${alert.kind}`, [alert.message, alert.centreId ? `Centre: ${alert.centreId}` : null, ALERTS_PAGE].filter(Boolean).join("\n\n"));
          emailed += 1;
        } catch (e) {
          log.error({ requestId: ctx.requestId, job: job.id, message: "an alert email was not sent", alert: alert.key, error: e });
        }
        // A push that cannot be written is logged like a failed email: the alert row stands, and a retry of the step
        // would find it raised and push nothing (the review's R-db-5).
        for (const t of targets) {
          try {
            await source.notify(t.centre, t.user, [{ kind: "alert", key: `alert:${alert.key}`, due_at: now.toISOString(), title: ALERT_TITLE, body: alert.message }], now);
            pushed += 1;
          } catch (e) {
            log.error({ requestId: ctx.requestId, job: job.id, message: "an alert push was not written", alert: alert.key, error: e });
          }
        }
      }
      return { kind: "done", name: "check", result: { checked: alerts.length, raised, emailed, pushed } };
    },
  };
}
