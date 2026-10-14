import { type DraftRequest, type Kind, settleBatched, stepCall } from "../../agents/agent.js";
import { checkRequest } from "../../agents/check.js";
import type { BatchItem, ClaudeAnswer, ClaudeRequest } from "../../claude.js";
import { DbFailure } from "../../db.js";
import { log } from "../../log.js";
import { makeAgent } from "../../make.js";
import { modelFor } from "../../models.js";
import type { MaterialRequest } from "../../plan/budget.js";
import { artefactOf, materialInput, placeOf } from "../../plan/material.js";
import { sha256 } from "../../price.js";
import { CheckVerdict } from "../../schemas.js";
import { BATCH_POLL_MS, BATCH_ROOM_MS, batchDeadline, cancelBatch, halfPriced, readBatch, sendBatch } from "../batch.js";
import { jobAgent } from "../call.js";
import type { Job, StepContext, StepOutcome } from "../types.js";
import type { Material, PlanRecordSource } from "./plan.js";

/** The plan's material through the Message Batches API (D108): every request's draft in one batch, each a started row
 *  keyed `<job>:make:<n>`; when it ends, each draft's check in a second; then each draft settled in turn (its free checks
 *  and the check's verdict, a repair made live) and kept by its key, every batch row at half price. A placement (several
 *  calls) and a mock (one call per exam, shared by the plans) are made live, as is a kind switched off (not made, not
 *  paid) and a draft the gate refused (the live path words it). A batch not ended by its deadline is left: the rest is
 *  made live on the batch's rows. */
export type Batched = Material & {
  batch: string;
  phase: "drafts" | "checks";
  /** By request: the batch's draft row. */
  rows: Record<string, string>;
  /** The requests made live after the batch's. */
  live: number[];
  deadline: string;
  /** By request: the batch's draft answer (the checks' phase). */
  drafts?: Record<string, ClaudeAnswer<unknown>>;
  /** By request: the check's row. */
  checks?: Record<string, string>;
};
export type Keeping = Material & {
  queue: number[];
  live: number[];
  rows: Record<string, string>;
  drafts: Record<string, ClaudeAnswer<unknown>>;
  /** By request: the check batch's verdict; none (a check batch given up) is asked live. */
  verdicts: Record<string, CheckVerdict | null>;
  /** By request: the check's half price, carried to the keep's step with the draft's. */
  checkPaise: Record<string, number>;
};
/** What follows the batch: the requests made live (on the batch's rows when it was given up), or Plan ready. */
export type Next = { live: number[]; rows: Record<string, string> };

type Spec = { body: NonNullable<ReturnType<typeof materialInput>>; spec: Kind<unknown, unknown> };

/** A request a batch can carry: one call with its own key. */
function specOf(req: MaterialRequest, centre: string): Spec | null {
  if (req.kind === "placement" || req.kind === "mock") return null;
  const body = materialInput(req, centre);
  return body ? { body, spec: makeAgent(body) as Kind<unknown, unknown> } : null;
}

const draftId = (n: number) => `make_${n}`;
const checkId = (n: number) => `make_${n}__check`;
const hour = <T>(asked: DraftRequest<T>): DraftRequest<T> => ({ ...asked, system: { ...asked.system, ttl: "1h" } });

function draftItem(n: number, s: Spec): BatchItem {
  const chosen = modelFor(s.spec.kind, "draft", s.spec.classLevel?.(s.body));
  return { customId: draftId(n), request: { ...hour(s.spec.draft(s.body)), model: chosen.model, effort: chosen.effort } as ClaudeRequest<unknown> };
}

function checkItem(n: number, s: Spec, parsed: unknown): BatchItem {
  const chosen = modelFor(s.spec.kind, "check", s.spec.classLevel?.(s.body));
  const request = checkRequest(s.spec.rubric ?? "", hour(s.spec.draft(s.body)), parsed);
  return { customId: checkId(n), request: { ...hour(request), model: chosen.model, effort: chosen.effort } as ClaudeRequest<unknown> };
}

const ordered = (rows: Record<string, unknown>) => Object.keys(rows).map(Number).sort((a, b) => a - b);

