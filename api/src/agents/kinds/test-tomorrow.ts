import { request } from "../../prompts/test-tomorrow.js";
import type { MessageOutput, TestTomorrowInput } from "../../schemas.js";
import type { Kind } from "../agent.js";
import { messageFindings, messageRubric } from "./message.js";

/** Test tomorrow in the parent's language (P10-TestTomorrow). */
export const testTomorrow: Kind<TestTomorrowInput, MessageOutput> = {
  kind: "test_tomorrow",
  draft: (input) => request(input),
  student: (input) => ({ id: input.studentId, name: input.studentName }),
  verify: (input, draft) => {
    const asked = request(input);
    return messageFindings({ ...input, facts: [asked.text, asked.system.own] }, draft);
  },
  rubric: messageRubric(["It says the test is tomorrow with its day, the portions when given, and one thing to go over this evening when given; four sentences at most."]),
};
