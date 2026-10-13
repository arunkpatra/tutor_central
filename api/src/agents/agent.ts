import { type ClaudeAnswer, type ClaudeClient, type ClaudeRequest, CLAUDE_DEADLINE_MS } from "../claude.js";
import type { AIKind, Db, Finish, StartCall } from "../db.js";
import { log } from "../log.js";
import { type Chosen, modelFor, type Step } from "../models.js";
import { costPaise, promptHash, sha256 } from "../price.js";
import type { CheckVerdict, ClassLevel } from "../schemas.js";
import { checkRequest, repairRequest } from "./check.js";
import { mathsFindings } from "./maths.js";

/** A kind's request before the table chooses its model and effort (D100). */
export type DraftRequest<T> = Omit<ClaudeRequest<T>, "model" | "effort" | "deadlineMs">;
export type Finding = { item: string; problem: string };

/** One kind of AI work as an agent runs it (D99): the draft request; the free checks; the rubric a model check holds it
 *  to (a kind with none is drafted alone: the kinds Phase 21 moves); and how its answer is read. */
export type Kind<I, T> = {
  kind: AIKind;
  draft(input: I): DraftRequest<T>;
  /** Deterministic findings over a parsed draft (free); none means it passes. */
  verify?(input: I, draft: T): Finding[];
  /** The kind writes mathematics in LaTeX (D102): every string of a draft is held to `mathsProblem` (free). */
  maths?: boolean;
  /** The rubric the checker is held to, in words; also `api/evals/<kind>/rubric.md`. */
  rubric?: string;
  /** A sheet's band is chosen by its class (models.ts). */
  classLevel?(input: I): ClassLevel | undefined;
  /** An answer that holds nothing to use (a page with no chapters): refused in words, never checked. */
  empty?(draft: T): boolean;
  /** The student the call names: the gate asks their consent (D62); the name words a refusal. */
  student?(input: I): { id: string; name?: string } | undefined;
  /** What is kept of an answer (a register's rows tidied). */
  keep?(draft: T): T;
};

/** Who asks, under which key (the draft's; its steps add `:check`, `:repair`, `:repair:check`, 0052), with the body's
 *  hash the gate checks under the key, and the time the whole run may take. */
export type AgentContext = {
  db: Db;
  claude: ClaudeClient;
  token: string;
  requestId: string;
  centre: string;
  key: string;
  inputHash: string;
  job?: string;
  budgetMs?: number;
  now?: () => number;
};

export type AgentOutcome<T> =
  | { kind: "ok"; id: string; parsed: T; costPaise: number; repaired: boolean; replay: boolean }
  | { kind: "pending" }
  | { kind: "paused" }
  /** `words`: refused (the topic, an unfit answer, a draft the repair could not fix) or service (a timeout, a cut). */
  | { kind: "failed"; id: string; costPaise: number; reason: string; words: "refused" | "service" };

/** A fallback model is asked only for a call that failed quickly for want of capacity, never for a refused topic. */
const RETRYABLE = new Set(["timeout", "api 429", "api 529"]);
/** Below this much time left, no fallback and no repair is started: the answer would come after the app gave up. */
const FALLBACK_ROOM_MS = 20_000;
const REPAIR_ROOM_MS = 30_000;
/** A check is short; a hung checker does not eat the run's time. */
const CHECK_MS = 30_000;

/** Runs a kind (D99): the draft on the table's model (a fallback once for a quick failure); the schema (the client's);
 *  `verify`; the model check by the other tier; one repair with the findings quoted; the checks again; else a refusal.
 *  Every call is a recorded row with its step; the draft's row is finished last with the answer kept, so a replay of
 *  its key answers what the tutor got. A switched-off kind answers `paused` before any row. A check that fails keeps
 *  the draft (a guard, not a gate on availability). A DbFailure starting the draft is the caller's to word. */
