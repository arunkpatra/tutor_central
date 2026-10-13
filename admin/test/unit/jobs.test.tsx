import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import { cancelJob, retryJob } from "../../app/jobs/actions";
import JobsPage from "../../app/jobs/page";
import { stepNote } from "../../content/jobs";
import { withData } from "../../lib/data";
import { previewData } from "../../lib/data/preview";

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const page = async (q: Record<string, string>) =>
  renderToStaticMarkup(await JobsPage({ searchParams: Promise.resolve(q) }));

test("jobs with a failed one open: the error, Retry and Cancel's absence, the steps", async () => {
  const html = await page({ open: "preview-failed" });
  for (const words of [
    "jobs today",
    "Retry from the failed step",
    "the lease lapsed on the last attempt",
    "make:2",
    "sheet · Sonnet · timeout on 3 tries",
    "sheet · Haiku · replayed",
    "done · 11 of 11 made",
    "done · 14 of 15 made",
    "running · make:3",
    "waiting",
    "cancelled",
    "runs at 16:00",
    "by the tutor at 06:10",
  ])
    expect(html).toContain(words);
  // A failed job is retried, not cancelled.
  expect(html).not.toContain(">Cancel<");
});

test("without open no step is shown; a live job open offers Cancel", async () => {
  expect(await page({})).not.toContain("Retry from the failed step");
  const fake = {
    ...previewData,
    job: async () => ({ ...(await previewData.job("preview-failed"))!, state: "running" as const, id: "p6" }),
  };
  const html = await withData(fake, () => page({ open: "p6" }));
  expect(html).toContain(">Cancel<");
  expect(html).not.toContain("Retry from the failed step");
});

test("the outcome's banner after Retry or Cancel", async () => {
  expect(await page({ open: "preview-failed", done: "retried" })).toContain("Queued again");
  expect(await page({ open: "preview-failed", done: "refused" })).toContain(
    "Nothing changed: the job is no longer in that state",
  );
});

const form = (fields: Record<string, string>) => {
  const f = new FormData();
  for (const [k, v] of Object.entries(fields)) f.set(k, v);
  return f;
};
const redirectOf = async (run: () => Promise<void>) =>
  ((await run().catch((e: { digest?: string }) => e)) as { digest?: string }).digest ?? "";

test("the retry action refuses a job that is not failed, and says so", async () => {
  const fake = { ...previewData, retry: async () => false };
  const to = await withData(fake, () =>
    redirectOf(() => retryJob(form({ job: "preview-failed", back: "/jobs?state=failed" }))),
  );
  expect(to).toContain("/jobs?state=failed&open=preview-failed&done=refused");
});

test("retry and cancel go back to the list they came from, never elsewhere", async () => {
  expect(await redirectOf(() => retryJob(form({ job: "preview-failed", back: "/jobs" })))).toContain(
    "/jobs?open=preview-failed&done=retried",
  );
  expect(await redirectOf(() => cancelJob(form({ job: "p6", back: "https://evil.example/jobs" })))).toContain(
    "/jobs?open=p6&done=cancelled",
  );
});

test("a step's note", () => {
  expect(
    stepNote({
      step: "read",
      attempt: 1,
      state: "done",
      error: null,
      cost_paise: 0,
      generation_id: null,
      created_at: "2026-10-13T00:00:02Z",
      seconds: 0.4,
      call: null,
    }),
  ).toBe("05:30:02 · 0.4 s");
  expect(
    stepNote({
      step: "make:0",
      attempt: 1,
      state: "done",
      error: null,
      cost_paise: 4,
      generation_id: null,
      created_at: "2026-10-13T00:00:07Z",
      seconds: 4,
      call: {
        kind: "check",
        model: "claude-haiku-5-5",
        status: "ok",
        error_reason: null,
        latency_ms: 4100,
        replayed: false,
      },
    }),
  ).toBe("check · Haiku · ₹0.04");
});
