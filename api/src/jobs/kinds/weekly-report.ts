import type { Sender } from "../../alerts/resend.js";
import { log } from "../../log.js";
import type { ReportSource } from "../../report/db.js";
import { reportText } from "../../report/text.js";
import type { JobHandler } from "../types.js";

/** How far back a report may ask: Monday's report reads the week before; Send now this week. */
const WEEKS = 12;

/** The weekly report (D115): one step, `send`. Reads the week asked and the one before it, renders the board's words and
 *  emails them to ALERT_EMAIL through the alerts' sender. No AI call. A failed send fails the step with a retry (the
 *  runner's backoff); a week the figures do not hold fails at once. */
export function weeklyReport(report: { source: ReportSource; sender: Sender; email: string }): JobHandler {
  return {
    async step(job, ctx) {
      const input = job.input as { week_monday?: unknown; so_far?: unknown };
      const monday = typeof input.week_monday === "string" ? input.week_monday : "";
      const weeks = await report.source.figures(WEEKS);
      const at = weeks.findIndex((w) => w.week_monday === monday);
      const week = weeks[at];
      const before = weeks[at + 1];
      if (!week || !before)
        return {
          kind: "fail",
          name: "send",
          error: { reason: "no_week", message: monday },
          retry: false,
        };
      const [reasons, centres, openAlerts] = await Promise.all([
        report.source.reasons(monday),
        report.source.centres(),
        report.source.openAlerts(),
      ]);
      const { subject, text } = reportText({
        week,
        before,
        reasons,
        centres,
        openAlerts,
        soFar: input.so_far === true,
      });
      try {
        await report.sender.send(report.email, subject, text);
      } catch (e) {
        log.error({
          requestId: ctx.requestId,
          job: job.id,
          message: "the weekly report was not sent",
          error: e,
        });
        return {
          kind: "fail",
          name: "send",
          error: { reason: "send_failed" },
          retry: true,
        };
      }
      return {
        kind: "done",
        name: "send",
        result: { sent: true, to: report.email, week: monday },
      };
    },
  };
}
