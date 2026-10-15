import { expect, test } from "bun:test";
import { fakeAlertsSource } from "../src/alerts/db.js";
import type { Facts } from "../src/alerts/lines.js";
import { fakeSender } from "../src/alerts/resend.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { alertsJob } from "../src/jobs/kinds/alerts.js";
import type { Job, StepContext } from "../src/jobs/types.js";

const none: Facts = { failedJobs: [], costToday: [], requestsHour: { total: 0, errors: 0 }, stuckJobs: [] };
const job: Job = { id: "a1", centreId: null, kind: "alerts", attempts: 1, step: {}, input: {}, leaseUntil: "" };
function context(): StepContext {
  const clock = fakeClock();
  return { db: fakeDb(), jobs: fakeJobsDb(clock), claude: fakeClaude({}), clock, requestId: "r", worker: "w" };
}
const targets = [{ user: "owner", centre: "c-owner" }];

test("a new alert is raised, emailed to ALERT_EMAIL and pushed to each target", async () => {
  const source = fakeAlertsSource({ ...none, failedJobs: [{ id: "j1", kind: "plan", centreId: "c1", finishedAt: "2026-10-13T05:11:30Z" }] }, targets);
  const sender = fakeSender();
  const outcome = await alertsJob(source, sender, "you@example.com").step(job, context());
  expect(outcome).toMatchObject({ kind: "done", name: "check", result: { checked: 1, raised: 1, emailed: 1, pushed: 1 } });
  expect(source.raised.map((a) => a.key)).toEqual(["job_failed:j1:2026-10-13T05:11"]);
  expect(sender.sent).toHaveLength(1);
  expect(sender.sent[0]).toMatchObject({ to: "you@example.com", subject: "Tutor Central alert: job_failed" });
  expect(sender.sent[0]?.text).toContain("a plan job failed after its last try");
  expect(sender.sent[0]?.text).toContain("https://admin.tutorcentral.in/alerts");
  expect(source.notified).toHaveLength(1);
  expect(source.notified[0]).toMatchObject({ centre: "c-owner", user: "owner" });
  expect(source.notified[0]?.rows[0]).toMatchObject({ kind: "alert", key: "alert:job_failed:j1:2026-10-13T05:11", title: "Tutor Central needs a look", body: "a plan job failed after its last try" });
});

test("the same failed job raises one alert across two runs: no second email, no second push", async () => {
  const source = fakeAlertsSource({ ...none, failedJobs: [{ id: "j1", kind: "plan", centreId: "c1", finishedAt: "2026-10-13T05:11:30Z" }] }, targets);
  const sender = fakeSender();
  const handler = alertsJob(source, sender, "you@example.com");
  await handler.step(job, context());
  const second = await handler.step(job, context());
  expect(second).toMatchObject({ result: { checked: 1, raised: 0, emailed: 0, pushed: 0 } });
  expect(sender.sent).toHaveLength(1);
  expect(source.notified).toHaveLength(1);
});

test("the error rate alert is keyed by the hour: two runs in one hour raise one, the next hour another", async () => {
  const source = fakeAlertsSource({ ...none, requestsHour: { total: 40, errors: 4 } }, targets);
  const sender = fakeSender();
  const handler = alertsJob(source, sender, "you@example.com");
  const ctx = context();
  ctx.clock = fakeClock(Date.parse("2026-10-13T05:10:00Z"));
  await handler.step(job, ctx);
  ctx.clock = fakeClock(Date.parse("2026-10-13T05:50:00Z"));
  await handler.step(job, ctx);
  ctx.clock = fakeClock(Date.parse("2026-10-13T06:10:00Z"));
  await handler.step(job, ctx);
  expect(source.raised.map((a) => a.key)).toEqual(["error_rate:2026-10-13T05", "error_rate:2026-10-13T06"]);
  expect(sender.sent).toHaveLength(2);
});

test("a failing email leaves the step done: the alert stands and the push went", async () => {
  const source = fakeAlertsSource({ ...none, failedJobs: [{ id: "j1", kind: "plan", centreId: "c1", finishedAt: "2026-10-13T05:11:30Z" }] }, targets);
  const sender = fakeSender({ fail: true });
  const outcome = await alertsJob(source, sender, "you@example.com").step(job, context());
  expect(outcome).toMatchObject({ kind: "done", result: { raised: 1, emailed: 0, pushed: 1 } });
  expect(source.notified).toHaveLength(1);
});

test("a push that cannot be written is logged; the step ends done and the next alert is still raised (R-db-5)", async () => {
  const source = fakeAlertsSource(
    { ...none, failedJobs: [{ id: "j1", kind: "plan", centreId: "c1", finishedAt: "2026-10-13T05:11:30Z" }, { id: "j2", kind: "pdf", centreId: "c1", finishedAt: "2026-10-13T05:12:00Z" }] },
    targets,
  );
  source.notify = async () => {
    throw new Error("the outbox could not be written");
  };
  const outcome = await alertsJob(source, fakeSender(), "you@example.com").step(job, context());
  expect(outcome).toMatchObject({ kind: "done", result: { raised: 2, emailed: 2, pushed: 0 } });
});

test("the lines come from the source: a centre at ₹72 is quiet under a ₹90 line, and loud under the seed's ₹60", async () => {
  const facts = { ...none, costToday: [{ centreId: "c1", paise: 7200 }] };
  const quiet = fakeAlertsSource(facts, targets, { costDayPaise: 9000, errorRatePct: 5, errorRateMinRequests: 20, stuckMinutes: 10 });
  expect(await alertsJob(quiet, fakeSender(), "you@example.com").step(job, context())).toMatchObject({ result: { checked: 0, raised: 0 } });
  const loud = fakeAlertsSource(facts, targets);
  expect(await alertsJob(loud, fakeSender(), "you@example.com").step(job, context())).toMatchObject({ result: { checked: 1, raised: 1 } });
  expect(loud.raised[0]?.message).toBe("a centre’s cost today over the line: ₹72, over ₹60");
});
