import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type MockInput, MockOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** A mock two days before a school test (P10-Mock): the school's pattern (the board's blueprint, or the app's default by
 *  class), each question on one skill of the portions and naming it (the gap report tallies by skill), a key for the
 *  tutor. Portions and a class only; no student is named. */
export function request(input: MockInput): ClaudeRequest<MockOutput> {
  const { marks, durationMinutes, sections } = input.pattern;
  return {
    model: modelFor("mock", input.classLevel),
    effort: "high",
    system: [
      VOICE,
      "You set a mock test in the pattern the school uses: exactly the marks given, sections as given (or sensible sections when none).",
      "Each question tests one skill from the portions and names it in the skill field.",
      "A key with a short answer per question. No text copied from a textbook.",
      "Questions a student of that class can answer in the minutes given. Number the questions from 1 across the sections.",
    ].join(" "),
    text: [
      `${input.title}, class ${input.classLevel} ${input.subject}.`,
      `Portions: ${input.portions.map((p) => `"${p}"`).join(", ")}.`,
      `Pattern: ${marks} marks, ${durationMinutes} minutes.`,
      ...(sections ?? []).map((s) => `${s.name}: ${s.questions} questions of ${s.marksEach} ${s.marksEach === 1 ? "mark" : "marks"}.`),
    ].join("\n"),
    schema: MockOutput,
  };
}
