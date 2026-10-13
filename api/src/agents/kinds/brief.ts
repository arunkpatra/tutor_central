import { request } from "../../prompts/brief.js";
import type { BriefOutput, ClassLevel } from "../../schemas.js";
import type { Kind } from "../agent.js";
import { rubric } from "./rubric.js";
import { workedExampleFindings } from "./worked-example.js";

export type BriefInput = { classLevel: ClassLevel; subject: string; chapter: string };

/** The tutor's brief for a chapter (P10-Brief): three mistakes and three lines (the schema's), the worked example's rules. */
export const brief: Kind<BriefInput, BriefOutput> = {
  kind: "brief",
  classLevel: (input) => input.classLevel,
  maths: true,
  draft: (input) => request(input.classLevel, input.subject, input.chapter),
  verify: (_input, draft) => workedExampleFindings(draft.workedExample, "worked example's "),
  rubric: rubric([
    "It is about the chapter named, as that class meets it.",
    "Three mistakes students of that class really make, each with a way to catch it in class.",
    "The worked example is right in every step; where its answer comes with a proof, they agree.",
    "Three lines a tutor can say in class.",
  ]),
};
