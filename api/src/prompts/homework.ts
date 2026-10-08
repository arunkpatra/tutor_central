import type { ClaudeRequest } from "../claude.js";
import { type HomeworkInput, QuestionSetOutput } from "../schemas.js";
import { LEVEL_WORDS, VOICE } from "./shared.js";

/** Homework: a short set of practice questions for one evening, with the answers for the tutor. */
export function request(input: HomeworkInput): ClaudeRequest<QuestionSetOutput> {
  return {
    model: "claude-sonnet-5-5",
    effort: "medium",
    system: [
      VOICE,
      "You set homework: short practice questions a student can finish in one evening.",
      "Give every question its answer, for the tutor. Instructions are one line for the student, or null.",
      "Number the questions from 1. The title is the topic.",
    ].join(" "),
    text: [
      `Write homework for ${input.classLevel}, ${input.subject}.`,
      `Topic: ${input.topic}.`,
      `Level: ${LEVEL_WORDS[input.level]}.`,
      `Exactly ${input.questions} questions.`,
    ].join("\n"),
    schema: QuestionSetOutput,
  };
}
