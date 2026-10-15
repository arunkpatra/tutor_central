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
  never: "never",
} as const;

/** The lines as a form (P22-Alerts-Lines): the four numbers, Save, the last change. */
export const LINES_FORM = {
  changed: (when: string, by: string) => `last changed ${when} by ${by} · written to the audit`,
  costDay: "cost_day · ₹ a centre in a day",
  errorRate: "error_rate · % of an hour’s requests",
  errorMin: "error_rate · at least this many requests",
  stuck: "job_stuck · minutes with no step",
  save: "Save the lines",
  saveNote: "The next check reads the new lines (within ten minutes).",
  failed: "job_failed",
  failedNote:
    "has no line: any job failed after its last try is raised. Each alert is raised once, emailed to you and pushed to your iPhone.",
  bad: "Whole numbers, 0 or more (stuck minutes 1 or more); the rate may have a decimal, up to 100",
  you: "you",
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
    "set_model",
    "set_alert_lines",
    "set_allowance",
    "run_evals",
    "send_report",
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
  const t = row.target;
  if (row.action === "set_alert_lines" && typeof t.cost_day_paise === "number") {
    return `cost_day ${rupees(t.cost_day_paise)} · error_rate ${t.error_rate_pct}% of ${t.error_rate_min_requests} · job_stuck ${t.stuck_minutes} min`;
  }
  const kind = typeof row.target.kind === "string" ? row.target.kind : null;
  if (row.action === "set_model" && kind) {
    return [kind, t.step, t.enabled === false ? "off" : null].filter(Boolean).join(" · ");
  }
  const step = typeof row.target.step === "string" ? row.target.step : null;
  if (row.action === "retry_job" || row.action === "cancel_job") {
    return (
      [kind, row.subject, step && row.action === "retry_job" ? `from ${step}` : null].filter(Boolean).join(" · ") || "—"
    );
  }
  return kind ?? "—";
}
