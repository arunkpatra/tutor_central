import { batchFindings, type DraftRequest, type Finding, type Kind, settleBatched, stepCall } from "../../agents/agent.js";
import { checkRequest, repairRequest } from "../../agents/check.js";
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
/** The batch in flight (D108, D111): the drafts, then their checks, then the repairs the findings ask for, then the
 *  repairs' checks; each phase's rows by request, finished at half when its batch ends. */
export type Batched = Material & {
  batch: string;
  phase: "drafts" | "checks" | "repairs" | "rechecks";
  /** By request: the batch's draft row. */
  rows: Record<string, string>;
  /** The requests made live after the batch's. */
  live: number[];
  deadline: string;
  /** By request: the rows the batch in flight answers (a check, a repair or a repair's check). */
  pending?: Record<string, string>;
} & Answers;
/** What the batches answered, by request. */
type Answers = {
  drafts?: Record<string, ClaudeAnswer<unknown>>;
  verdicts?: Record<string, CheckVerdict | null>;
  repairs?: Record<string, ClaudeAnswer<unknown>>;
  rechecks?: Record<string, CheckVerdict | null>;
  /** The half price of a request's check, repair and repair's check, carried to its keep's step with the draft's. */
  paise?: Record<string, number>;
};
export type Keeping = Material & { queue: number[]; live: number[]; rows: Record<string, string> } & Answers;
/** What follows the batch: the requests made live (on the batch's rows when it was given up), or Plan ready. */
export type Next = { live: number[]; rows: Record<string, string> };

type Spec = { body: NonNullable<ReturnType<typeof materialInput>>; spec: Kind<unknown, unknown> };

/** A request a batch can carry: one call with its own key. */
function specOf(req: MaterialRequest, centre: string): Spec | null {
  if (req.kind === "placement" || req.kind === "mock") return null;
  const body = materialInput(req, centre);
  return body ? { body, spec: makeAgent(body) as Kind<unknown, unknown> } : null;
}

/** A batch request's id (letters, digits, `_` and `-`): `make_<n>`, then `__check`, `__repair` or `__recheck`. */
const itemId = (n: number, step?: "check" | "repair" | "recheck") => (step ? `make_${n}__${step}` : `make_${n}`);
const requestOf = (id: string) => Number((id.split("__")[0] ?? "").slice("make_".length));
const hour = <T>(asked: DraftRequest<T>): DraftRequest<T> => ({ ...asked, system: { ...asked.system, ttl: "1h" } });

function draftItem(n: number, s: Spec): BatchItem {
  const chosen = modelFor(s.spec.kind, "draft", s.spec.classLevel?.(s.body));
  return { customId: itemId(n), request: { ...hour(s.spec.draft(s.body)), model: chosen.model, effort: chosen.effort } as ClaudeRequest<unknown> };
}

/** A draft's check, or (`recheck`) its repair's: the other tier against the rubric. */
function checkItem(n: number, s: Spec, parsed: unknown, step: "check" | "recheck" = "check"): BatchItem {
  const chosen = modelFor(s.spec.kind, "check", s.spec.classLevel?.(s.body));
  const request = checkRequest(s.spec.rubric ?? "", hour(s.spec.draft(s.body)), parsed);
  return { customId: itemId(n, step), request: { ...hour(request), model: chosen.model, effort: chosen.effort } as ClaudeRequest<unknown> };
}

