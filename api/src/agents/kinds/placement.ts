import { request } from "../../prompts/placement.js";
import type { ClassLevel, PlacementOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric, words } from "./rubric.js";

export type PlacementInput = { classLevel: ClassLevel; subject: string; chapters: string[] };

/** The placement: one question per chapter, the chapter as given. */
export const placement: Kind<PlacementInput, PlacementOutput> = {
  kind: "placement",
  classLevel: (input) => input.classLevel,
  maths: true,
  draft: (input) => request(input.classLevel, input.subject, input.chapters),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const asked = input.chapters.join(" | ");
    if (draft.questions.map((q) => q.chapter).join(" | ") !== asked) findings.push({ item: "chapters", problem: `one question per chapter, in order, each repeating its chapter as given: ${asked}` });
    for (const q of draft.questions) if (words(q.answer) > 16) findings.push({ item: q.chapter, problem: "the answer is longer than twelve words" });
    return findings;
  },
  rubric: rubric([
    "One question per chapter named, on the chapter's most basic idea, answered aloud in a few words.",
    "Each expected answer is right.",
  ]),
};
