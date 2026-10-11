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
      w.taught.length > 0 ? `Taught: ${w.taught.join(", ")}.` : "",
      w.right ? `Got right: ${w.right}.` : "",
      w.practise.length > 0 ? `To practise: ${w.practise.join(", ")}.` : "",
      w.coming.length > 0 ? `Coming: ${w.coming.join(", ")}.` : "",
      w.attendance ? `Attendance: ${w.attendance}.` : "",
      "Write the week's note: what was taught, what the student got right, what to practise at home and what is coming.",
    ]
      .filter(Boolean)
      .join("\n"),
    schema: MessageOutput,
  };
}
