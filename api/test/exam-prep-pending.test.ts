import { expect, test } from "bun:test";
import { makeHandlers } from "../src/jobs/kinds/index.js";
import type { Job, StepContext } from "../src/jobs/types.js";

// Migration 0057 queues an exam's job (D106) a deploy before its handler (Task 6): the job waits, never fails (a failed
// job alerts the owner), and the handler that ships takes it from its first step.
test("an exam's job waits an hour, its step untouched, while its handler is not yet here", async () => {
  const handler = makeHandlers().exam_prep;
  const job: Job = { id: "j", centreId: "c", kind: "exam_prep", attempts: 1, step: {}, input: { item_id: "i" }, leaseUntil: "" };
  const now = Date.parse("2026-10-14T10:00:00Z");
  const out = await handler?.step(job, { clock: { now: () => now, sleep: async () => {} } } as unknown as StepContext);
  expect(out).toMatchObject({ kind: "wait", name: "pending", step: {} });
  expect(out?.kind === "wait" && out.runAt.toISOString()).toBe("2026-10-14T11:00:00.000Z");
});
