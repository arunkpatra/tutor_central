import { request } from "../../prompts/plan.js";
import type { PlanInput, PlanOutput } from "../../schemas.js";
import type { Kind } from "../agent.js";
import { rubric } from "./rubric.js";

/** The plan's naming: one first topic per group asked. */
export const plan: Kind<PlanInput, PlanOutput> = {
  kind: "plan",
  classLevel: (input) => input.groups[0]?.classLevel,
  draft: (input) => request(input),
  verify: (input, draft) => {
    const asked = input.groups.map((g) => g.groupNo).sort();
    const named = [...new Set(draft.groups.map((g) => g.groupNo))].sort();
    return asked.join(",") === named.join(",") && draft.groups.length === asked.length ? [] : [{ item: "groups", problem: `one topic for each group asked: ${asked.join(", ")}` }];
  },
  rubric: rubric([
    "One chapter and one skill for each group, a chapter a class of that level is usually at in the month given (the school year runs June to March).",
    "Chapter names as the class's book prints them; a skill a tutor can teach in one class and check with one question.",
  ]),
};
