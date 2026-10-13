import type { BatchItem, ClaudeAnswer, ClaudeRequest } from "../../claude.js";
import { DbFailure } from "../../db.js";
import { batchId, type CaseScore, batchFinish, caseOfBatchId, checkItems, draftItem, outcomeOf, type Ready, ready, scoreCase, scoreKinds } from "../../evals/runner.js";
import { EVAL_KINDS, loadCases } from "../../evals/cases.js";
import { log } from "../../log.js";
import { modelFor } from "../../models.js";
import { sha256 } from "../../price.js";
import { CheckVerdict } from "../../schemas.js";
import type { Job, JobHandler, StepContext, StepOutcome } from "../types.js";

const POLL_MS = 60_000;

/** The nightly evals (D101, plan decision 12): every case of every kind on its agent and switched on, as Message Batches
 *  at half price. `submit` sends the drafts; `drafts` waits for them, finishes their rows and sends each draft's check
 *  (the other tier) and grade (Opus 5.5, the rubric); `checks` waits for those and scores. Each call is a recorded row of
 *  the Smoke centre (`smokeCentre`, so the gate and the allowance see them) keyed `evals:<day>:<case>` with `:check` or
 *  `:grade`: the job itself has no centre, so a row names it by its key. A kind switched off is skipped and named. A hand
 *  run may ask for some kinds (`input.kinds`). */
export function evalRun(source: { smokeCentre: string }): JobHandler {
  return {
    async step(job, ctx) {
      if (!source.smokeCentre) return { kind: "fail", name: "submit", error: { reason: "no_smoke_centre" }, retry: false };
      const at = (job.step as { at?: string }).at ?? "submit";
      try {
        if (at === "submit") return await submit(job, ctx, source.smokeCentre);
        if (at === "drafts") return await drafts(job, ctx, source.smokeCentre);
        return await checks(job, ctx, source.smokeCentre);
      } catch (e) {
        log.error({ requestId: ctx.requestId, job: job.id, message: "the evals' step threw", error: e instanceof Error ? e : String(e) });
        return { kind: "fail", name: at, error: { reason: "batch", message: e instanceof Error ? e.message : String(e) }, retry: true };
      }
    },
  };
}

type Input = { day: string; kinds?: string[] };
type Drafts = Record<string, { row: string; parsed: unknown; outcome: ReturnType<typeof outcomeOf>; paise: number }>;
type Step = { at: "submit" } | { at: "drafts"; batch: string; rows: Record<string, string>; paused: string[] } | { at: "checks"; batch: string; drafts: Drafts; rows: Record<string, string>; paused: string[] };

const inputOf = (job: Job): Input => {
  const raw = job.input as { day?: unknown; kinds?: unknown };
  const kinds = Array.isArray(raw.kinds) ? raw.kinds.filter((k): k is string => (EVAL_KINDS as readonly string[]).includes(String(k))) : undefined;
  return { day: typeof raw.day === "string" ? raw.day : new Date().toISOString().slice(0, 10), kinds };
};

/** The cases of the kinds asked that are switched on, made ready; the kinds switched off. */
function casesOf(input: Input): { cases: Ready[]; paused: string[] } {
  const kinds = input.kinds ?? [...EVAL_KINDS];
  const paused = kinds.filter((k) => !modelFor(k as never, "draft", k === "sheet" ? "8" : undefined).enabled);
  return { cases: loadCases(kinds.filter((k) => !paused.includes(k))).map(ready), paused };
}

const keyOf = (day: string, id: string) => `evals:${day}:${id}`;
const later = (ctx: StepContext) => new Date(ctx.clock.now() + POLL_MS);

async function submit(job: Job, ctx: StepContext, centre: string): Promise<StepOutcome> {
  const input = inputOf(job);
  const { cases, paused } = casesOf(input);
  const rows: Record<string, string> = {};
  const items: BatchItem[] = [];
  for (const r of cases) {
    const recorded = { evals: input.day, case: r.c.id };
    try {
      const started = await ctx.db.startCall("", { centre, kind: r.c.kind, input: recorded, model: r.chosen.model, key: keyOf(input.day, r.c.id), inputHash: sha256(JSON.stringify(recorded)), requestId: ctx.requestId, agentStep: "draft" });
      rows[r.c.id] = started.id;
      items.push(draftItem(r));
    } catch (e) {
      log.error({ requestId: ctx.requestId, job: job.id, case: r.c.id, message: "an eval's draft was not started", reason: e instanceof DbFailure ? e.reason : String(e) });
    }
  }
  const batch = await batchOf(ctx, items);
  return { kind: "wait", name: "submit", step: { at: "drafts", batch, rows, paused }, runAt: later(ctx) };
}

async function batchOf(ctx: StepContext, items: BatchItem[]): Promise<string> {
  if (!ctx.claude.batch) throw new Error("the client sends no batches");
  if (items.length === 0) return "";
  return (await ctx.claude.batch(items)).id;
}

async function resultsOf(ctx: StepContext, batch: string, items: BatchItem[]): Promise<"running" | Map<string, ClaudeAnswer<unknown>>> {
  if (!batch || items.length === 0) return new Map();
  if (!ctx.claude.batchResults) throw new Error("the client reads no batches");
  return ctx.claude.batchResults(batch, items);
}

