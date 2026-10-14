import { first } from "../../prompts/message.js";
import { request } from "../../prompts/progress-note.js";
import type { NoteInput, NoteOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { signsOff } from "./message.js";
import { rubric } from "./rubric.js";

/** The sentences of a note: each ends at a full stop, a question mark or an exclamation, or at the end of the text. */
const sentences = (text: string) => text.split(/(?<=[.?!])\s+/).map((s) => s.trim()).filter(Boolean);

/** A progress note to the parent (Make's V1): four to six sentences, the parent's and the student's first names in it,
 *  no sign-off (the app signs it). The student is named, so the gate asks their parent's consent (D62). */
export const progressNote: Kind<NoteInput, NoteOutput> = {
  kind: "progress_note",
  draft: (input) => request(input),
  student: (input) => (input.studentId ? { id: input.studentId, name: input.studentName } : undefined),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const said = sentences(draft.note);
    if (said.length < 4 || said.length > 6) findings.push({ item: "length", problem: `${said.length} sentences; four to six` });
    const names = [first(input.studentName), ...(input.parentName ? [first(input.parentName)] : [])];
    const missing = names.filter((name) => !draft.note.includes(name));
    if (missing.length) findings.push({ item: "names", problem: `call them by first name: ${missing.join(" and ")} is not in the note` });
    if (signsOff(said.at(-1) ?? "")) findings.push({ item: "sign-off", problem: "end with the last sentence of the note: the app adds the signature" });
    return findings;
  },
  rubric: rubric([
    "A progress note to the parent, by first name, about the student, by first name: one paragraph of four to six sentences, sent on WhatsApp.",
    "Only what the tutor has seen and the attendance line when given; honest, never blaming; warm or plain as asked; no signature, name or sign-off such as Regards at the end (a closing line to the parent, such as happy to talk, is a sentence of the note, not a sign-off).",
  ]),
};
