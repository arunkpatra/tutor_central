import { request } from "../../prompts/note.js";
import type { MessageOutput, WeeklyNoteInput } from "../../schemas.js";
import type { Kind } from "../agent.js";
import { messageFindings, messageRubric } from "./message.js";

/** The weekly note to a parent (P10-Note), from the week's facts the record gives, with the tutor's own words. */
export const note: Kind<WeeklyNoteInput, MessageOutput> = {
  kind: "note",
  draft: (input) => request(input),
  student: (input) => ({ id: input.studentId, name: input.studentName }),
  verify: (input, draft) => {
    const asked = request(input);
    return messageFindings({ ...input, facts: [asked.text, asked.system.own] }, draft);
  },
  rubric: messageRubric([
    "It tells the week: what was taught, what went right, what to practise, what is coming, as the facts give them; a week with nothing new says so.",
    "A change the tutor asked for with Write again is an instruction to the writer, never a sentence of the message.",
  ]),
};