async function drafts(job: Job, ctx: StepContext, centre: string): Promise<StepOutcome> {
  const input = inputOf(job);
  const step = job.step as Extract<Step, { at: "drafts" }>;
  const { cases } = casesOf(input);
  const asked = cases.filter((r) => step.rows[r.c.id]);
  const items = asked.map(draftItem);
  const answers = await resultsOf(ctx, step.batch, items);
  if (answers === "running") return { kind: "wait", name: "drafts", step, runAt: later(ctx) };
  const done: Drafts = {};
  const rows: Record<string, string> = {};
  const next: BatchItem[] = [];
  let paise = 0;
  for (const r of asked) {
    const answer = answers.get(r.c.id) ?? { kind: "failed" as const, reason: "batch missing", latencyMs: 0 };
    const request = items.find((i) => i.customId === r.c.id)?.request as ClaudeRequest<unknown>;
    const outcome = outcomeOf(answer, r.spec, step.rows[r.c.id] as string);
    const finish = batchFinish(answer, request, `${r.c.kind}@${r.asked.version}`, outcome.kind === "ok" ? outcome.parsed : null);
    await ctx.db.finish("", step.rows[r.c.id] as string, finish);
    paise += finish.costPaise ?? 0;
    done[r.c.id] = { row: step.rows[r.c.id] as string, parsed: outcome.kind === "ok" ? outcome.parsed : null, outcome, paise: finish.costPaise ?? 0 };
    if (outcome.kind !== "ok") continue;
    // The check and the grade, each a row hung off the draft by its key (0052's grammar).
    for (const [suffix, item] of Object.entries(checkItems(r, outcome.parsed)) as [("check" | "grade"), BatchItem][]) {
      const recorded = { evals: input.day, case: r.c.id, step: suffix };
      try {
        const started = await ctx.db.startCall("", { centre, kind: r.c.kind, input: recorded, model: item.request.model, key: `${keyOf(input.day, r.c.id)}:${suffix}`, inputHash: sha256(JSON.stringify(recorded)), requestId: ctx.requestId, agentStep: suffix });
        rows[item.customId] = started.id;
        next.push(item);
      } catch (e) {
        log.error({ requestId: ctx.requestId, job: job.id, case: r.c.id, step: suffix, message: "an eval's check was not started", reason: e instanceof DbFailure ? e.reason : String(e) });
      }
    }
  }
  const batch = await batchOf(ctx, next);
  return { kind: "wait", name: "drafts", step: { at: "checks", batch, drafts: done, rows, paused: step.paused }, runAt: later(ctx), costPaise: paise };
}

async function checks(job: Job, ctx: StepContext, _centre: string): Promise<StepOutcome> {
  const input = inputOf(job);
  const step = job.step as Extract<Step, { at: "checks" }>;
  const { cases } = casesOf(input);
  const asked = cases.filter((r) => step.drafts[r.c.id]);
  const items = asked.flatMap((r) => {
    const parsed = step.drafts[r.c.id]?.parsed;
    if (parsed === null || parsed === undefined) return [];
    const { check, grade } = checkItems(r, parsed);
    return [check, grade].filter((i) => step.rows[i.customId]);
  });
  const answers = await resultsOf(ctx, step.batch, items);
  if (answers === "running") return { kind: "wait", name: "checks", step, runAt: later(ctx) };
  const verdicts = new Map<string, CheckVerdict | null>();
  let paise = 0;
  for (const item of items) {
    const answer = answers.get(item.customId) ?? { kind: "failed" as const, reason: "batch missing", latencyMs: 0 };
    const id = caseOfBatchId(item.customId);
    const r = asked.find((x) => x.c.id === id) as Ready;
    const verdict = answer.kind === "ok" ? CheckVerdict.safeParse(answer.parsed) : null;
    const finish = batchFinish(answer, item.request, `${r.c.kind}@${r.asked.version}`, verdict?.success ? verdict.data : null);
    await ctx.db.finish("", step.rows[item.customId] as string, finish);
    paise += finish.costPaise ?? 0;
    verdicts.set(item.customId, verdict?.success ? verdict.data : null);
    (step.drafts[id as string] as Drafts[string]).paise += finish.costPaise ?? 0;
  }
  const scores: CaseScore[] = asked.map((r) => {
    const d = step.drafts[r.c.id] as Drafts[string];
    return scoreCase(r, d.outcome, verdicts.get(batchId(r.c.id, "check")) ?? null, verdicts.get(batchId(r.c.id, "grade")) ?? null, d.paise);
  });
  const kinds = scoreKinds(scores, (id) => cases.find((r) => r.c.id === id)?.c.expect.refused === true);
  const failures = scores.filter((s) => !(s.schema && s.verify && s.expect) || s.grade === false).map((s) => ({ id: s.id, reasons: s.reasons.slice(0, 4) }));
  return {
    kind: "done",
    name: "checks",
    result: { day: input.day, gate: Object.values(kinds).every((k) => k.gate), kinds, paused: step.paused, cost_paise: scores.reduce((n, s) => n + s.paise, 0), failures },
    costPaise: paise,
  };
}
