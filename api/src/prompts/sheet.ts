import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type SheetInput, SheetOutput } from "../schemas.js";
import { VOICE, blocks, LIMITS, MATHS, PROOF, syllabusFacts } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "3";

const REASONS: Record<string, string> = {
  easier: "Make it easier: recall and one-step questions only.",
  harder: "Make it harder: application and two-step questions.",
  shorter: "Make it shorter: fewer, quicker questions.",
  "more sums": "More sums: numerical questions, fewer words.",
  "different numbers": "Keep the questions' shape and change every number.",
};

/** A group's practice set or homework sheet (P10-Sheet): questions on the skills named, for the class, with the answers
 *  for the tutor. Skills and a class only; no student is named. A reason comes from Make it again. */
export function request(input: SheetInput): ClaudeRequest<SheetOutput> {
  const reason = input.reason ? (REASONS[input.reason.toLowerCase()] ?? `The tutor asks: ${input.reason}`) : null;
  return {
    model: modelFor("sheet", "draft", input.classLevel).model,
    effort: "medium",
    version: VERSION,
    system: blocks([
      VOICE,
      "You write questions for a class of a tuition centre: a practice set for one class sitting, or homework.",
      "Spread the questions across the skills named, taking the skills in the order named; within each skill, easier questions first.",
      "Write your own questions and numbers; never reuse a textbook's exercise word for word.",
      "Give every question its answer, for the tutor. Instructions are one line for the student, or null. Number from 1. The title is the first skill.",
      PROOF,
      MATHS,
      LIMITS.sheet,
      syllabusFacts(input.classLevel, input.subject),
    ], [
      input.forHomework
        ? "You set homework: short practice questions a student finishes in one evening, lighter for the younger classes."
        : "You write a practice set for one class sitting: questions the students work through while the tutor moves between them.",
    ]),
    text: [
      `Class ${input.classLevel} ${input.subject}, ${input.forHomework ? "homework" : "a practice set"} on: ${input.skills.map((s) => `"${s}"`).join(", ")}.`,
      `Exactly ${input.questions} questions.`,
      reason,
    ].filter(Boolean).join("\n"),
    schema: SheetOutput,
  };
}
