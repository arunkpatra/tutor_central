import type { ClaudeRequest } from "./claude.js";
import type { V2Kind } from "./db.js";
import type { ClassLevel } from "./schemas.js";

type Model = ClaudeRequest<unknown>["model"];

/** One model per V2 kind, no fallbacks (D35, D63; docs/spec-v2.md section 9): Haiku for the short and the personal
 *  kinds, Sonnet for what needs more reasoning; a sheet moves to Sonnet from class 6. */
const MODELS: Record<Exclude<V2Kind, "sheet">, Model> = {
  check: "claude-haiku-5-5",
  placement: "claude-haiku-5-5",
  note: "claude-haiku-5-5",
  can_do: "claude-haiku-5-5",
  test_tomorrow: "claude-haiku-5-5",
  worked_example: "claude-sonnet-5-5",
  figure: "claude-sonnet-5-5",
  brief: "claude-sonnet-5-5",
  mock: "claude-sonnet-5-5",
  parse_school: "claude-sonnet-5-5",
  parse_textbook: "claude-sonnet-5-5",
  plan: "claude-sonnet-5-5",
  gap_report: "claude-sonnet-5-5",
};
const EARLY: readonly ClassLevel[] = ["lkg", "ukg", "1", "2", "3", "4", "5"];

export function modelFor(kind: V2Kind, classLevel: ClassLevel): Model {
  if (kind === "sheet") return EARLY.includes(classLevel) ? "claude-haiku-5-5" : "claude-sonnet-5-5";
  return MODELS[kind];
}

/** Marking a paper, a mock's included, is check-paper's (V1's model). */
export const MARKING_MODEL: Model = "claude-opus-5-5";
