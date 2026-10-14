import { request, sectionPlan } from "../../prompts/paper.js";
import type { PaperInput, PaperOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric } from "./rubric.js";

const count = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;

/** A question paper (Make's V1, P6-Result-Paper): the section plan the API worked out followed exactly, each section's
 *  count and marks each; the questions numbered 1 to n through the paper; every question answered. */
export const paper: Kind<PaperInput, PaperOutput> = {
  kind: "paper",
  draft: (input) => request(input),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const plan = sectionPlan(input.questions, input.marks);
    if (draft.sections.length !== plan.length) findings.push({ item: "sections", problem: `${count(draft.sections.length, "section", "sections")}, not ${plan.length}` });
    const questions = draft.sections.flatMap((s) => s.questions);
    if (questions.some((q, i) => q.number !== i + 1)) findings.push({ item: "numbering", problem: "number the questions 1 to n in order through the paper" });
    for (const q of questions) if (!q.answer.trim()) findings.push({ item: `question ${q.number}`, problem: `question ${q.number} has no answer` });
    plan.forEach((want, i) => {
      const got = draft.sections[i];
      if (!got) return;
      if (got.questions.length !== want.count) findings.push({ item: want.title, problem: `${want.title} has ${count(got.questions.length, "question", "questions")}, not ${want.count}` });
      for (const q of got.questions) if (q.marks !== want.marksEach) findings.push({ item: want.title, problem: `${want.title}: question ${q.number} has ${q.marks} marks, not ${want.marksEach}` });
    });
    return findings;
  },
  rubric: rubric([
    "A question paper on the topic for the class, in the section plan given: the same sections in order, each with its number of questions and its marks each; the harder questions in the sections with more marks.",
    "Every question has its answer for the tutor, right, with the key step where there is one.",
  ]),
};
