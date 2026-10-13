import { request } from "../../prompts/check.js";
import type { ChecksOutput, ClassLevel } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric, words } from "./rubric.js";

export type CheckInput = { classLevel: ClassLevel; subject: string; skills: string[] };

/** The close's checks: one question per skill, the skill as given, a short answer (asked at twelve words; a little room). */
export const check: Kind<CheckInput, ChecksOutput> = {
  kind: "check",
  classLevel: (input) => input.classLevel,
  maths: true,
  draft: (input) => request(input.classLevel, input.subject, input.skills),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const asked = input.skills.join(" | ");
    const answered = draft.questions.map((q) => q.skill).join(" | ");
    if (asked !== answered) findings.push({ item: "skills", problem: `one question per skill, in order, each repeating its skill as given: ${asked}` });
    for (const q of draft.questions) if (words(q.answer) > 16) findings.push({ item: q.skill, problem: "the answer is longer than twelve words" });
    return findings;
  },
  rubric: rubric([
    "One question per skill named, each answered aloud in a few words or one line of working.",
    "Each expected answer is right.",
    "No multiple choice, no trick questions.",
  ]),
};
