import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type HomeworkInput, QuestionSetOutput } from "../schemas.js";
import { LEVEL_WORDS, VOICE, blocks } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "7";

/** Homework: a short set of practice questions for one evening, with the answers for the tutor. */
export function request(input: HomeworkInput): ClaudeRequest<QuestionSetOutput> {
  return {
    model: modelFor("homework", "draft").model,
    effort: "high",
    version: VERSION,
    system: blocks([
      VOICE,
      "You set homework: short practice questions a student can finish in one evening.",
      "Give every question its answer, for the tutor. Instructions are one line for the student, or null.",
      "Number the questions from 1. The title is the topic.",
      "Write every question afresh: never a textbook exercise in its words or with its numbers.",
      "Pitch every question at the class named: what a student of that class meets in its own year's book, never a higher class's chapter.",
      "Use numbers of your own in every question, never the numbers of an exercise you remember from a textbook; sentence case throughout, a method's or a rule's name in lower case (the quadratic formula, factorisation).",
      "Every question tests the subject named: in a language, social science or science set, never an arithmetic sum dressed in the topic.",
    ]),
    text: [
      `Write homework for ${input.classLevel}, ${input.subject}.`,
      `Topic: ${input.topic}.`,
      `Level: ${LEVEL_WORDS[input.level]}.`,
      `Exactly ${input.questions} questions.`,
    ].join("\n"),
    schema: QuestionSetOutput,
  };
}
