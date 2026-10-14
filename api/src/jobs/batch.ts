import { finished, halved } from "../agents/agent.js";
import type { BatchItem, ClaudeAnswer, ClaudeRequest } from "../claude.js";
import type { Finish } from "../db.js";
import { log } from "../log.js";
import type { StepContext } from "./types.js";

/** The Message Batches runner (D101, D108), shared by the nightly evals and the plan's material: a list of requests sent
 *  as one batch at half price, read back by their ids, each answer's row finished at half and marked `batched`. A batch
 *  id takes letters, digits, `_` and `-` alone (the nightly's run of 2026-10-13 failed on a colon). */

/** A batch waits this long between reads. */
export const BATCH_POLL_MS = 60_000;
/** A batch left past this is given up and the rest made live (D108). */
const BATCH_HOURS_MS = 4 * 3_600_000;
/** And never past this long before the batch's start. */
const BEFORE_START_MS = 90 * 60_000;

/** Sends the requests as one batch; its id, or "" when there is nothing to send. */
export async function sendBatch(ctx: Pick<StepContext, "claude">, items: BatchItem[]): Promise<string> {
  if (items.length === 0) return "";
  if (!ctx.claude.batch) throw new Error("the client sends no batches");
  return (await ctx.claude.batch(items)).id;
}

/** A batch still running, or each request's answer by its id (an empty batch answers nothing). */
export async function readBatch(ctx: Pick<StepContext, "claude">, batch: string, items: BatchItem[]): Promise<"running" | Map<string, ClaudeAnswer<unknown>>> {
  if (!batch || items.length === 0) return new Map();
  if (!ctx.claude.batchResults) throw new Error("the client reads no batches");
  return ctx.claude.batchResults(batch, items);
}

/** A batch given up at its deadline is cancelled, so what it has not run is not paid as well as made live; a cancel
 *  that fails is logged (the batch's answers are never read). */
export async function cancelBatch(ctx: Pick<StepContext, "claude" | "requestId">, batch: string): Promise<void> {
  if (!batch || !ctx.claude.cancelBatch) return;
  try {
    await ctx.claude.cancelBatch(batch);
  } catch (e) {
    log.error({ requestId: ctx.requestId, batch, message: "a batch given up was not cancelled", error: e instanceof Error ? e : String(e) });
  }
}

/** A batch answer's finish (D76): priced at the Batches API's half and marked `batched`. */
export function halfPriced(answer: ClaudeAnswer<unknown>, request: ClaudeRequest<unknown>, version: string, kept: unknown): Finish {
  return halved(finished(answer, request, version, null, kept), answer);
}

/** A batch is sent only with this long left before its deadline; a plan asked later makes its material live. */
export const BATCH_ROOM_MS = 30 * 60_000;

/** When a batch is given up (D108): four hours after it was sent, and never past 90 minutes before the batch's start on
 *  its day (India's time). */
export function batchDeadline(sentAt: number, date: string, start: string | null | undefined): Date {
  const hours = sentAt + BATCH_HOURS_MS;
  if (!start) return new Date(hours);
  const begins = Date.parse(`${date}T${start.slice(0, 8)}+05:30`);
  return new Date(Math.min(hours, begins - BEFORE_START_MS));
}