/** A draft's repair with its findings quoted (D111). */
function repairItem(n: number, s: Spec, findings: Finding[]): BatchItem {
  const chosen = modelFor(s.spec.kind, "repair", s.spec.classLevel?.(s.body));
  return { customId: itemId(n, "repair"), request: { ...hour(repairRequest(hour(s.spec.draft(s.body)), findings)), model: chosen.model, effort: chosen.effort } as ClaudeRequest<unknown> };
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

/** The batch read: running, a minute more (or given up at the deadline: cancelled, the rest made live); ended, its rows
 *  finished at half and the next phase's batch sent, or the drafts settled in turn. */
export async function wait(job: Job, ctx: StepContext, centre: string, step: Batched): Promise<StepOutcome> {
  const specs = new Map(ordered(step.rows).map((n) => [n, specOf(step.requests[n] as MaterialRequest, centre) as Spec]));
  const spec = (n: number) => specs.get(n) as Spec;
  const items = itemsOf(step, spec);
  const answers = await readBatch(ctx, step.batch, items);
  if (answers === "running") {
    if (ctx.clock.now() < Date.parse(step.deadline)) return { kind: "wait", name: "make:wait", step: { ...step, at: "make:wait" }, runAt: new Date(ctx.clock.now() + BATCH_POLL_MS) };
    log.info({ requestId: ctx.requestId, job: job.id, batch: step.batch, phase: step.phase, message: "the batch passed its deadline: the rest is made live" });
    await cancelBatch(ctx, step.batch);
    if (step.phase === "drafts") return { kind: "continue", name: "make:wait", step: { ...base(step), at: "make:live", queue: [...ordered(step.rows), ...step.live].sort((a, b) => a - b), rows: step.rows } };
    return { kind: "continue", name: "make:wait", step: keeping(step) };
  }
  const answer = (id: string) => answers.get(id) ?? { kind: "failed" as const, reason: "batch missing", latencyMs: 0 };
  const known: Answers = { drafts: { ...step.drafts }, verdicts: { ...step.verdicts }, repairs: { ...step.repairs }, rechecks: { ...step.rechecks }, paise: { ...step.paise } };
  const agent = (n: number) => jobAgent(ctx, { centre, input: spec(n).body, job: job.id, step: `make:${n}` });
  const version = (n: number, item: BatchItem) => `${spec(n).spec.kind}@${item.request.version}`;
  // Each answer of the phase: a check's verdict or a repair kept on its row, finished at half.
  for (const item of step.phase === "drafts" ? [] : items) {
    const n = requestOf(item.customId);
    const got = answer(item.customId);
    let kept: unknown = null;
    if (step.phase === "repairs") {
      (known.repairs as Record<string, ClaudeAnswer<unknown>>)[n] = got;
      kept = got.kind === "ok" ? got.parsed : null;
    } else {
      const verdict = got.kind === "ok" ? CheckVerdict.safeParse(got.parsed) : null;
      kept = verdict?.success ? verdict.data : null;
      (step.phase === "checks" ? (known.verdicts as Record<string, CheckVerdict | null>) : (known.rechecks as Record<string, CheckVerdict | null>))[n] = kept as CheckVerdict | null;
    }
    const finish = halfPriced(got, item.request, version(n, item), kept);
    await ctx.db.finish("", step.pending?.[n] as string, finish);
    (known.paise as Record<string, number>)[n] = ((known.paise as Record<string, number>)[n] ?? 0) + (finish.costPaise ?? 0);
  }
  // The next phase's requests: a check for each draft that came back, a repair for each with findings, a check for each
  // repair that came back.
  const next: { n: number; item: BatchItem; suffix: ":check" | ":repair" | ":repair:check" }[] = [];
  for (const [n, s] of specs) {
    if (step.phase === "drafts") {
      const got = answer(itemId(n));
      (known.drafts as Record<string, ClaudeAnswer<unknown>>)[n] = got;
      if (got.kind === "ok" && !s.spec.empty?.(got.parsed) && s.spec.rubric !== undefined) next.push({ n, item: checkItem(n, s, got.parsed), suffix: ":check" });
    } else if (step.phase === "checks" && n in (known.verdicts ?? {})) {
      const findings = batchFindings(s.spec, s.body, known.drafts?.[n] as ClaudeAnswer<unknown>, known.verdicts?.[n]);
      if (findings.length > 0) next.push({ n, item: repairItem(n, s, findings), suffix: ":repair" });
    } else if (step.phase === "repairs" && n in (known.repairs ?? {})) {
      const got = known.repairs?.[n] as ClaudeAnswer<unknown>;
      if (got.kind === "ok" && !s.spec.empty?.(got.parsed)) next.push({ n, item: checkItem(n, s, got.parsed, "recheck"), suffix: ":repair:check" });
    }
  }
  const pending: Record<string, string> = {};
  const sent: BatchItem[] = [];
  for (const { n, item, suffix } of next) {
    try {
      pending[n] = (await ctx.db.startCall("", stepCall(agent(n), spec(n).spec.kind, item.request.model, step.rows[n] as string, suffix))).id;
      sent.push(item);
    } catch (e) {
      // Its step is made live when the draft is settled.
      log.error({ requestId: ctx.requestId, job: job.id, request: n, step: suffix, message: "a batch row was not started", reason: e instanceof DbFailure ? e.reason : String(e) });
    }
  }
  const phase = ({ drafts: "checks", checks: "repairs", repairs: "rechecks", rechecks: null } as const)[step.phase];
  const moved = { ...step, ...known };
  if (sent.length === 0 || phase === null) return { kind: "continue", name: "make:wait", step: keeping(moved) };
  await ctx.db.markBatched(Object.values(pending));
  const batch = await sendBatch(ctx, sent);
  return { kind: "continue", name: "make:wait", step: { ...moved, at: "make:wait", phase, batch, pending } };
}

/** The phase's requests rebuilt from the step (the batch's answers are read by them). */
function itemsOf(step: Batched, spec: (n: number) => Spec): BatchItem[] {
  if (step.phase === "drafts") return ordered(step.rows).map((n) => draftItem(n, spec(n)));
  return ordered(step.pending ?? {}).map((n) => {
    const s = spec(n);
    if (step.phase === "checks") return checkItem(n, s, (step.drafts?.[n] as { parsed: unknown }).parsed);
    if (step.phase === "repairs") return repairItem(n, s, batchFindings(s.spec, s.body, step.drafts?.[n] as ClaudeAnswer<unknown>, step.verdicts?.[n]));
    return checkItem(n, s, (step.repairs?.[n] as { parsed: unknown }).parsed, "recheck");
  });
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
  const repaired = step.repairs?.[n];
  const outcome = await settleBatched(
    jobAgent(ctx, { centre, input: s.body, job: job.id, step: `make:${n}` }),
    s.spec,
    s.body,
    row,
    step.drafts?.[n] as ClaudeAnswer<unknown>,
    step.verdicts?.[n],
    repaired ? { answer: repaired, verdict: step.rechecks?.[n] } : undefined,
  );
  const paise = (outcome.kind === "ok" || outcome.kind === "failed" ? outcome.costPaise : 0) + (step.paise?.[n] ?? 0);
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

/** The drafts settled in turn; what a phase given up left unanswered is made live (no verdict, no repair). */
function keeping(step: Batched): Keeping & { at: "make:keep" } {
  const { drafts, verdicts, repairs, rechecks, paise } = step;
  return { ...base(step), at: "make:keep", queue: ordered(step.drafts ?? {}), live: step.live, rows: step.rows, drafts, verdicts, repairs, rechecks, paise };
}
