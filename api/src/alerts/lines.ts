/** The alerts job's four lines (D95): what `alert_facts` (0046) answers, compared; each alert keyed so it is raised once.
 *  The numbers are constants until Phase 22 moves them to the portal. Pure: facts in, alerts out. */
export type Facts = {
  failedJobs: { id: string; kind: string; centreId: string | null }[];
  costToday: { centreId: string; paise: number }[];
  requestsHour: { total: number; errors: number };
  stuckJobs: { id: string; kind: string; centreId: string | null; startedAt: string }[];
};

export type AlertKind = "job_failed" | "cost_day" | "error_rate" | "job_stuck";
/** An alert as raised: value and threshold in the line's own unit (paise, a percentage, minutes, a count). */
export type Alert = { key: string; kind: AlertKind; centreId: string | null; threshold: number; value: number; message: string };

export const LINES = { costDayPaise: 6000, errorRatePct: 5, errorRateMinRequests: 20, stuckMinutes: 10 } as const;

/** ₹72, ₹60, ₹0.50: rupees as the portal writes them. */
function rupees(paise: number): string {
  const r = paise / 100;
  return r < 10 ? `₹${r.toFixed(2)}` : `₹${Math.round(r)}`;
}

/** India's calendar day, for the cost line's key. */
function istDay(at: Date): string {
  return at.toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });
}

/** "a plan job", "an export job". */
function aJob(kind: string): string {
  return `${/^[aeiou]/.test(kind) ? "an" : "a"} ${kind} job`;
}

export function alertsFor(facts: Facts, now: Date): Alert[] {
  const alerts: Alert[] = [];
  for (const j of facts.failedJobs) {
    alerts.push({ key: `job_failed:${j.id}`, kind: "job_failed", centreId: j.centreId, threshold: 0, value: 1, message: `${aJob(j.kind)} failed after its last try` });
  }
  for (const c of facts.costToday) {
    if (c.paise <= LINES.costDayPaise) continue;
    alerts.push({
      key: `cost_day:${c.centreId}:${istDay(now)}`,
      kind: "cost_day",
      centreId: c.centreId,
      threshold: LINES.costDayPaise,
      value: c.paise,
      message: `a centre’s cost today over the line: ${rupees(c.paise)}, over ${rupees(LINES.costDayPaise)}`,
    });
  }
  const { total, errors } = facts.requestsHour;
  const pct = total > 0 ? Math.round((errors / total) * 1000) / 10 : 0;
  if (total >= LINES.errorRateMinRequests && pct > LINES.errorRatePct) {
    alerts.push({
      key: `error_rate:${now.toISOString().slice(0, 13)}`,
      kind: "error_rate",
      centreId: null,
      threshold: LINES.errorRatePct,
      value: pct,
      message: `errors over ${LINES.errorRatePct}% of requests in an hour: ${pct}%`,
    });
  }
  for (const j of facts.stuckJobs) {
    const minutes = Math.floor((now.getTime() - Date.parse(j.startedAt)) / 60_000);
    if (minutes <= LINES.stuckMinutes) continue;
    alerts.push({
      key: `job_stuck:${j.id}`,
      kind: "job_stuck",
      centreId: j.centreId,
      threshold: LINES.stuckMinutes,
      value: minutes,
      message: `a job running over ${LINES.stuckMinutes} minutes: ${j.kind}, ${minutes} min`,
    });
  }
  return alerts;
}
