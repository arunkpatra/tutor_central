import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { ChecksOutput, type ClassLevel } from "../schemas.js";
import { VOICE } from "./shared.js";

const COUNT = ["One question", "Two questions", "Three questions"];

/** The close's checks (docs/spec-v2.md section 6): one short question per skill, asked aloud and tapped right or wrong.
 *  Skills and a class only; no student is named. */
export function request(classLevel: ClassLevel, subject: string, skills: string[]): ClaudeRequest<ChecksOutput> {
  return {
    model: modelFor("check", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You write questions a tutor asks a student aloud at the end of a class, one per skill, in the skill's order.",
      "Each question is one sentence a student of that class answers in a few words or one line of working; give the expected answer in at most twelve words.",
      "Use numbers and examples a student would meet in the textbook for that class; no multiple choice, no trick questions.",
      `Return exactly ${skills.length} question${skills.length === 1 ? "" : "s"}, the skill field repeating the skill as given.`,
    ].join(" "),
    text: `Class ${classLevel} ${subject}. ${COUNT[skills.length - 1] ?? "Questions"}, one for each skill: ${skills.map((s) => `"${s}"`).join(", ")}.`,
    schema: ChecksOutput,
  };
}
