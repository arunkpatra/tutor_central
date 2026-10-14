import { request } from "../../prompts/can-do.js";
import type { CanDoInput, MessageOutput } from "../../schemas.js";
import type { Kind } from "../agent.js";
import { messageFindings, messageRubric } from "./message.js";

/** Can-now-do for a young student on the ladder (P10-CanNowDo). */
export const canDo: Kind<CanDoInput, MessageOutput> = {
  kind: "can_do",
  draft: (input) => request(input),
  student: (input) => ({ id: input.studentId, name: input.studentName }),
  verify: (input, draft) => {
    const asked = request(input);
    return messageFindings({ ...input, facts: [asked.text, asked.system.own] }, draft);
  },
  rubric: messageRubric(["It says what the student can now do, the one thing to do at home as given, and what comes next."]),
};
