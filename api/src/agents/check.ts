import { CheckVerdict } from "../schemas.js";
import type { DraftRequest } from "./agent.js";

/** What every check is told (D99): judge the draft against the kind's rubric, find, never rewrite. The arithmetic of a
 *  proof is the server's (src/agents/arith.ts); the checker compares the answer with its proof (review focus 2). */
const CHECK_RULES = [
  "You check a draft that was made for a tutor at a small tuition centre in India, against the rubric below.",
  "Judge only what the rubric asks. A matter of taste or wording is not a finding; a fact, a level, a limit or a format broken is.",
  "Where an answer comes with a proof (an expression and the value it equals), the answer must say the same value: an answer that does not agree with its proof is a finding.",
  "Answer pass true when the draft keeps every rule. Otherwise pass false, with one finding per problem: the item (a question's number, a step, a field, a chapter) in a few words and the problem in one sentence.",
  "Never rewrite the draft.",
].join(" ");

/** The check request for a draft: the rubric and the rules shared by every check of the kind (cached), the request and
 *  the draft as the turn. A photo the draft was read from is shown again, so the checker can hold it to the page. */
export function checkRequest<T>(rubric: string, asked: DraftRequest<T>, draft: T): DraftRequest<CheckVerdict> {
  return {
    system: { shared: `${CHECK_RULES}\n\nThe rubric:\n${rubric}`, own: "" },
    version: asked.version,
    text: [
      "What was asked:",
      asked.system.own,
      asked.text,
      "",
      "The draft, as JSON:",
      JSON.stringify(draft),
    ]
      .filter((line) => line !== undefined)
      .join("\n"),
    images: asked.images,
    schema: CheckVerdict,
  };
}

/** The repair's request: the draft's own request with the findings quoted, the same schema (D99). */
export function repairRequest<T>(asked: DraftRequest<T>, findings: { item: string; problem: string }[]): DraftRequest<T> {
  const fix = ["Fix these and change nothing else:", ...findings.map((f) => `- ${f.item}: ${f.problem}`)].join("\n");
  return { ...asked, system: { shared: asked.system.shared, own: [asked.system.own, fix].filter(Boolean).join("\n\n") } };
}
