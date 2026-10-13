import { rupees } from "@/lib/format";

/** The alerts' and the audit's words (P19-Alerts, P19-Audit). */
export const ALERTS = {
  title: "Alerts",
  lead: "What crossed a line: a failed job, a centre’s cost in a day, the error rate, a stuck job. Acknowledging one is written to the audit.",
  show: "Show",
  shows: { "open-first": "Open first", newest: "Newest" },
  tiles: {
    open: "open",
    acknowledgedWeek: "acknowledged this week",
    lastRaised: "last raised",
    how: "Email + push",
    howLabel: "how each alert reaches you",
  },
  head: { alert: "Alert", centre: "Centre", value: "Value · line", raised: "Raised", act: "" },
  acknowledge: "Acknowledge",
  acknowledged: (when: string) => `acknowledged · ${when}`,
  lines: "The lines, checked every ten minutes by the alerts job",
  line: [
    ["job_failed", "any job failed after its last try"],
    ["cost_day", "a centre over ₹60 in a day"],
    ["error_rate", "answers over 400 above 5% of an hour’s requests (at least 20)"],
    ["job_stuck", "a job running over 10 minutes"],
  ],
  linesNote: "Each alert is raised once, emailed to you and pushed to your iPhone. The lines change in Phase 22.",
  never: "never",
} as const;

export const AUDIT = {
  title: "Audit",
  lead: "Who did what, to which centre, when and from where: every sign-in, refusal, open of a record, retry, cancel and acknowledgement. Nothing here can be edited or deleted from the portal.",
  who: "Who",
  everyone: "Everyone",
  you: "you",
  action: "Action",
  actions: [
    "sign_in",
    "sign_out",
    "refused",
    "enrol_totp",
    "open_record",
    "retry_job",
    "cancel_job",
    "acknowledge_alert",
  ],
  all: "All",
  days: "Days",
  dayChoices: ["7", "30", "90"],
  list: "Newest first",
  head: { when: "When", who: "Who", action: "Action", centre: "Centre", detail: "Reason or target", from: "From" },
} as const;

/** An alert's value against its line, in its own unit (D95): rupees, a percentage, minutes, a count. */
export function valueLine(kind: string, value: number | null, threshold: number | null): string {
  if (value === null || threshold === null) return "—";
  switch (kind) {
    case "cost_day":
      return `${rupees(value)} · over ${rupees(threshold)}`;
    case "error_rate":
      return `${value}% · over ${threshold}%`;
    case "job_stuck":
      return `${value} min · over ${threshold}`;
    default:
      return `${value} · over ${threshold}`;
  }
}

/** An audit row's reason, or what it acted on: "plan · Class 8 Science · 13 Oct · from make:2". */
export function auditDetail(row: {
  action: string;
  reason: string | null;
  target: { [key: string]: unknown };
  subject: string | null;
}): string {
  if (row.reason) return row.reason;
  const kind = typeof row.target.kind === "string" ? row.target.kind : null;
  const step = typeof row.target.step === "string" ? row.target.step : null;
  if (row.action === "retry_job" || row.action === "cancel_job") {
    return (
      [kind, row.subject, step && row.action === "retry_job" ? `from ${step}` : null].filter(Boolean).join(" · ") || "—"
    );
  }
  return kind ?? "—";
}
