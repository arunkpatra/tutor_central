import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type PlanInput, PlanOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

/** A first topic for a group whose record names none yet (plan decision 1): the chapter a class is usually at in that
 *  month of the Indian school year, and its first skill, as a skill name the app can teach and check. */
export function request(input: PlanInput): ClaudeRequest<PlanOutput> {
  return {
    model: modelFor("plan", input.groups[0]?.classLevel ?? "8"),
    effort: "medium",
    system: [
      VOICE,
      "For each group, name the chapter a class of that level is usually at in the given month of the school year (June to March) and one skill from it, as a short skill name a tutor can teach in one class and check with one question.",
      "Chapter names as the common textbook for that board and class prints them; no text from inside a book.",
    ].join(" "),
    text: [`${MONTHS[input.month - 1]}.`, ...input.groups.map((g) => `Group ${g.groupNo}: class ${g.classLevel} ${g.subject}.`)].join("\n"),
    schema: PlanOutput,
  };
}
