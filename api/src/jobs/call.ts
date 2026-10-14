import { type AgentContext, type AgentOutcome, draftOn, type Kind, runAgent } from "../agents/agent.js";
import { DbFailure } from "../db.js";
import { sha256 } from "../price.js";
import type { StepContext } from "./types.js";

/** A job's agent may take 170 s on the job's clock, not a route's 110 s: no one waits, and the worker starts a step only
 *  while 120 s of its 200 s are left (runner.ts), so a step ends by 250 s inside the 300 s function, with room for the
 *  repair after a slow draft (the review's finding 1). */
export const JOB_AGENT_BUDGET_MS = 170_000;

export type RecordedCall<T> =
  | { kind: "ok"; id: string; parsed: T; costPaise: number; repaired?: boolean }
  | { kind: "pending" }
  | { kind: "paused" }
  | { kind: "failed"; id?: string; costPaise?: number; reason: string };

/** A paid call made by a job step (D84), run by the kind's agent (D99): asked of the gate as the platform with the key
 *  `<job>:<step>` (or the key given: a mock shared by two plans, a week's note), so a step taken again after a lost lease
 *  replays the finished call or meets it still running, and pays once; its check and repair hang off that key. A call
 *  naming a student asks the gate for their consent: without it the call fails `student_consent` before anything is
 *  paid. A kind switched off is `paused`, with no row. The cost is every row's. */
export async function recordedCall<I, T>(
  ctx: StepContext,
  args: { centre: string; spec: Kind<I, T>; input: I; recorded?: unknown; job: string; step: string; key?: string },
): Promise<RecordedCall<T>> {
  try {
    return recordedOf(await runAgent(jobAgent(ctx, args), args.spec, args.input, args.recorded ?? args.input));
  } catch (e) {
    return { kind: "failed", reason: e instanceof DbFailure ? e.reason : "start" };
  }
}

/** A call made live on a draft row started before: a batch's whose batch did not end by its deadline (D108), so no
 *  second draft row is started and the row is paid once. */
export async function callOnRow<I, T>(
  ctx: StepContext,
  args: { centre: string; spec: Kind<I, T>; input: I; job: string; step: string; key?: string },
  row: string,
): Promise<RecordedCall<T>> {
  try {
    return recordedOf(await draftOn(jobAgent(ctx, args), args.spec, args.input, row));
  } catch (e) {
    return { kind: "failed", reason: e instanceof DbFailure ? e.reason : "start" };
  }
}

/** A job's agent: the platform under the key `<job>:<step>` (or the key given), the job's budget and clock, and the
 *  hour's cache mark (D108). */
export function jobAgent(ctx: StepContext, args: { centre: string; input: unknown; recorded?: unknown; job: string; step: string; key?: string }): AgentContext {
  const recorded = args.recorded ?? args.input;
  return { db: ctx.db, claude: ctx.claude, token: "", requestId: ctx.requestId, centre: args.centre, key: args.key ?? `${args.job}:${args.step}`, inputHash: sha256(JSON.stringify(recorded)), job: args.job, budgetMs: JOB_AGENT_BUDGET_MS, now: ctx.clock.now, cacheTTL: "1h" };
}

function recordedOf<T>(outcome: AgentOutcome<T>): RecordedCall<T> {
  if (outcome.kind === "ok") return { kind: "ok", id: outcome.id, parsed: outcome.parsed, costPaise: outcome.costPaise, repaired: outcome.repaired };
  if (outcome.kind === "failed") return { kind: "failed", id: outcome.id, costPaise: outcome.costPaise, reason: outcome.reason };
  return outcome;
}
