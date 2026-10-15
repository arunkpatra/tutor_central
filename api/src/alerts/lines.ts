/** The alerts job's four lines (D95): what `alert_facts` (0046) answers, compared; each alert keyed so it is raised once.
 *  The numbers are the portal's (`alert_lines`, 0066, D113), read by the job each run. Pure: facts and lines in, alerts out. */
export type Facts = {
  failedJobs: { id: string; kind: string; centreId: string | null; finishedAt: string }[];
  costToday: { centreId: string; paise: number }[];
  requestsHour: { total: number; errors: number };
  /** Running with no progress: `since` is the last step's time, or the start. */
  stuckJobs: { id: string; kind: string; centreId: string | null; since: string }[];
};

export type AlertKind = "job_failed" | "cost_day" | "error_rate" | "job_stuck";
/** An alert as raised: value and threshold in the line's own unit (paise, a percentage, minutes, a count). */
export type Alert = { key: string; kind: AlertKind; centreId: string | null; threshold: number; value: number; message: string };

/** A cost in paise for India's day, a percentage of an hour's requests with their minimum, minutes with no step. */
export type Lines = { costDayPaise: number; errorRatePct: number; errorRateMinRequests: number; stuckMinutes: number };
/** 0066's seed: a test's lines and a source with no table row's. */
export const DEFAULT_LINES: Lines = { costDayPaise: 6000, errorRatePct: 5, errorRateMinRequests: 20, stuckMinutes: 10 };

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

export function alertsFor(facts: Facts, now: Date, lines: Lines = DEFAULT_LINES): Alert[] {
  const alerts: Alert[] = [];
  for (const j of facts.failedJobs) {
    // Keyed by the failure (to the minute), so a job retried and failing again is raised again.
    alerts.push({ key: `job_failed:${j.id}:${j.finishedAt.slice(0, 16)}`, kind: "job_failed", centreId: j.centreId, threshold: 0, value: 1, message: `${aJob(j.kind)} failed after its last try` });
  }
  for (const c of facts.costToday) {
    if (c.paise <= lines.costDayPaise) continue;
    alerts.push({
      key: `cost_day:${c.centreId}:${istDay(now)}`,
      kind: "cost_day",
      centreId: c.centreId,
      threshold: lines.costDayPaise,
      value: c.paise,
      message: `a centre’s cost today over the line: ${rupees(c.paise)}, over ${rupees(lines.costDayPaise)}`,
    });
  }
  const { total, errors } = facts.requestsHour;
  const pct = total > 0 ? Math.round((errors / total) * 1000) / 10 : 0;
  if (total >= lines.errorRateMinRequests && pct > lines.errorRatePct) {
    alerts.push({
      key: `error_rate:${now.toISOString().slice(0, 13)}`,
      kind: "error_rate",
      centreId: null,
      threshold: lines.errorRatePct,
      value: pct,
      message: `errors over ${lines.errorRatePct}% of requests in an hour: ${pct}%`,
    });
  }
  for (const j of facts.stuckJobs) {
    const minutes = Math.floor((now.getTime() - Date.parse(j.since)) / 60_000);
    if (minutes <= lines.stuckMinutes) continue;
    alerts.push({
      key: `job_stuck:${j.id}`,
      kind: "job_stuck",
      centreId: j.centreId,
      threshold: lines.stuckMinutes,
      value: minutes,
      message: `a job running over ${lines.stuckMinutes} minutes: ${j.kind}, ${minutes} min`,
    });
  }
  return alerts;
}
