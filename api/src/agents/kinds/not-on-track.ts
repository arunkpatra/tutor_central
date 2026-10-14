import { request } from "../../prompts/not-on-track.js";
import type { MessageOutput, NotOnTrackInput } from "../../schemas.js";
import type { Kind } from "../agent.js";
import { messageFindings, messageRubric } from "./message.js";

/** The message to the parent of a student not on track (P10-NotOnTrack-Message). */
export const notOnTrack: Kind<NotOnTrackInput, MessageOutput> = {
  kind: "not_on_track",
  draft: (input) => request(input),
  student: (input) => ({ id: input.studentId, name: input.studentName }),
  verify: (input, draft) => {
    const asked = request(input);
    return messageFindings({ ...input, facts: [asked.text, asked.system.own] }, draft);
  },
  rubric: messageRubric(["It says what is hard, what the class is doing about it, what helps at home when given, and asks for five minutes to talk this week; kind, never blaming."]),
};
