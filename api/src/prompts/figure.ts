import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type ClassLevel, type FigureKind, FigureOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

const RULES: Record<FigureKind, string> = {
  number_line: "number_line: from, to, step, start and jumps; start and the landing (start plus the jumps) lie on the line; at most 40 steps.",
  fraction_bar: "fraction_bar: parts (1 to 24), shaded (at most parts) and the label as a fraction.",
  place_value: "place_value: one whole number up to 9,999,999.",
  unit_circle: "unit_circle: one angle in degrees, 0 to 360.",
  triangle: "triangle: three angles that sum to 180 and three side labels, labels[i] the side opposite angles[i]; use 90 for a right angle.",
  labelled_cell: "labelled_cell: plant or animal, and one to five part names as the class's chapter names them.",
  food_chain: "food_chain: two to six links, the first a plant, each eaten by the next.",
};

/** A figure's spec (D59): the app draws it; the model only fills the template's numbers and labels. */
export function request(kind: FigureKind, classLevel: ClassLevel, subject: string, skill: string): ClaudeRequest<FigureOutput> {
  return {
    model: modelFor("figure", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You fill one figure template with the numbers and labels that illustrate a skill; the app draws it.",
      RULES[kind],
      "The caption is one sentence the tutor can say while pointing at the figure.",
    ].join(" "),
    text: `Class ${classLevel} ${subject}, the skill "${skill}". Fill the template ${kind}.`,
    schema: FigureOutput,
  };
}
