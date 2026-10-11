import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { MessageOutput, type WeeklyNoteInput } from "../schemas.js";
import { MESSAGE, spokenDate, whoLines } from "./message.js";
import { VOICE } from "./shared.js";

/** The weekly note to a parent (P10-Note): the week's facts from the student's record, worked out on the phone, in the
 *  parent's language with the English beside it. A fact that is empty is left out of the text, and the model is told to
 *  say nothing of it. */
export function request(input: WeeklyNoteInput): ClaudeRequest<MessageOutput> {
  const w = input.week;
  return {
    model: modelFor("note"),
    effort: "medium",
    system: [VOICE, MESSAGE, "This is the weekly note."].join(" "),
    text: [
      ...whoLines(input),
      `Week of ${spokenDate(w.monday)}.`,
      w.taught.length > 0 ? `Taught: ${w.taught.join(", ")}.` : "Taught: nothing new this week.",
      w.right ? `Got right: ${w.right}.` : "",
      w.practise.length > 0 ? `To practise: ${w.practise.join(", ")}.` : "",
      w.coming.length > 0 ? `Coming: ${w.coming.join(", ")}.` : "",
      w.attendance ? `Attendance: ${w.attendance}.` : "",
      input.tutorSays ? `The tutor adds: ${input.tutorSays}` : "",
      ask(w, input.tutorSays !== undefined),
    ]
      .filter(Boolean)
      .join("\n"),
    schema: MessageOutput,
  };
}

/** "Write the week's note: …" naming only the parts the facts hold, so the model is never asked for one it lacks; the
 *  tutor's own words from Make come last. */
function ask(w: WeeklyNoteInput["week"], tutorAdds: boolean): string {
  const parts = [
    w.taught.length > 0 ? "what was taught" : "",
    w.right ? "what the student got right" : "",
    w.practise.length > 0 ? "what to practise at home" : "",
    w.coming.length > 0 ? "what is coming" : "",
    tutorAdds ? "what the tutor adds" : "",
  ].filter(Boolean);
  if (parts.length === 0) return "Write a short note that the week had nothing new to report.";
  const list = parts.length === 1 ? parts[0] : `${parts.slice(0, -1).join(", ")} and ${parts.at(-1)}`;
  return `Write the week's note: ${list}.`;
}
