import { log } from "../log.js";
import { type Job, type JobHandler, type JobKind, type JobsDb, LeaseLost, type StepContext, type StepOutcome } from "./types.js";

/** Room for one more step before the budget ends: a Claude call's deadline (110 s) and its writes. */
export const STEP_ROOM_MS = 120_000;

export type DrainResult = { claimed: number; steps: number; done: number; waiting: number; failed: number; lost: number };

/** One run of the worker (D71): claim up to `limit` due jobs and take each through its steps while the budget leaves room
 *  for another, writing each step as it ends. A job the budget stops waits at the step it reached, for the next wake. A
 *  job whose lease another worker took, or that was cancelled, is left as it is. A handler that throws fails its job with
 *  a retry. */
export async function drain(opts: {
  jobs: JobsDb;
  handlers: Partial<Record<JobKind, JobHandler>>;
  ctx: Omit<StepContext, "jobs" | "worker">;
  worker: string;
  budgetMs: number;
  limit?: number;
}): Promise<DrainResult> {
  const { jobs, handlers, worker, budgetMs } = opts;
  const clock = opts.ctx.clock;
  const started = clock.now();
  const result: DrainResult = { claimed: 0, steps: 0, done: 0, waiting: 0, failed: 0, lost: 0 };
  const ctx: StepContext = { ...opts.ctx, jobs, worker };
  const claimed = await jobs.claim(worker, opts.limit ?? 5);
  result.claimed = claimed.length;
  for (const job of claimed) {
    const handler = handlers[job.kind];
    let current: Job = job;
    for (;;) {
      let outcome: StepOutcome;
      if (!handler) {
        outcome = { kind: "fail", name: "start", error: { reason: "no_handler", message: `no handler for ${job.kind}` }, retry: false };
      } else if (clock.now() - started >= budgetMs - STEP_ROOM_MS) {
        outcome = { kind: "wait", name: "budget", step: current.step, runAt: new Date(clock.now()) };
      } else {
        if (!(await jobs.extend(job.id, worker))) {
          result.lost += 1;
          break;
        }
        outcome = await handler.step(current, ctx).catch((e: unknown) => {
          log.error({ requestId: ctx.requestId, job: job.id, kind: job.kind, message: "a step threw", error: e });
          return { kind: "fail", name: String(current.step.at ?? "start"), error: { reason: "error", message: e instanceof Error ? e.message : String(e) }, retry: true } as const;
        });
      }
      try {
        await jobs.record(job.id, worker, outcome);
      } catch (e) {
        if (!(e instanceof LeaseLost)) throw e;
        log.warn({ requestId: ctx.requestId, job: job.id, message: "the job is no longer this worker's", why: e.why });
        result.lost += 1;
        break;
      }
      if (outcome.name !== "budget") result.steps += 1;
      if (outcome.kind === "continue") {
        current = { ...current, step: outcome.step };
        continue;
      }
      if (outcome.kind === "done") result.done += 1;
      if (outcome.kind === "wait") result.waiting += 1;
      if (outcome.kind === "fail") result.failed += 1;
      break;
    }
  }
  return result;
}
