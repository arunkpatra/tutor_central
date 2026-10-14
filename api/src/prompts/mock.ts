import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type MockInput, MockOutput } from "../schemas.js";
import { VOICE, againWords, blocks, LIMITS, MATHS, PROOF } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "5";

/** A mock two days before a school test (P10-Mock): the school's pattern (the board's blueprint, or the app's default by
 *  class), two to six skills across the paper with each question naming one (the gap report tallies by skill, U45), a
 *  key for the tutor. Portions and a class only; no student is named. */
export function request(input: MockInput): ClaudeRequest<MockOutput> {
  const { marks, durationMinutes, sections } = input.pattern;
  return {
    model: modelFor("mock", "draft", input.classLevel).model,
    effort: "high",
    version: VERSION,
    system: blocks([
      VOICE,
      "You set a mock test in the pattern the school uses: exactly the marks given, sections as given (or sensible sections when none).",
      "Choose two to six skills across the paper, each one of the portions' skills (a chapter's main ideas, not one per question);",
      "each question names one of them in its skill field, so several questions share a skill.",
      "A key with a short answer per question. No text copied from a textbook.",
      "Questions a student of that class can answer in the minutes given. Number the questions from 1 across the sections.",
      PROOF,
      MATHS,
      LIMITS.mock,
    ], [againWords(input.reason)]),
    text: [
      `${input.title}, class ${input.classLevel} ${input.subject}.`,
      `Portions: ${input.portions.map((p) => `"${p}"`).join(", ")}.`,
      `Pattern: ${marks} marks, ${durationMinutes} minutes.`,
      ...(sections ?? []).map((s) => `${s.name}: ${s.questions} questions of ${s.marksEach} ${s.marksEach === 1 ? "mark" : "marks"}.`),
    ].join("\n"),
    schema: MockOutput,
  };
}
