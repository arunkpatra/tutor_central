import { request } from "../../prompts/figure.js";
import { type ClassLevel, type FigureDraftOutput, type FigureKind, FigureOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { NUMBER_TOKEN, numberOf, numbersIn } from "./numbers.js";
import { rubric } from "./rubric.js";

type NumberLine = Extract<FigureDraftOutput["figure"], { kind: "number_line" }>;

/** A number line's caption says what the line draws (the first nightly's figure, D105): the landing (start plus the
 *  jumps) as a number, and a count of jumps it names ("5 jumps", "five jumps") equal to the jumps drawn. */
export function numberLineCaptionFindings(line: NumberLine, caption: string): Finding[] {
  const findings: Finding[] = [];
  const named = caption.match(new RegExp(`\\b${NUMBER_TOKEN}\\s+jumps?\\b`, "i"))?.[1];
  const count = named === undefined ? undefined : numberOf(named);
  if (count !== undefined && count !== line.jumps.length) findings.push({ item: "caption", problem: `the caption says ${count} jumps; the figure draws ${line.jumps.length}` });
  const landing = line.start + line.jumps.reduce((a, b) => a + b, 0);
  if (!numbersIn(caption).includes(landing)) findings.push({ item: "caption", problem: `the caption does not name the landing, ${landing}` });
  return findings;
}

export type FigureInput = { figure: FigureKind; classLevel: ClassLevel; subject: string; skill: string };

/** A figure's spec (D59): the template asked for, its rule (the figure's refinements, D99) and a number line's caption as
 *  findings, so a wrong figure is repaired once before it is refused. */
export const figure: Kind<FigureInput, FigureDraftOutput> = {
  kind: "figure",
  classLevel: (input) => input.classLevel,
  draft: (input) => request(input.figure, input.classLevel, input.subject, input.skill),
  verify: (input, draft) => {
    if (draft.figure.kind !== input.figure) return [{ item: "figure", problem: `it is a ${draft.figure.kind}; the template asked for is ${input.figure}` }];
    const ruled = FigureOutput.safeParse(draft);
    if (!ruled.success) return ruled.error.issues.map((issue): Finding => ({ item: "figure", problem: issue.message }));
    return draft.figure.kind === "number_line" ? numberLineCaptionFindings(draft.figure, draft.caption) : [];
  },
  rubric: rubric([
    "The figure illustrates the skill named for that class, with numbers and labels a student of that class meets.",
    "The template's rule holds (a landing on the line, shaded parts within the whole, a triangle's angles summing to 180, a food chain starting with a plant).",
    "The caption is one sentence that says what the figure shows, and agrees with its numbers.",
    "A triangle's labels name its sides, never its angles; the app draws them on the sides.",
  ]),
};
