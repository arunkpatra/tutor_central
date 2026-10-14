import { type AgentOutcome, type DraftRequest, type Kind } from "../agents/agent.js";
import { checkRequest } from "../agents/check.js";
import type { BatchItem, ClaudeAnswer, ClaudeRequest } from "../claude.js";
import { type Chosen, modelFor } from "../models.js";
import { CheckVerdict, type ClassLevel } from "../schemas.js";
import { agentFor, type Case, evaluate } from "./cases.js";
import { RUBRIC_GATE } from "./gate.js";

/** The grader's words (D101): an answer judged against the kind's rubric with the request beside it, by Opus 5.5, a
 *  model other than any generator — the nightly's `llm-rubric`. */
const GRADE_RULES = [
  "You grade an answer that was made for a tutor at a small tuition centre in India, against the rubric below.",
  "Judge only what the rubric asks; a matter of taste is not a failure. Pass true when the answer meets every line of the rubric.",
  "Otherwise pass false, with one finding per line it breaks: the item in a few words and the problem in one sentence.",
].join(" ");
export const GRADER = "claude-opus-5-5" as const;

export function gradeRequest<T>(rubric: string, asked: DraftRequest<T>, answer: T): DraftRequest<CheckVerdict> {
  return { ...checkRequest(rubric, asked, answer), system: { shared: `${GRADE_RULES}\n\nThe rubric:\n${rubric}`, own: "" } };
}

/** A case made ready: its agent, its input, the draft request and the table's choice for its draft. */
export type Ready = { c: Case; spec: Kind<unknown, unknown>; input: unknown; asked: DraftRequest<unknown>; chosen: Chosen; level?: ClassLevel };

export function ready(c: Case): Ready {
  const { spec, input } = agentFor(c);
  const level = spec.classLevel?.(input);
  return { c, spec, input, asked: spec.draft(input), chosen: modelFor(spec.kind, "draft", level), level };
}

/** A batch request's id: the case's for its draft, `<case>__check` and `<case>__grade` for the rest (the Batches API takes
 *  letters, digits, `_` and `-` alone; run 38384… of 2026-10-13 failed on a colon). */
export const batchId = (caseId: string, step?: "check" | "grade"): string => (step ? `${caseId}__${step}` : caseId);
export const caseOfBatchId = (id: string): string => id.split("__")[0] ?? id;

export const draftItem = (r: Ready): BatchItem => ({ customId: r.c.id, request: { ...r.asked, model: r.chosen.model, effort: r.chosen.effort } as ClaudeRequest<unknown> });

/** The check (the other tier, as the agent's) and the grade (Opus) of a draft that came back. */
export function checkItems(r: Ready, parsed: unknown): { check: BatchItem; grade: BatchItem } {
  const rubric = r.spec.rubric ?? "";
  const checker = modelFor(r.spec.kind, "check", r.level);
  return {
    check: { customId: batchId(r.c.id, "check"), request: { ...checkRequest(rubric, r.asked, parsed), model: checker.model, effort: checker.effort } as ClaudeRequest<unknown> },
    grade: { customId: batchId(r.c.id, "grade"), request: { ...gradeRequest(rubric, r.asked, parsed), model: GRADER, effort: "medium" } as ClaudeRequest<unknown> },
  };
}

/** A draft answer as the agent's outcome, for `evaluate`. */
export function outcomeOf(answer: ClaudeAnswer<unknown>, spec: Kind<unknown, unknown>, id: string): AgentOutcome<unknown> {
  if (answer.kind === "ok" && !spec.empty?.(answer.parsed)) return { kind: "ok", id, parsed: answer.parsed, costPaise: 0, repaired: false, replay: false };
  return { kind: "failed", id, costPaise: 0, reason: answer.kind === "ok" ? "refused" : answer.kind === "refused" ? answer.reason : answer.kind === "truncated" ? "truncated" : answer.reason, words: answer.kind === "ok" || answer.kind === "refused" ? "refused" : "service" };
}

export type CaseScore = { kind: string; id: string; schema: boolean; verify: boolean; expect: boolean; check: boolean | null; grade: boolean | null; paise: number; reasons: string[] };
export type KindScore = { cases: number; schema: number; verify: number; expect: number; check_pass: number; would_repair: number; grade_pass: number; grade_rate: number; cost_paise: number; gate: boolean };

/** Each case scored: the free checks (`evaluate`), the checker's and the grader's verdicts. */
export function scoreCase(r: Ready, outcome: AgentOutcome<unknown>, check: CheckVerdict | null, grade: CheckVerdict | null, paise: number): CaseScore {
  const scored = evaluate(r.c, r.input, outcome);
  return { kind: r.c.kind, id: r.c.id, schema: scored.schema, verify: scored.verify, expect: scored.expect, check: check?.pass ?? null, grade: grade?.pass ?? null, paise, reasons: [...scored.reasons, ...(grade && !grade.pass ? grade.findings.map((f) => `grade: ${f.item}: ${f.problem}`) : [])] };
}

/** Per kind: the passes, the share the checker would have sent to a repair, the rubric's rate and the gate (D101: every
 *  case's free checks, the rubric at 85% or more). A case expecting a refusal is not graded. */
export function scoreKinds(cases: CaseScore[], expectsRefusal: (id: string) => boolean): Record<string, KindScore> {
  const kinds: Record<string, KindScore> = {};
  for (const s of cases) {
    const k = (kinds[s.kind] ??= { cases: 0, schema: 0, verify: 0, expect: 0, check_pass: 0, would_repair: 0, grade_pass: 0, grade_rate: 0, cost_paise: 0, gate: false });
    k.cases += 1;
    if (s.schema) k.schema += 1;
    if (s.verify) k.verify += 1;
    if (s.expect) k.expect += 1;
    if (s.check === true) k.check_pass += 1;
    if (s.check === false || !s.verify) k.would_repair += 1;
    if (s.grade === true) k.grade_pass += 1;
    k.cost_paise += s.paise;
  }
  for (const [kind, k] of Object.entries(kinds)) {
    const graded = cases.filter((s) => s.kind === kind && !expectsRefusal(s.id)).length;
    k.grade_rate = graded === 0 ? 1 : Math.round((k.grade_pass / graded) * 100) / 100;
    k.gate = k.schema === k.cases && k.verify === k.cases && k.expect === k.cases && k.grade_rate >= RUBRIC_GATE;
  }
  return kinds;
}
