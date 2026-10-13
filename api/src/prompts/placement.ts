import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type ClassLevel, PlacementOutput } from "../schemas.js";
import { VOICE, blocks, LIMITS, MATHS, syllabusFacts } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "4";

/** The placement (P10-Placement): one question per chapter, or per step of the ladder, that tells whether a student has
 *  its most basic idea. Chapters and a class only; no student is named. */
export function request(classLevel: ClassLevel, subject: string, chapters: string[]): ClaudeRequest<PlacementOutput> {
  return {
    model: modelFor("placement", "draft", classLevel).model,
    effort: "medium",
    version: VERSION,
    system: blocks([
      VOICE,
      "You write one question per chapter that tells whether a student has the chapter's most basic idea, in the chapters' order.",
      "A student who knows the chapter answers it aloud in a few words; give the expected answer in at most twelve words.",
      "No multiple choice, no trick questions.",
      MATHS,
      LIMITS.placement,
      syllabusFacts(classLevel, subject),
    ], [`Return exactly ${chapters.length} question${chapters.length === 1 ? "" : "s"}, the chapter field repeating the chapter as given.`]),
    text: `Class ${classLevel} ${subject}. One question for each chapter of the placement: ${chapters.map((c) => `"${c}"`).join(", ")}.`,
    schema: PlacementOutput,
  };
}
