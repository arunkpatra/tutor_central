import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { MessageOutput, type NotOnTrackInput } from "../schemas.js";
import { MESSAGE, whoLines } from "./message.js";
import { VOICE } from "./shared.js";

/** The message to the parent of a student not on track (P10-NotOnTrack-Message), in Hindi, Hinglish or Kannada (the
 *  English one is a template on the phone): what is hard, what we are doing, what helps at home, a five-minute talk. */
export function request(input: NotOnTrackInput): ClaudeRequest<MessageOutput> {
  return {
    model: modelFor("not_on_track"),
    effort: "medium",
    system: [
      VOICE,
      MESSAGE,
      `Say what is hard, what we are doing in class, ${input.atHome ? "what helps at home, " : ""}and ask for five minutes to talk this week; kind and plain, never blaming the student.`,
    ].join(" "),
    text: [
      ...whoLines(input),
      `Finding hard: ${input.hard.join(", ")}.`,
      input.reasons.length > 0 ? `Why: ${input.reasons.join("; ")}.` : "",
      `What we are doing: ${input.doing}.`,
      input.atHome ? `At home: ${input.atHome}.` : "",
    ]
      .filter(Boolean)
      .join("\n"),
    schema: MessageOutput,
  };
}