/** Every draft the batch can carry started and sent; the rest made live after it. */
export async function submit(job: Job, ctx: StepContext, centre: string, m: Material): Promise<StepOutcome> {
  const deadline = batchDeadline(ctx.clock.now(), m.draft.date, m.record.classroom.start).toISOString();
  // Asked close to the batch's start (Make the plan again before class): every request live, no batch.
  if (Date.parse(deadline) - ctx.clock.now() < BATCH_ROOM_MS) {
    return { kind: "continue", name: "make:submit", step: { ...m, at: "make:live", queue: m.requests.map((_, i) => i), rows: {} } };
  }
  const rows: Record<string, string> = {};
  const live: number[] = [];
  const items: BatchItem[] = [];
  for (const [n, req] of m.requests.entries()) {
    const s = specOf(req, centre);
    const chosen = s && modelFor(s.spec.kind, "draft", s.spec.classLevel?.(s.body));
    if (!s || !chosen?.enabled) {
      live.push(n);
      continue;
    }
    try {
      const started = await ctx.db.startCall("", { centre, kind: s.spec.kind, input: s.body, model: chosen.model, key: `${job.id}:make:${n}`, inputHash: sha256(JSON.stringify(s.body)), requestId: ctx.requestId, job: job.id, agentStep: "draft" });
      // Made before (the step taken again): the live path replays it by its key.
      if (started.replay && started.status === "ok") {
        live.push(n);
        continue;
      }
      rows[n] = started.id;
      items.push(draftItem(n, s));
    } catch (e) {
      // Refused by the gate (the allowance): the live path meets the same refusal and counts it not made.
      log.error({ requestId: ctx.requestId, job: job.id, request: n, message: "a batch draft was not started", reason: e instanceof DbFailure ? e.reason : String(e) });
      live.push(n);
    }
  }
  if (items.length === 0) return { kind: "continue", name: "make:submit", step: { ...m, at: "make:live", queue: live, rows: {} } };
  await ctx.db.markBatched(Object.values(rows));
  const batch = await sendBatch(ctx, items);
  // Read at once: a batch that ended meanwhile goes on; one running waits a minute.
  return { kind: "continue", name: "make:submit", step: { ...m, at: "make:wait", phase: "drafts", batch, rows, live, deadline } satisfies Batched & { at: string } };
}

/** The batch read: running, a minute more (or given up at the deadline); ended, the drafts' checks sent, or the checks'
 *  verdicts finished at half and the drafts settled in turn. */
export async function wait(job: Job, ctx: StepContext, centre: string, step: Batched): Promise<StepOutcome> {
  const specs = new Map(ordered(step.rows).map((n) => [n, specOf(step.requests[n] as MaterialRequest, centre) as Spec]));
  const items = step.phase === "drafts"
    ? [...specs].map(([n, s]) => draftItem(n, s))
    : ordered(step.checks ?? {}).map((n) => checkItem(n, specs.get(n) as Spec, (step.drafts?.[n] as { parsed: unknown }).parsed));
  const answers = await readBatch(ctx, step.batch, items);
  if (answers === "running") {
    if (ctx.clock.now() < Date.parse(step.deadline)) return { kind: "wait", name: "make:wait", step: { ...step, at: "make:wait" }, runAt: new Date(ctx.clock.now() + BATCH_POLL_MS) };
    log.info({ requestId: ctx.requestId, job: job.id, batch: step.batch, phase: step.phase, message: "the batch passed its deadline: the rest is made live" });
    await cancelBatch(ctx, step.batch);
    if (step.phase === "drafts") return { kind: "continue", name: "make:wait", step: { ...base(step), at: "make:live", queue: [...ordered(step.rows), ...step.live].sort((a, b) => a - b), rows: step.rows } };
    return { kind: "continue", name: "make:wait", step: keeping(step, {}, {}) };
  }
  const answer = (id: string) => answers.get(id) ?? { kind: "failed" as const, reason: "batch missing", latencyMs: 0 };
  if (step.phase === "drafts") {
    const drafts: Record<string, ClaudeAnswer<unknown>> = {};
    const checks: Record<string, string> = {};
    const next: BatchItem[] = [];
    for (const [n, s] of specs) {
      const got = answer(draftId(n));
      drafts[n] = got;
      if (got.kind !== "ok" || s.spec.empty?.(got.parsed) || s.spec.rubric === undefined) continue;
      try {
        const agent = jobAgent(ctx, { centre, input: s.body, job: job.id, step: `make:${n}` });
        const item = checkItem(n, s, got.parsed);
        checks[n] = (await ctx.db.startCall("", stepCall(agent, s.spec.kind, item.request.model, step.rows[n] as string, ":check"))).id;
        next.push(item);
      } catch (e) {
        // Its check is asked live when the draft is settled.
        log.error({ requestId: ctx.requestId, job: job.id, request: n, message: "a batch check was not started", reason: e instanceof DbFailure ? e.reason : String(e) });
      }
    }
    await ctx.db.markBatched(Object.values(checks));
    const batch = await sendBatch(ctx, next);
    return { kind: "continue", name: "make:wait", step: { ...step, at: "make:wait", phase: "checks", batch, drafts, checks } };
  }
  const verdicts: Record<string, CheckVerdict | null> = {};
  const checkPaise: Record<string, number> = {};
  for (const item of items) {
    const n = Number(item.customId.slice("make_".length, -"__check".length));
    const got = answer(item.customId);
    const verdict = got.kind === "ok" ? CheckVerdict.safeParse(got.parsed) : null;
    verdicts[n] = verdict?.success ? verdict.data : null;
    const s = specs.get(n) as Spec;
    const finish = halfPriced(got, item.request, `${s.spec.kind}@${item.request.version}`, verdicts[n]);
    await ctx.db.finish("", step.checks?.[n] as string, finish);
    checkPaise[n] = finish.costPaise ?? 0;
  }
  return { kind: "continue", name: "make:wait", step: keeping(step, verdicts, checkPaise) };
}