export async function runAgent<I, T>(ctx: AgentContext, spec: Kind<I, T>, input: I, recorded: unknown = input): Promise<AgentOutcome<T>> {
  const level = spec.classLevel?.(input);
  const chosen = modelFor(spec.kind, "draft", level);
  if (!chosen.enabled) return { kind: "paused" };
  const now = ctx.now ?? (() => performance.now());
  const started = now();
  const left = () => (ctx.budgetMs ?? CLAUDE_DEADLINE_MS) - (now() - started);
  const student = spec.student?.(input);
  const asked = spec.draft(input);

  const draftRow = await ctx.db.startCall(ctx.token, base(ctx, spec.kind, recorded, chosen.model, ctx.key, ctx.inputHash, student?.id, "draft"));
  if (draftRow.replay) {
    if (draftRow.status !== "ok" || draftRow.output === null) return { kind: "pending" };
    return { kind: "ok", id: draftRow.id, parsed: JSON.parse(draftRow.output) as T, costPaise: 0, repaired: false, replay: true };
  }

  let cost = 0;
  const call = async <R>(request: DraftRequest<R>, model: Chosen["model"], effort: Chosen["effort"], cap?: number): Promise<ClaudeAnswer<R>> => {
    // Whole milliseconds: Node's AbortSignal.timeout refuses a fraction (performance.now() gives one).
    const answer = await ctx.claude.complete({ ...request, model, effort, deadlineMs: Math.max(1, Math.floor(Math.min(left(), cap ?? Number.POSITIVE_INFINITY))) });
    cost += costOf(answer) ?? 0;
    return answer;
  };

  let fallbackModel: string | null = null;
  let answer = await call(asked, chosen.model, chosen.effort);
  if (answer.kind === "failed" && RETRYABLE.has(answer.reason) && chosen.fallback && left() > FALLBACK_ROOM_MS) {
    log.info({ at: "agent", requestId: ctx.requestId, kind: spec.kind, fallback: chosen.fallback, after: answer.reason });
    fallbackModel = chosen.fallback;
    answer = await call(asked, chosen.fallback, chosen.effort);
  }
  const finishDraft = async (finish: Finish) => ctx.db.finish(ctx.token, draftRow.id, finish);
  const version = `${spec.kind}@${asked.version}`;
  if (answer.kind !== "ok" || spec.empty?.(answer.parsed)) {
    const finish = finished(answer, { ...asked, model: fallbackModel ?? chosen.model }, version, fallbackModel, null, answer.kind === "ok" ? "refused" : undefined);
    await finishDraft(finish);
    return { kind: "failed", id: draftRow.id, costPaise: cost, reason: finish.errorReason ?? "error", words: answer.kind === "failed" || answer.kind === "truncated" ? "service" : "refused" };
  }
  const draft = answer;
  const keep = (parsed: T) => (spec.keep ? spec.keep(parsed) : parsed);
  const rubric = spec.rubric;
  if (rubric === undefined) {
    const kept = keep(draft.parsed);
    await finishDraft(finished(draft, { ...asked, model: chosen.model }, version, fallbackModel, kept));
    return { kind: "ok", id: draftRow.id, parsed: kept, costPaise: cost, repaired: false, replay: false };
  }

  /** The free findings and the model's verdict on one answer, under the check's key. */
  const findingsOf = async (parsed: T, suffix: ":check" | ":repair:check"): Promise<Finding[]> => {
    const own = [...(spec.verify?.(input, parsed) ?? []), ...(spec.maths ? mathsFindings(parsed) : [])];
    const verdict = await check(ctx, spec, level, rubric, asked, parsed, draftRow.id, suffix, version, call);
    return [...own, ...(verdict && !verdict.pass ? verdict.findings : [])];
  };
  const refuse = async (findings: Finding[]) => {
    const reason = `check:${findings[0]?.item ?? "draft"}`.slice(0, 120);
    log.info({ at: "agent", requestId: ctx.requestId, kind: spec.kind, refused: reason, findings });
    await finishDraft({ ...finished(draft, { ...asked, model: chosen.model }, version, fallbackModel, null), status: "failed", output: null, errorReason: reason });
    return { kind: "failed" as const, id: draftRow.id, costPaise: cost, reason, words: "refused" as const };
  };

  const first = await findingsOf(draft.parsed, ":check");
  if (first.length === 0) {
    const kept = keep(draft.parsed);
    await finishDraft(finished(draft, { ...asked, model: chosen.model }, version, fallbackModel, kept));
    return { kind: "ok", id: draftRow.id, parsed: kept, costPaise: cost, repaired: false, replay: false };
  }
  if (left() < REPAIR_ROOM_MS) return refuse(first);

  const repairChoice = modelFor(spec.kind, "repair", level);
  const repairAsked = repairRequest(asked, first);
  let repairRow: { id: string };
  try {
    repairRow = await ctx.db.startCall(ctx.token, stepCall(ctx, spec.kind, repairChoice.model, draftRow.id, ":repair", student?.id));
  } catch (e) {
    log.error({ at: "agent", requestId: ctx.requestId, kind: spec.kind, step: "repair", error: e instanceof Error ? e : String(e) });
    return refuse(first);
  }
  const repaired = await call(repairAsked, repairChoice.model, repairChoice.effort);
  await ctx.db.finish(ctx.token, repairRow.id, finished(repaired, { ...repairAsked, model: repairChoice.model }, version, null, repaired.kind === "ok" ? repaired.parsed : null));
  if (repaired.kind !== "ok") return refuse(first);
  const second = await findingsOf(repaired.parsed, ":repair:check");
  if (second.length > 0) return refuse(second);
  const kept = keep(repaired.parsed);
  await finishDraft(finished(draft, { ...asked, model: chosen.model }, version, fallbackModel, kept));
  return { kind: "ok", id: draftRow.id, parsed: kept, costPaise: cost, repaired: true, replay: false };
}

/** The model check (D99): the other tier against the rubric, under `<draft key><suffix>`. A check that fails or cannot
 *  start keeps the draft and logs (null). */
