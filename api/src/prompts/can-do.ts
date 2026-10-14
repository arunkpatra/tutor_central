import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type CanDoInput, MessageOutput } from "../schemas.js";
import { MESSAGE, whoLines } from "./message.js";
import { VOICE, blocks } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "4";

/** Can-now-do for a young student on the ladder (P10-CanNowDo): what moved up, what the student can now do, one thing
 *  to do at home (the app's fixed line per step, no AI) and what is next, in the parent's language. */
export function request(input: CanDoInput): ClaudeRequest<MessageOutput> {
  const l = input.ladder;
  return {
    model: modelFor("can_do", "draft").model,
    effort: "medium",
    version: VERSION,
    system: blocks([VOICE, MESSAGE, "This is a short note on what a young student can now do."]),
    text: [
      ...whoLines(input),
      l.movedUp.length > 0 ? `Moved up this week: ${l.movedUp.map((m) => `${m.area} to ${m.step}`).join(", ")}.` : "",
      `Can now do: ${l.canDo.join(", ")}.`,
      `At home: ${l.atHome}.`,
      l.next.length > 0 ? `Next: ${l.next.join(", ")}.` : "",
      "Write the note: what the student can now do, one thing to do at home, what comes next.",
    ]
      .filter(Boolean)
      .join("\n"),
    schema: MessageOutput,
  };
}
