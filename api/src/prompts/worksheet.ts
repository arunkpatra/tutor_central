import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { QuestionSetOutput, type WorksheetInput } from "../schemas.js";
import { LEVEL_WORDS, VOICE, blocks } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "2";

/** A worksheet: practice problems. The answers always come back (they are the tutor's key); the app decides whether
 *  the key is printed for the student. */
export function request(input: WorksheetInput): ClaudeRequest<QuestionSetOutput> {
  return {
    model: modelFor("worksheet", "draft").model,
    effort: "medium",
    version: VERSION,
    system: blocks([
      VOICE,
      "You write worksheets: practice problems that build from easier to harder.",
      "Give every problem its answer, for the tutor's key. Instructions are one line for the student, or null.",
      "Number the problems from 1. The title is the topic.",
    ]),
    text: [
      `Write a worksheet for ${input.classLevel}, ${input.subject}.`,
      `Topic: ${input.topic}.`,
      `Level: ${LEVEL_WORDS[input.level]}.`,
      `Exactly ${input.questions} problems.`,
    ].join("\n"),
    schema: QuestionSetOutput,
  };
}
