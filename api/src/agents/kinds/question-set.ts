import { request as homeworkRequest } from "../../prompts/homework.js";
import { request as worksheetRequest } from "../../prompts/worksheet.js";
import type { HomeworkInput, QuestionSetOutput, WorksheetInput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric } from "./rubric.js";

/** A set of questions (homework, a worksheet): exactly the number asked, numbered from 1, every one answered. */
function setFindings(asked: number, draft: QuestionSetOutput): Finding[] {
  const findings: Finding[] = [];
  if (draft.questions.length !== asked) findings.push({ item: "count", problem: `${draft.questions.length} questions, not ${asked}` });
  if (draft.questions.some((q, i) => q.number !== i + 1)) findings.push({ item: "numbering", problem: "number the questions 1 to n in order" });
  for (const q of draft.questions) if (!q.answer.trim()) findings.push({ item: `question ${q.number}`, problem: `question ${q.number} has no answer` });
  return findings;
}

/** Homework (Make's V1): short questions one evening holds, the answers for the tutor. */
export const homework: Kind<HomeworkInput, QuestionSetOutput> = {
  kind: "homework",
  draft: (input) => homeworkRequest(input),
  verify: (input, draft) => setFindings(input.questions, draft),
  rubric: rubric([
    "Homework on the topic at the level asked: exactly the number of questions asked, short enough for one evening; the instructions one line for the student, or none.",
    "Every question has its answer for the tutor, right.",
  ]),
};

/** A worksheet (Make's V1): problems from easier to harder, the answers the tutor's key. */
export const worksheet: Kind<WorksheetInput, QuestionSetOutput> = {
  kind: "worksheet",
  draft: (input) => worksheetRequest(input),
  verify: (input, draft) => setFindings(input.questions, draft),
  rubric: rubric([
    "A worksheet on the topic at the level asked: exactly the number of problems asked, building from easier to harder; the instructions one line for the student, or none.",
    "Every problem has its answer for the tutor's key, right.",
  ]),
};
