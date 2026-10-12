import { expect, test } from "bun:test";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { drain } from "../src/jobs/runner.js";
import type { Job, JobHandler, StepContext, StepOutcome } from "../src/jobs/types.js";

/** A handler that walks `read` → `groups` → `name` → `write`, each step taking `stepMs` on the clock. */
function walker(clock: ReturnType<typeof fakeClock>, stepMs = 1_000, during?: (job: Job, at: string) => void): JobHandler & { seen: string[] } {
  const order = ["read", "groups", "name", "write"];
  const seen: string[] = [];
  return {
    seen,
    async step(job: Job): Promise<StepOutcome> {
      const at = (job.step.at as string | undefined) ?? "read";
      seen.push(at);
      clock.advance(stepMs);
      during?.(job, at);
      const next = order[order.indexOf(at) + 1];
      return next ? { kind: "continue", name: at, step: { at: next } } : { kind: "done", name: at, result: { plan_id: "p1" } };
    },
  };
}

function setup(handler: (clock: ReturnType<typeof fakeClock>, jobs: ReturnType<typeof fakeJobsDb>) => JobHandler) {
  const clock = fakeClock();
  const jobs = fakeJobsDb(clock);
  const h = handler(clock, jobs);
  const db = fakeDb();
  const ctx = { db, claude: fakeClaude({}), clock, requestId: "r1" };
  const run = (worker = "w1", budgetMs = 200_000) => drain({ jobs, handlers: { plan: h }, ctx, worker, budgetMs });
  return { clock, jobs, h, run, db };
}

test("a job's steps run in order in one run while the budget allows, and done is written once", async () => {
  let h!: ReturnType<typeof walker>;
  const { jobs, run } = setup((clock) => (h = walker(clock)));
  await jobs.enqueue("c1", "plan", "plan:a");
  const result = await run();
  expect(result).toEqual({ claimed: 1, steps: 4, done: 1, waiting: 0, failed: 0, lost: 0 });
  expect(h.seen).toEqual(["read", "groups", "name", "write"]);
  expect(jobs.steps.map((s) => [s.name, s.state])).toEqual([["read", "continue"], ["groups", "continue"], ["name", "continue"], ["write", "done"]]);
  expect(jobs.jobs[0]).toMatchObject({ state: "done", result: { plan_id: "p1" } });
});

test("the budget ends between steps: the job waits at the step reached and the next run continues there", async () => {
  let h!: ReturnType<typeof walker>;
  // Each step takes 50 s; a budget of 220 s leaves room (120 s) for one step after the first.
  const { jobs, run } = setup((clock) => (h = walker(clock, 50_000)));
  await jobs.enqueue("c1", "plan", "plan:b");
  const first = await run("w1", 220_000);
  expect(first).toMatchObject({ steps: 2, waiting: 1, done: 0 });
  expect(jobs.jobs[0]).toMatchObject({ state: "waiting", step: { at: "name" }, attempts: 1 });
  const second = await run("w2", 220_000);
  expect(second).toMatchObject({ steps: 2, done: 1 });
  expect(h.seen).toEqual(["read", "groups", "name", "write"]);
  expect(jobs.jobs[0]).toMatchObject({ state: "done", attempts: 1 });
});

test("a step whose lease was taken stops the worker", async () => {
  let h!: ReturnType<typeof walker>;
  const { jobs, run } = setup((clock, j) => (h = walker(clock, 1_000, (job, at) => at === "groups" && j.takeLease(job.id, "w2"))));
  await jobs.enqueue("c1", "plan", "plan:c");
  const result = await run();
  expect(result).toMatchObject({ steps: 1, lost: 1, done: 0 });
  expect(h.seen).toEqual(["read", "groups"]);
  expect(jobs.steps.map((s) => s.name)).toEqual(["read"]);
});