async function check<T>(
  ctx: AgentContext,
  spec: { kind: AIKind },
  level: ClassLevel | undefined,
  rubric: string,
  asked: DraftRequest<T>,
  parsed: T,
  draftId: string,
  suffix: ":check" | ":repair:check",
  version: string,
  call: <R>(request: DraftRequest<R>, model: Chosen["model"], effort: Chosen["effort"], cap?: number) => Promise<ClaudeAnswer<R>>,
): Promise<CheckVerdict | null> {
  const chosen = modelFor(spec.kind, "check", level);
  const request = checkRequest(rubric, asked, parsed);
  let row: { id: string };
  try {
    row = await ctx.db.startCall(ctx.token, stepCall(ctx, spec.kind, chosen.model, draftId, suffix));
  } catch (e) {
    log.error({ at: "agent", requestId: ctx.requestId, kind: spec.kind, step: "check", error: e instanceof Error ? e : String(e) });
    return null;
  }
  const verdict = await call(request, chosen.model, chosen.effort, CHECK_MS);
  await ctx.db.finish(ctx.token, row.id, finished(verdict, { ...request, model: chosen.model }, version, null, verdict.kind === "ok" ? verdict.parsed : null));
  if (verdict.kind !== "ok") {
    log.error({ at: "agent", requestId: ctx.requestId, kind: spec.kind, step: "check", outcome: verdict.kind, kept: "draft" });
    return null;
  }
  return verdict.parsed;
}

function base(ctx: AgentContext, kind: AIKind, input: unknown, model: string, key: string, inputHash: string, student: string | undefined, agentStep: NonNullable<StartCall["agentStep"]>): StartCall {
  return { centre: ctx.centre, kind, input, model, student, key, inputHash, requestId: ctx.requestId, job: ctx.job, agentStep };
}

/** A check's or repair's row: recorded under the draft's kind, keyed by the draft's key and the step (0052's grammar). */
function stepCall(ctx: AgentContext, kind: AIKind, model: string, draftId: string, suffix: ":check" | ":repair" | ":repair:check", student?: string): StartCall {
  const recorded = { step: suffix.slice(1), draft: draftId };
  const agentStep = suffix === ":repair" ? "repair" : "check";
  return base(ctx, kind, recorded, model, `${ctx.key}${suffix}`, sha256(JSON.stringify(recorded)), student, agentStep);
}

function costOf<R>(answer: ClaudeAnswer<R>): number | null {
  if (answer.kind === "failed") return null;
  return costPaise(answer.model, answer.tokensIn, answer.tokensOut, answer.tokensCached, answer.tokensWritten);
}

/** How an answer finishes its row (D76): the output kept (`kept`, null for none), or failed with its reason; the billed
 *  tokens of every answer that came back and the cost they priced. `refusedAs` fails an answer that parsed (an empty
 *  one). */
export function finished<R>(
  answer: ClaudeAnswer<R>,
  request: Pick<DraftRequest<R>, "system"> & { model: string },
  promptVersion: string,
  fallbackModel: string | null,
  kept: unknown,
  refusedAs?: string,
): Finish {
  const finishedAt = new Date().toISOString();
  const common = { promptHash: promptHash(request.system), promptVersion, fallbackModel, finishedAt };
  if (answer.kind === "failed") {
    return { status: "failed", output: null, model: request.model, tokensIn: null, tokensOut: null, tokensCached: null, costPaise: null, latencyMs: answer.latencyMs, stopReason: null, errorReason: answer.reason, ...common };
  }
  const billed = {
    model: answer.model,
    tokensIn: answer.tokensIn,
    tokensOut: answer.tokensOut,
    tokensCached: answer.tokensCached,
    costPaise: costOf(answer),
    latencyMs: answer.latencyMs,
    stopReason: answer.stopReason,
    ...common,
  };
  if (answer.kind === "ok" && refusedAs === undefined && kept !== null) return { status: "ok", output: JSON.stringify(kept), ...billed, errorReason: null };
  // Cut at max_tokens: a service failure, never a refusal of the topic (D76).
  const errorReason = answer.kind === "truncated" ? "truncated" : answer.kind === "refused" ? answer.reason : (refusedAs ?? "refused");
  return { status: "failed", output: null, ...billed, errorReason };
}


/** A kind not moved onto the agent (Phase 21 moves the mock, the parents' kinds, the gap report, read-marks and V1's):
 *  its prompt's request drafted alone, with no check and no repair; the table still chooses its model and can pause it. */
export function fromRequest<T>(
  kind: AIKind,
  request: ClaudeRequest<T>,
  rest: { student?: string; studentName?: string; empty?: (draft: T) => boolean; keep?: (draft: T) => T; classLevel?: ClassLevel } = {},
): Kind<unknown, T> {
  const { model: _model, effort: _effort, deadlineMs: _deadline, ...asked } = request;
  return {
    kind,
    draft: () => asked,
    empty: rest.empty,
    keep: rest.keep,
    classLevel: rest.classLevel ? () => rest.classLevel : undefined,
    student: rest.student ? () => ({ id: rest.student as string, name: rest.studentName }) : undefined,
  };
}
