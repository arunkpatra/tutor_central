import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type TestTomorrowInput, TestTomorrowOutput } from "../schemas.js";
import { MESSAGE, spokenDay, whoLines } from "./message.js";
import { VOICE, blocks } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "3";


/** Test tomorrow in the parent's language (P10-TestTomorrow), with the English beside it for the tutor. The student
 *  is named, so the call needs their consent (start_ai_generation). The app signs it (Phase 14). */
export function request(input: TestTomorrowInput): ClaudeRequest<TestTomorrowOutput> {
  return {
    model: modelFor("test_tomorrow", "draft").model,
    effort: "medium",
    version: VERSION,
    system: blocks([VOICE, MESSAGE, "Say the student's test is tomorrow and the portions when given; four sentences at most."], [
      input.revise ? "Then one thing to go over this evening, as given." : "",
    ]),
    text: [
      ...whoLines(input),
      `Test: ${input.title} (${input.subject}), ${spokenDay(input.date)}.`,
      input.portions ? `Portions: ${input.portions}.` : "",
      input.revise ? `To go over this evening: ${input.revise}.` : "",
    ]
      .filter(Boolean)
      .join("\n"),
    schema: TestTomorrowOutput,
  };
}