test("a step that meets an in-progress key waits, and is not claimed again before its time", async () => {
  const { clock, jobs, run } = setup((clock) => ({
    async step(job): Promise<StepOutcome> {
      if (job.step.at === "name") return { kind: "done", name: "name", result: {} };
      return { kind: "wait", name: "name", step: { at: "name" }, runAt: new Date(clock.now() + 30_000) };
    },
  }));
  await jobs.enqueue("c1", "plan", "plan:d");
  expect(await run()).toMatchObject({ waiting: 1 });
  expect(jobs.jobs[0]?.state).toBe("waiting");
  expect(await run()).toMatchObject({ claimed: 0 });
  clock.advance(30_000);
  expect(await run()).toMatchObject({ claimed: 1, done: 1 });
});

test("a cancelled job's step keeps its paid call on the call's row and the worker stops", async () => {
  const { jobs, run, db } = setup((_clock, j) => ({
    async step(job, ctx: StepContext): Promise<StepOutcome> {
      const started = await ctx.db.startCall("", { centre: "c1", kind: "plan", input: {}, model: "claude-sonnet-5-5", key: `${job.id}:name`, job: job.id });
      j.cancel(job.id);
      return { kind: "continue", name: "name", step: { at: "write" }, generationId: started.id };
    },
  }));
  await jobs.enqueue("c1", "plan", "plan:e");
  expect(await run()).toMatchObject({ lost: 1, steps: 0 });
  expect(db.started[0]).toMatchObject({ key: "job-1:name", job: "job-1" });
  expect(jobs.jobs[0]?.state).toBe("cancelled");
  expect(jobs.steps).toEqual([]);
});

test("a failing step retries with backoff and fails after max_attempts", async () => {
  const { clock, jobs, run } = setup(() => ({
    async step(): Promise<StepOutcome> {
      throw new Error("the record could not be read");
    },
  }));
  await jobs.enqueue("c1", "plan", "plan:f");
  expect(await run()).toMatchObject({ failed: 1 });
  expect(jobs.jobs[0]).toMatchObject({ state: "queued", attempts: 1, error: { reason: "error" } });
  clock.advance(30_000);
  await run();
  expect(jobs.jobs[0]).toMatchObject({ state: "queued", attempts: 2 });
  clock.advance(60_000);
  await run();
  expect(jobs.jobs[0]).toMatchObject({ state: "failed", attempts: 3 });
  clock.advance(600_000);
  expect(await run()).toMatchObject({ claimed: 0 });
});

test("a job is leased when its turn comes, not at the run's start, so a long first job leaves the next one's lease whole", async () => {
  const seenQueued: string[] = [];
  const { jobs, run } = setup((clock, j) =>
    walker(clock, 1_000, (job, at) => {
      if (job.id === j.jobs[0]?.id && at === "write") seenQueued.push(j.jobs[1]?.state ?? "");
    }),
  );
  await jobs.enqueue("c1", "plan", "plan:first");
  await jobs.enqueue("c1", "plan", "plan:second");
  expect(await run()).toMatchObject({ claimed: 2, done: 2 });
  expect(seenQueued).toEqual(["queued"]);
});

test("the lease is extended before each step", async () => {
  const { jobs, run } = setup((clock) => walker(clock));
  await jobs.enqueue("c1", "plan", "plan:g");
  await run();
  expect(jobs.counts.extend).toBe(4);
});

test("two workers draining at once never run the same job's step twice", async () => {
  let h!: ReturnType<typeof walker>;
  const { jobs, run } = setup((clock) => (h = walker(clock)));
  for (const k of ["a", "b", "c"]) await jobs.enqueue("c1", "plan", `plan:h-${k}`);
  const [one, two] = await Promise.all([run("w1"), run("w2")]);
  expect((one.claimed ?? 0) + (two.claimed ?? 0)).toBe(3);
  expect(h.seen.length).toBe(12);
  expect(jobs.jobs.every((j) => j.state === "done")).toBe(true);
});

test("a job of a kind with no handler fails without a retry", async () => {
  const { jobs, run } = setup((clock) => walker(clock));
  await jobs.enqueue("c1", "export", "export:1");
  expect(await run()).toMatchObject({ failed: 1 });
  expect(jobs.jobs[0]).toMatchObject({ state: "failed", error: { reason: "no_handler" } });
});
