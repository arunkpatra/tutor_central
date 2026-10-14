import { request } from "../../prompts/mock.js";
import { type MockInput, type MockOutput, mockMarks } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { proofHolds } from "../arith.js";
import { rubric } from "./rubric.js";

/** A mock in the school's pattern (P10-Mock, D73): the marks sum to the pattern's, the questions numbered 1 to n across
 *  the sections, each section as the pattern sets it, two to six skills each question names (the gap report tallies by
 *  them), every proof holding; mathematics in LaTeX. */
export const mock: Kind<MockInput, MockOutput> = {
  kind: "mock",
  classLevel: (input) => input.classLevel,
  maths: true,
  draft: (input) => request(input),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const total = mockMarks(draft);
    if (total !== input.pattern.marks) findings.push({ item: "marks", problem: `the marks sum to ${total}, not ${input.pattern.marks}` });
    const questions = draft.sections.flatMap((s) => s.questions);
    if (questions.some((q, i) => q.number !== i + 1)) findings.push({ item: "numbering", problem: "number the questions 1 to n in order across the sections" });
    const skills = new Set(questions.map((q) => q.skill.trim().toLowerCase()));
    if (skills.size < 2 || skills.size > 6) findings.push({ item: "skills", problem: `the paper names ${skills.size} skills; two to six, each question naming one` });
    for (const want of input.pattern.sections ?? []) {
      const got = draft.sections.find((s) => s.name.trim().toLowerCase() === want.name.trim().toLowerCase());
      if (!got) {
        findings.push({ item: want.name, problem: `${want.name} is missing` });
        continue;
      }
      if (got.questions.length !== want.questions) findings.push({ item: want.name, problem: `${want.name} has ${got.questions.length} questions, not ${want.questions}` });
      for (const q of got.questions) if (q.marks !== want.marksEach) findings.push({ item: want.name, problem: `${want.name}: question ${q.number} has ${q.marks} marks, not ${want.marksEach}` });
    }
    for (const q of questions) if (q.proof && !proofHolds(q.proof)) findings.push({ item: `question ${q.number}`, problem: `its proof ${q.proof.expression} does not equal ${q.proof.equals}` });
    return findings;
  },
  rubric: rubric([
    "A paper in the school's pattern: the marks sum to the pattern's, each section as given, the questions numbered through the paper.",
    "Two to six skills from the portions named, each question naming one; questions a student of that class answers in the minutes given.",
    "Every answer in the key is right. Where an answer comes with a proof, the answer says the same value as the proof.",
  ]),
};
