import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type ClassLevel, WorkedExampleOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** The worked example for a skill (P10-WorkedExample): one problem a student of that class meets, solved one step at a
 *  time as the tutor says it aloud, and the common slip. */
export function request(classLevel: ClassLevel, subject: string, skill: string): ClaudeRequest<WorkedExampleOutput> {
  return {
    model: modelFor("worked_example", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You write one worked example a tutor shows a class one step at a time, saying each step aloud before the next.",
      "Each step has a short title and the working in one or two lines; two to six steps.",
      "The slip is the one mistake students of that class make most on this skill, in one sentence that starts 'A common slip here:'.",
    ].join(" "),
    text: `Class ${classLevel} ${subject}. One worked example for the skill "${skill}", with numbers from the class's textbook level.`,
    schema: WorkedExampleOutput,
  };
}
