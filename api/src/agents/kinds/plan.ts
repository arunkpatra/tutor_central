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
    "Chapter names as a current or a recent book for the class prints them (the books changed in 2023 to 2025; a centre may use either) where the request lists the chapters; where it does not, a chapter or a plain topic name a class of that level studies, never a chapter of another class's book; a skill a tutor can teach in one class and check with one question.",
  ]),
};
