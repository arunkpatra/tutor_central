import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";

/** The kinds of 0028's `job_kind`; this phase runs `plan` and `sweep`, Phase 18 the rest. */
export type JobKind = "plan" | "artefact" | "note_day" | "reminder_sweep" | "export" | "pdf" | "eval_run" | "sweep";

/** A job as the worker holds it: the step reached and the input, the centre from its own row (D83). */
export type Job = {
  id: string;
  centreId: string | null;
  kind: JobKind;
  attempts: number;
  step: Record<string, unknown>;
  input: Record<string, unknown>;
  leaseUntil: string;
};

/** What one step did: go on to the next step, finish, wait (a key in progress, the budget), or fail. A step that paid
 *  for a call names its generation and cost, so the step row and the job's cost carry them. */
export type StepOutcome =
  | { kind: "continue"; name: string; step: Record<string, unknown>; generationId?: string; costPaise?: number }
  | { kind: "done"; name: string; result: Record<string, unknown>; generationId?: string; costPaise?: number }
  | { kind: "wait"; name: string; step: Record<string, unknown>; runAt: Date; generationId?: string }
  | { kind: "fail"; name: string; error: { reason: string; message?: string }; retry: boolean; generationId?: string };

export type Clock = { now(): number; sleep(ms: number): Promise<void> };

/** The worker's reach into the database: the eight job functions of 0028 and the sweep's, through the service role. */
export type JobsDb = {
  claim(worker: string, limit: number): Promise<Job[]>;
  extend(job: string, worker: string): Promise<boolean>;
  /** record_step, then wait_job, finish_job or fail_job by the outcome. Throws LeaseLost when the job is no longer this
   *  worker's (another took the lease, or it was cancelled). */
  record(job: string, worker: string, outcome: StepOutcome): Promise<void>;
  enqueue(centre: string | null, kind: JobKind, key: string, input?: Record<string, unknown>, runAt?: Date): Promise<string>;
  /** The queued, waiting or running jobs of a kind (the tick's sweep guard). */
  live(kind: JobKind): Promise<number>;
  /** close_pending_generations: rows left pending past ten minutes, closed as failed. */
  closePending(): Promise<number>;
};

/** What a step may use: the platform's Db for paid calls (start_ai_call as the platform), Claude, the clock. */
export type StepContext = { db: Db; jobs: JobsDb; claude: ClaudeClient; clock: Clock; requestId: string; worker: string };
export type JobHandler = { step(job: Job, ctx: StepContext): Promise<StepOutcome> };

/** The job is no longer this worker's: its lease was taken or it was cancelled. The worker stops it without writing. */
export class LeaseLost extends Error {
  constructor(public readonly why: "job_lease_lost" | "job_cancelled" | "job_not_running") {
    super(why);
    this.name = "LeaseLost";
  }
}

export const realClock: Clock = { now: () => Date.now(), sleep: (ms) => new Promise((resolve) => setTimeout(resolve, ms)) };
