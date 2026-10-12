import { type Clock, type Job, type JobKind, type JobsDb, LeaseLost, type StepOutcome } from "./types.js";

type State = "queued" | "running" | "waiting" | "done" | "failed" | "cancelled";
export type FakeJob = Job & {
  state: State;
  key: string;
  runAt: number;
  leasedBy: string | null;
  leaseUntilMs: number;
  maxAttempts: number;
  result?: Record<string, unknown>;
  error?: { reason: string; message?: string };
  costPaise: number;
};
export type FakeStep = { job: string; name: string; state: string; attempt: number; generationId?: string };

const LEASE_MS = 180_000;

/** An in-memory JobsDb with 0028's rules on a fake clock: a claim takes due jobs one worker at a time (skip locked), a
 *  write by a worker that lost the lease or on a cancelled job throws LeaseLost, a retry backs off 30 s × 2^(n−1). */
export function fakeJobsDb(clock: Clock) {
  const jobs: FakeJob[] = [];
  const steps: FakeStep[] = [];
  let pendingClosed = 0;
  const counts = { extend: 0, closePending: 0 };
  const held = (id: string, worker: string) => {
    const j = jobs.find((x) => x.id === id);
    if (!j) throw new LeaseLost("job_not_running");
    if (j.state === "cancelled") throw new LeaseLost("job_cancelled");
    if (j.state !== "running") throw new LeaseLost("job_not_running");
    if (j.leasedBy !== worker) throw new LeaseLost("job_lease_lost");
    return j;
  };
  const db: JobsDb = {
    async claim(worker, limit) {
      const now = clock.now();
      const due = jobs
        .filter(
          (j) =>
            (j.state === "waiting" && j.runAt <= now) ||
            (j.state === "queued" && j.runAt <= now && j.attempts < j.maxAttempts) ||
            (j.state === "running" && j.leaseUntilMs < now && j.attempts < j.maxAttempts),
        )
        .sort((a, b) => a.runAt - b.runAt)
        .slice(0, limit);
      for (const j of due) {
        if (j.state !== "waiting") j.attempts += 1;
        j.state = "running";
        j.leasedBy = worker;
        j.leaseUntilMs = now + LEASE_MS;
        j.leaseUntil = new Date(j.leaseUntilMs).toISOString();
      }
      return due.map((j) => ({ ...j, step: { ...j.step } }));
    },
    async extend(id, worker) {
      counts.extend += 1;
      const j = jobs.find((x) => x.id === id);
      if (!j || j.state !== "running" || j.leasedBy !== worker) return false;
      j.leaseUntilMs = clock.now() + LEASE_MS;
      return true;
    },
    async record(id, worker, outcome: StepOutcome) {
      const j = held(id, worker);
      // job_steps.step is 1 to 40 characters (0028): the table refuses a longer name, so the fake does too.
      if (outcome.name.length < 1 || outcome.name.length > 40) throw new Error("job_steps_step_check");
      steps.push({ job: id, name: outcome.name, state: outcome.kind, attempt: j.attempts, generationId: outcome.generationId });
      if ("costPaise" in outcome) j.costPaise += outcome.costPaise ?? 0;
      j.leaseUntilMs = clock.now() + LEASE_MS;
      if (outcome.kind === "continue") j.step = outcome.step;
      if (outcome.kind === "wait") Object.assign(j, { state: "waiting", step: outcome.step, runAt: outcome.runAt.getTime(), leasedBy: null });
      if (outcome.kind === "done") Object.assign(j, { state: "done", result: outcome.result, leasedBy: null });
      if (outcome.kind === "fail") {
        const again = outcome.retry && j.attempts < j.maxAttempts;
        const wait = Math.min(600_000, 30_000 * 2 ** (Math.max(j.attempts, 1) - 1));
        Object.assign(j, { state: again ? "queued" : "failed", error: outcome.error, leasedBy: null, runAt: again ? clock.now() + wait : j.runAt });
      }
    },
    async enqueue(centre, kind: JobKind, key, input = {}, runAt) {
      const existing = jobs.find((j) => j.centreId === centre && j.key === key);
      if (existing) return existing.id;
      const id = `job-${jobs.length + 1}`;
      const at = runAt?.getTime() ?? clock.now();
      jobs.push({ id, centreId: centre, kind, attempts: 0, step: {}, input, leaseUntil: "", state: "queued", key, runAt: at, leasedBy: null, leaseUntilMs: 0, maxAttempts: 3, costPaise: 0 });
      return id;
    },
    async live(kind) {
      return jobs.filter((j) => j.kind === kind && ["queued", "waiting", "running"].includes(j.state)).length;
    },
    async closePending() {
      counts.closePending += 1;
      return pendingClosed;
    },
  };
  return {
    ...db,
    jobs,
    steps,
    counts,
    /** What the next closePending answers. */
    setPendingClosed(n: number) {
      pendingClosed = n;
    },
    /** Another worker takes the job's lease (a lapsed lease retaken). */
    takeLease(id: string, worker: string) {
      const j = jobs.find((x) => x.id === id);
      if (j) j.leasedBy = worker;
    },
    cancel(id: string) {
      const j = jobs.find((x) => x.id === id);
      if (j) j.state = "cancelled";
    },
  };
}

/** A clock the test moves; sleeping moves it. */
export function fakeClock(start = Date.UTC(2026, 9, 12, 12, 0, 0)) {
  let now = start;
  return {
    now: () => now,
    async sleep(ms: number) {
      now += ms;
    },
    advance(ms: number) {
      now += ms;
    },
  };
}
