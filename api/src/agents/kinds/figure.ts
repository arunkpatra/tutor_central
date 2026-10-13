import { request } from "../../prompts/figure.js";
import { type ClassLevel, type FigureDraftOutput, type FigureKind, FigureOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric } from "./rubric.js";

export type FigureInput = { figure: FigureKind; classLevel: ClassLevel; subject: string; skill: string };

/** A figure's spec (D59): the template asked for, its rule (the figure's refinements, D99) as findings, so a wrong
 *  triangle is repaired once before it is refused. */
export const figure: Kind<FigureInput, FigureDraftOutput> = {
  kind: "figure",
  classLevel: (input) => input.classLevel,
  draft: (input) => request(input.figure, input.classLevel, input.subject, input.skill),
  verify: (input, draft) => {
    if (draft.figure.kind !== input.figure) return [{ item: "figure", problem: `it is a ${draft.figure.kind}; the template asked for is ${input.figure}` }];
    const ruled = FigureOutput.safeParse(draft);
    return ruled.success ? [] : ruled.error.issues.map((issue): Finding => ({ item: "figure", problem: issue.message }));
  },
  rubric: rubric([
    "The figure illustrates the skill named for that class, with numbers and labels a student of that class meets.",
    "The template's rule holds (a landing on the line, shaded parts within the whole, a triangle's angles summing to 180, a food chain starting with a plant).",
    "The caption is one sentence that says what the figure shows, and agrees with its numbers.",
  ]),
};
