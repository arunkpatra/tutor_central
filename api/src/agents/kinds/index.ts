import type { AIKind } from "../../db.js";
import type { Kind } from "../agent.js";
import { brief } from "./brief.js";
import { check } from "./check.js";
import { figure } from "./figure.js";
import { parseSchool } from "./parse-school.js";
import { parseTextbook } from "./parse-textbook.js";
import { placement } from "./placement.js";
import { plan } from "./plan.js";
import { sheet } from "./sheet.js";
import { workedExample } from "./worked-example.js";

/** The kinds moved onto their agents (D99, plan decision 13); the rest stay drafted alone until Phase 21. */
const KINDS = { sheet, worked_example: workedExample, figure, brief, check, placement, plan, parse_textbook: parseTextbook, parse_school: parseSchool } as const;

export function kindFor(kind: AIKind): Kind<unknown, unknown> | null {
  return ((KINDS as Record<string, unknown>)[kind] as Kind<unknown, unknown> | undefined) ?? null;
}

/** Each moved kind's rubric, by kind: the words its version pins (src/prompts/registry.ts). */
export function rubrics(): Record<string, string> {
  return Object.fromEntries(Object.entries(KINDS).map(([kind, spec]) => [kind, spec.rubric ?? ""]));
}

export { brief, check, figure, parseSchool, parseTextbook, placement, plan, sheet, workedExample };