/** One batch draft settled and kept by its key; the next, then the live requests, then Plan ready. A keep that fails is
 *  taken again: its draft is settled again from the step, with no second batch call. */
export async function keepOne(job: Job, ctx: StepContext, source: PlanRecordSource, centre: string, step: Keeping, after: (m: Material, next: Next) => Record<string, unknown>): Promise<StepOutcome> {
  const [n, ...rest] = step.queue as [number, ...number[]];
  // A batch carries no placement (specOf).
  const req = step.requests[n] as Exclude<MaterialRequest, { kind: "placement" }>;
  const s = specOf(req, centre) as Spec;
  const row = step.rows[n] as string;
  const name = `make:keep:${n}`;
  const outcome = await settleBatched(jobAgent(ctx, { centre, input: s.body, job: job.id, step: `make:${n}` }), s.spec, s.body, row, step.drafts[n] as ClaudeAnswer<unknown>, step.verdicts[n]);
  const paise = (outcome.kind === "ok" || outcome.kind === "failed" ? outcome.costPaise : 0) + (step.checkPaise[n] ?? 0);
  const made = outcome.kind === "ok";
  if (outcome.kind === "ok") {
    try {
      await source.keep(centre, artefactOf(req, outcome.parsed as never, outcome.id), { plan: step.plan, ...placeOf(req, step.draft) }, `${job.id}:make:${n}`);
    } catch (e) {
      return { kind: "fail", name, error: { reason: "keep_failed", message: e instanceof Error ? e.message : String(e) }, retry: true, generationId: row };
    }
  }
  const counts = { made: step.made + (made ? 1 : 0), notMade: step.notMade + (made ? 0 : 1) };
  const m: Material = { ...base(step), ...counts };
  const next = rest.length > 0 ? { ...step, ...counts, queue: rest, at: "make:keep" } : after(m, { live: step.live, rows: {} });
  return { kind: "continue", name, step: next, generationId: row, costPaise: paise };
}

function base(step: Material): Material {
  const { record, draft, plan, requests, made, notMade } = step;
  return { record, draft, plan, requests, made, notMade };
}

function keeping(step: Batched, verdicts: Record<string, CheckVerdict | null>, checkPaise: Record<string, number>): Keeping & { at: "make:keep" } {
  // A check batch given up: every draft's check is asked live (no verdict).
  return { ...base(step), at: "make:keep", queue: ordered(step.drafts ?? {}), live: step.live, rows: step.rows, drafts: step.drafts ?? {}, verdicts, checkPaise };
}
