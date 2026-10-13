import { type Kind, runAgent } from "../agents/agent.js";
import { DbFailure } from "../db.js";
import { sha256 } from "../price.js";
import type { StepContext } from "./types.js";

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
  const recorded = args.recorded ?? args.input;
  try {
    const outcome = await runAgent(
      { db: ctx.db, claude: ctx.claude, token: "", requestId: ctx.requestId, centre: args.centre, key: args.key ?? `${args.job}:${args.step}`, inputHash: sha256(JSON.stringify(recorded)), job: args.job },
      args.spec,
      args.input,
      recorded,
    );
    if (outcome.kind === "ok") return { kind: "ok", id: outcome.id, parsed: outcome.parsed, costPaise: outcome.costPaise, repaired: outcome.repaired };
    if (outcome.kind === "failed") return { kind: "failed", id: outcome.id, costPaise: outcome.costPaise, reason: outcome.reason };
    return outcome;
  } catch (e) {
    return { kind: "failed", reason: e instanceof DbFailure ? e.reason : "start" };
  }
}
