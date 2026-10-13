import { request } from "../../prompts/sheet.js";
import type { SheetInput, SheetOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { proofHolds } from "../arith.js";
import { rubric } from "./rubric.js";

/** A group's practice set or homework (P10-Sheet): exactly the questions asked, numbered from 1, each answer right and
 *  agreeing with its proof. */
export const sheet: Kind<SheetInput, SheetOutput> = {
  kind: "sheet",
  classLevel: (input) => input.classLevel,
  draft: (input) => request(input),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    if (draft.questions.length !== input.questions) findings.push({ item: "questions", problem: `there are ${draft.questions.length} questions; exactly ${input.questions} were asked` });
    draft.questions.forEach((q, i) => {
      if (q.number !== i + 1) findings.push({ item: `question ${i + 1}`, problem: `it is numbered ${q.number}; number from 1 in order` });
      if (q.text.length > 600) findings.push({ item: `question ${q.number}`, problem: "it is longer than 600 characters" });
      if (q.proof && !proofHolds(q.proof)) findings.push({ item: `question ${q.number}`, problem: `its proof ${q.proof.expression} does not equal ${q.proof.equals}` });
    });
    return findings;
  },
  rubric: rubric([
    "Exactly the number of questions asked, on the skills named, in their order, easiest first.",
    "Every answer is right. Where an answer comes with a proof, the answer says the same value as the proof.",
    "A practice set fits one class sitting; homework fits one evening.",
  ]),
};
