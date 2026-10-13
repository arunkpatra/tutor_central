import { expect, test } from "bun:test";
import { alertsFor, type Facts, LINES } from "../src/alerts/lines.js";

const now = new Date("2026-10-13T05:12:00Z"); // 10:42 in India
const none: Facts = { failedJobs: [], costToday: [], requestsHour: { total: 0, errors: 0 }, stuckJobs: [] };

test("no facts, no alerts", () => expect(alertsFor(none, now)).toEqual([]));

test("a failed job is one alert keyed by the job, its kind in words", () => {
  expect(alertsFor({ ...none, failedJobs: [{ id: "j0", kind: "export", centreId: null }] }, now)[0]?.message).toBe("an export job failed after its last try");
  const alerts = alertsFor({ ...none, failedJobs: [{ id: "j1", kind: "plan", centreId: "c1" }] }, now);
  expect(alerts).toEqual([{ key: "job_failed:j1", kind: "job_failed", centreId: "c1", threshold: 0, value: 1, message: "a plan job failed after its last try" }]);
});

test("a centre at ₹60.00 is not over the line, ₹60.01 is, keyed by the centre and India's day", () => {
  expect(alertsFor({ ...none, costToday: [{ centreId: "c1", paise: LINES.costDayPaise }] }, now)).toEqual([]);
  const [alert] = alertsFor({ ...none, costToday: [{ centreId: "c1", paise: 7200 }] }, now);
  expect(alert).toEqual({ key: "cost_day:c1:2026-10-13", kind: "cost_day", centreId: "c1", threshold: 6000, value: 7200, message: "a centre’s cost today over the line: ₹72, over ₹60" });
  // 23:30 in India on the 13th is 18:00 UTC: still the 13th's line.
  expect(alertsFor({ ...none, costToday: [{ centreId: "c1", paise: 6001 }] }, new Date("2026-10-13T18:00:00Z"))[0]?.key).toBe("cost_day:c1:2026-10-13");
});

test("the error rate needs 20 requests, and is keyed by the hour", () => {
  expect(alertsFor({ ...none, requestsHour: { total: 19, errors: 5 } }, now)).toEqual([]);
  expect(alertsFor({ ...none, requestsHour: { total: 20, errors: 1 } }, now)).toEqual([]);
  const [alert] = alertsFor({ ...none, requestsHour: { total: 20, errors: 2 } }, now);
  expect(alert).toEqual({ key: "error_rate:2026-10-13T05", kind: "error_rate", centreId: null, threshold: 5, value: 10, message: "errors over 5% of requests in an hour: 10%" });
});

test("a job running 9 minutes is not stuck, 11 is", () => {
  const at = (minutes: number) => new Date(now.getTime() - minutes * 60_000).toISOString();
  expect(alertsFor({ ...none, stuckJobs: [{ id: "j2", kind: "plan", centreId: "c1", startedAt: at(9) }] }, now)).toEqual([]);
  const [alert] = alertsFor({ ...none, stuckJobs: [{ id: "j2", kind: "plan", centreId: "c1", startedAt: at(11) }] }, now);
  expect(alert).toEqual({ key: "job_stuck:j2", kind: "job_stuck", centreId: "c1", threshold: 10, value: 11, message: "a job running over 10 minutes: plan, 11 min" });
});
