import type { ClaudeRequest } from "../claude.js";
import { type AIKind, DbFailure } from "../db.js";
import { sha256 } from "../price.js";
import { finishOf } from "../routes/common.js";
import type { StepContext } from "./types.js";

export type RecordedCall<T> =
  | { kind: "ok"; id: string; parsed: T; costPaise: number }
  | { kind: "pending" }
  | { kind: "failed"; id?: string; costPaise?: number; reason: string };

/** A paid call made by a job step (D84): asked of the gate as the platform with the key `<job>:<step>`, so a step taken
 *  again after a lost lease replays the finished call or meets it still running, and pays once. Finished as a route
 *  finishes its row (`finishOf`). */
export async function recordedCall<T>(
  ctx: StepContext,
  args: { centre: string; kind: AIKind; input: unknown; request: ClaudeRequest<T>; job: string; step: string },
): Promise<RecordedCall<T>> {
  const key = `${args.job}:${args.step}`;
  let started: Awaited<ReturnType<StepContext["db"]["startCall"]>>;
  try {
    started = await ctx.db.startCall("", {
      centre: args.centre,
      kind: args.kind,
      input: args.input,
      model: args.request.model,
      key,
      inputHash: sha256(JSON.stringify(args.input)),
      requestId: ctx.requestId,
      job: args.job,
    });
  } catch (e) {
    return { kind: "failed", reason: e instanceof DbFailure ? e.reason : "start" };
  }
  if (started.replay) {
    if (started.status !== "ok" || started.output === null) return { kind: "pending" };
    return { kind: "ok", id: started.id, parsed: JSON.parse(started.output) as T, costPaise: 0 };
  }
  const result = await ctx.claude.complete(args.request);
  const outcome = finishOf({ request: args.request }, result);
  await ctx.db.finish("", started.id, outcome.finish);
  const costPaise = outcome.finish.costPaise ?? 0;
  if (outcome.kept !== undefined) return { kind: "ok", id: started.id, parsed: outcome.kept, costPaise };
  return { kind: "failed", id: started.id, costPaise, reason: outcome.finish.errorReason ?? "error" };
}
