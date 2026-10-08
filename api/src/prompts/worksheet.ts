import type { ClaudeRequest } from "../claude.js";
import { QuestionSetOutput, type WorksheetInput } from "../schemas.js";
import { LEVEL_WORDS, VOICE } from "./shared.js";

/** A worksheet: practice problems. The answers always come back (they are the tutor's key); the app decides whether
 *  the key is printed for the student. */
export function request(input: WorksheetInput): ClaudeRequest<QuestionSetOutput> {
  return {
    model: "claude-sonnet-5-5",
    effort: "medium",
    system: [
      VOICE,
      "You write worksheets: practice problems that build from easier to harder.",
      "Give every problem its answer, for the tutor's key. Instructions are one line for the student, or null.",
      "Number the problems from 1. The title is the topic.",
    ].join(" "),
    text: [
      `Write a worksheet for ${input.classLevel}, ${input.subject}.`,
      `Topic: ${input.topic}.`,
      `Level: ${LEVEL_WORDS[input.level]}.`,
      `Exactly ${input.questions} problems.`,
    ].join("\n"),
    schema: QuestionSetOutput,
  };
}
