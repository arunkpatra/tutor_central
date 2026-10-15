import { expect, test } from "bun:test";
import { fakeSender } from "../src/alerts/resend.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { weeklyReport } from "../src/jobs/kinds/weekly-report.js";
import type { Job, StepContext } from "../src/jobs/types.js";
import { fakeReportSource } from "../src/report/db.js";

const job = (input: Record<string, unknown>): Job => ({
  id: "r1",
  centreId: null,
  kind: "weekly_report",
  attempts: 1,
  step: {},
  input,
  leaseUntil: "",
});
function context(): StepContext {
  const clock = fakeClock();
  return {
    db: fakeDb(),
    jobs: fakeJobsDb(clock),
    claude: fakeClaude({}),
    clock,
    requestId: "r",
    worker: "w",
  };
}
const source = () =>
  fakeReportSource({
    weeks: ["2026-10-13", "2026-10-06", "2026-09-29"].map((m, i) => ({
      week_monday: m,
      so_far: i === 0,
      tutors_active: 3 - i,
      closes: 10 - i,
      plans_made: 0,
      plans_followed: 0,
      notes_sent: 0,
      made: 0,
      again: 0,
      make: 0,
      consent_given: 0,
      cost_paise: 0,
      per_active_tutor_paise: 0,
    })),
    reasons: { again: [], edits: 0, made: 0, notes: 0 },
    centres: { total: 4, inUse: 2 },
    openAlerts: 1,
  });

test("the job sends one email of the week asked, with the week before, and records it", async () => {
  const sender = fakeSender();
  const outcome = await weeklyReport({
    source: source(),
    sender,
    email: "you@example.com",
  }).step(job({ week_monday: "2026-10-06" }), context());
  expect(outcome).toEqual({
    kind: "done",
    name: "send",
    result: { sent: true, to: "you@example.com", week: "2026-10-06" },
  });
  expect(sender.sent).toHaveLength(1);
  expect(sender.sent[0]?.subject).toBe("Tutor Central, the week of 6 to 12 October");
  expect(sender.sent[0]?.text).toContain("Tutors active: 2 (1)");
  expect(sender.sent[0]?.text).toContain("Centres: 4 · in use: 2 · open alerts: 1");
});

test("this week so far is the first week with the one before it", async () => {
  const sender = fakeSender();
  await weeklyReport({
    source: source(),
    sender,
    email: "you@example.com",
  }).step(job({ week_monday: "2026-10-13", so_far: true }), context());
  expect(sender.sent[0]?.subject).toBe("Tutor Central, the week of 13 October so far");
  expect(sender.sent[0]?.text).toContain("Tutors active: 3 (2)");
});

test("a send that fails retries; a week the figures do not hold fails without one", async () => {
  const failing = await weeklyReport({
    source: source(),
    sender: fakeSender({ fail: true }),
    email: "you@example.com",
  }).step(job({ week_monday: "2026-10-06" }), context());
  expect(failing).toMatchObject({
    kind: "fail",
    name: "send",
    retry: true,
    error: { reason: "send_failed" },
  });
  const unknown = await weeklyReport({
    source: source(),
    sender: fakeSender(),
    email: "you@example.com",
  }).step(job({ week_monday: "2025-01-06" }), context());
  expect(unknown).toMatchObject({
    kind: "fail",
    retry: false,
    error: { reason: "no_week" },
  });
});
