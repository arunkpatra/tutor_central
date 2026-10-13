import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type NoteInput, NoteOutput } from "../schemas.js";
import { first } from "./message.js";
import { VOICE, blocks } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "2";

/** A progress note to the parent, in the tutor's voice, from what the tutor has seen. The app adds the signature. */
export function request(input: NoteInput): ClaudeRequest<NoteOutput> {
  const tone = input.tone === "warm" ? "warm and encouraging, still honest" : "plain and factual, still kind";
  return {
    model: modelFor("progress_note", "draft").model,
    effort: "medium",
    version: VERSION,
    system: blocks([
      VOICE,
      "You write short progress notes from a tutor to a parent, sent on WhatsApp.",
      "Address the parent by first name and call the child by first name.",
      "One paragraph of four to six sentences. Use only what the tutor has seen and the attendance line when given.",
      "End with the last sentence of the note: no signature, no name, no sign-off (the app adds the signature).",
    ], [`The tutor is ${input.tutorName} at ${input.centreName}.`, `Tone: ${tone}.`]),
    text: [
      `Parent: ${input.parentName ? first(input.parentName) : "the parent (no name given: start with Hello)"}.`,
      `Student: ${input.studentName}, ${input.classLevel}, ${input.subject}.`,
      input.attendanceLine ? `This month: ${input.attendanceLine}.` : null,
      `What the tutor has seen: ${input.observations}`,
      "Write the progress note.",
    ]
      .filter((line): line is string => line !== null)
      .join("\n"),
    schema: NoteOutput,
  };
}
