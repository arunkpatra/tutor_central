import type { ClaudeRequest } from "../claude.js";
import { type PaperInput, PaperOutput } from "../schemas.js";
import { LEVEL_WORDS, VOICE } from "./shared.js";

/** A question paper: sections whose marks add up to the paper's total exactly, every question with its answer. */
export function request(input: PaperInput): ClaudeRequest<PaperOutput> {
  return {
    model: "claude-sonnet-5-5",
    effort: "medium",
    system: [
      VOICE,
      "You set question papers. Group the questions into sections (Section A, Section B and so on) by marks, every question in a section carrying the section's marks.",
      "The marks of all questions add up to the paper's total exactly, and the number of questions is exactly what is asked.",
      "Give every question an answer the tutor can mark against: the final answer, with the key step where there is one.",
      "Number the questions from 1 across the whole paper. The title is the topic.",
    ].join(" "),
    text: [
      `Write a question paper for ${input.classLevel}, ${input.subject}.`,
      `Topic: ${input.topic}.`,
      `Level: ${LEVEL_WORDS[input.level]}.`,
      `${input.questions} questions, ${input.marks} marks in all.`,
    ].join("\n"),
    schema: PaperOutput,
  };
}
