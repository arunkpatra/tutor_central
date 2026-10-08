import type { ClaudeRequest } from "../claude.js";
import { type PaperInput, PaperOutput } from "../schemas.js";
import { LEVEL_WORDS, VOICE } from "./shared.js";

export type PlannedSection = { title: string; count: number; marksEach: number };

/** Marks per question for three sections, most usual first. */
const WEIGHTS = [
  [1, 2, 4],
  [1, 2, 3],
  [1, 3, 5],
  [2, 3, 5],
  [1, 2, 5],
  [2, 4, 6],
  [2, 5, 10],
  [5, 10, 20],
] as const;

/** The paper's sections, worked out here so the marks always add up (a model asked to do the sum does not always):
 *  three sections of rising marks with counts that fall (4 × 1, 4 × 2, 2 × 4 for 10 questions and 20 marks), the most
 *  even such split; else the questions shared as evenly as the marks allow, in one or two sections. */
export function sectionPlan(questions: number, marks: number): PlannedSection[] {
  type Best = { counts: number[]; weights: readonly number[]; score: number };
  let best: Best | undefined;
  for (const [index, weights] of WEIGHTS.entries()) {
    const [w1, w2, w3] = weights;
    for (let c = 1; c <= questions; c++) {
      for (let b = 1; b + c < questions; b++) {
        const a = questions - b - c;
        if (a * w1 + b * w2 + c * w3 !== marks) continue;
        const falling = a >= b && b >= c;
        const score = (falling ? 0 : 100) + Math.max(a, b, c) - Math.min(a, b, c) + index / 10;
        if (!best || score < best.score) best = { counts: [a, b, c], weights, score };
      }
    }
  }
  const titles = ["Section A", "Section B", "Section C"];
  if (best) {
    const { counts, weights } = best;
    return counts.map((count, i) => ({ title: titles[i] ?? "", count, marksEach: weights[i] ?? 1 }));
  }
  const base = Math.floor(marks / questions);
  const extra = marks % questions;
  const sections = [
    { count: questions - extra, marksEach: base },
    { count: extra, marksEach: base + 1 },
  ].filter((s) => s.count > 0 && s.marksEach > 0);
  return sections.map((s, i) => ({ title: titles[i] ?? "", ...s }));
}

/** A question paper to the API's section plan, every question with its answer. */
export function request(input: PaperInput): ClaudeRequest<PaperOutput> {
  const plan = sectionPlan(input.questions, input.marks);
  const word = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;
  return {
    model: "claude-sonnet-5-5",
    effort: "medium",
    system: [
      VOICE,
      "You set question papers. Follow the section plan you are given exactly: the same sections, in order, with the same number of questions and the same marks for each question.",
      "Harder questions go in the sections with more marks.",
      "Give every question an answer the tutor can mark against: the final answer, with the key step where there is one.",
      "Number the questions from 1 across the whole paper. The title is the topic.",
    ].join(" "),
    text: [
      `Write a question paper for ${input.classLevel}, ${input.subject}.`,
      `Topic: ${input.topic}.`,
      `Level: ${LEVEL_WORDS[input.level]}.`,
      `${input.questions} questions, ${input.marks} marks in all. The sections:`,
      ...plan.map((s) => `${s.title}: ${word(s.count, "question", "questions")} of ${word(s.marksEach, "mark", "marks")} each`),
    ].join("\n"),
    schema: PaperOutput,
  };
}
