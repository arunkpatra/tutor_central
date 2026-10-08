import type { ClaudeRequest } from "../claude.js";
import { type NoteInput, NoteOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

const firstName = (name: string) => name.trim().split(/\s+/)[0] ?? name;

/** A progress note to the parent, in the tutor's voice, from what the tutor has seen. The app adds the signature. */
export function request(input: NoteInput): ClaudeRequest<NoteOutput> {
  const tone = input.tone === "warm" ? "warm and encouraging, still honest" : "plain and factual, still kind";
  return {
    model: "claude-sonnet-5-5",
    effort: "medium",
    system: [
      VOICE,
      `You write short progress notes from ${input.tutorName} at ${input.centreName} to a parent, sent on WhatsApp.`,
      "Address the parent by first name and call the child by first name.",
      "One paragraph of four to six sentences. Use only what the tutor has seen and the attendance line when given.",
      `Tone: ${tone}.`,
      "End with the last sentence of the note: no signature, no name, no sign-off (the app adds the signature).",
    ].join(" "),
    text: [
      `Parent: ${input.parentName ? firstName(input.parentName) : "the parent (no name given: start with Hello)"}.`,
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
