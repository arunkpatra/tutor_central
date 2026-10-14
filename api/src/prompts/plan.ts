import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type PlanInput, PlanOutput } from "../schemas.js";
import { VOICE, blocks, LIMITS, syllabusFacts } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "4";

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

/** A first topic for a group whose record names none yet (plan decision 1): the chapter a class is usually at in that
 *  month of the Indian school year, and its first skill, as a skill name the app can teach and check. */
export function request(input: PlanInput): ClaudeRequest<PlanOutput> {
  return {
    model: modelFor("plan", "draft", input.groups[0]?.classLevel ?? "8").model,
    effort: "medium",
    version: VERSION,
    system: blocks([
      VOICE,
      "For each group, name the chapter a class of that level is usually at in the given month of the school year (June to March) and one skill from it, as a short skill name a tutor can teach in one class and check with one question.",
      "Chapter names as the common textbook for that board and class prints them: the chapter's title alone, without its number; no text from inside a book.",
      "Where a list of the class's chapters is given below, name a chapter from that list exactly as it is printed (either board), and one at the month's place in the year: June is the first month of ten and March the last, so in October a class is about two fifths of the way through the list.",
      "Where no list of the class's chapters is given, a plain topic name the class studies then (Birds and flight) is better than a chapter title you are not sure belongs to that class's book.",
      LIMITS.plan,
    ], [...new Set(input.groups.map((g) => syllabusFacts(g.classLevel, g.subject)))]),
    text: [`${MONTHS[input.month - 1]}.`, ...input.groups.map((g) => `Group ${g.groupNo}: class ${g.classLevel} ${g.subject}.`)].join("\n"),
    schema: PlanOutput,
  };
}
