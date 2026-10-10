import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { BriefOutput, type ClassLevel } from "../schemas.js";
import { VOICE } from "./shared.js";

/** The tutor's brief for a chapter (P10-Brief): five minutes of reading before the class, as a colleague's note. */
export function request(classLevel: ClassLevel, subject: string, chapter: string): ClaudeRequest<BriefOutput> {
  return {
    model: modelFor("brief", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You write a colleague's note to a tutor about a chapter they teach this week: what it is about in one paragraph a tutor reads in a minute, the three mistakes students of that class make most with how to catch each in class, one worked example to use, and three lines to say in class.",
      "Plain, direct, no headings inside the fields, nothing copied from a textbook.",
    ].join(" "),
    text: `Class ${classLevel} ${subject}, the chapter "${chapter}".`,
    schema: BriefOutput,
  };
}
