import { request } from "../../prompts/worked-example.js";
import type { ClassLevel, WorkedExampleOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { proofHolds } from "../arith.js";
import { rubric } from "./rubric.js";

export type WorkedExampleInput = { classLevel: ClassLevel; subject: string; skill: string };

/** The worked example's rules, shared with the brief's (its worked example): the answer's proof and the slip's proof hold,
 *  and the slip's wrong value is not the right one (the first nightly's brief, D105). */
export function workedExampleFindings(example: WorkedExampleOutput, at = ""): Finding[] {
  const findings: Finding[] = [];
  if (example.proof && !proofHolds(example.proof)) findings.push({ item: `${at}answer`, problem: `the proof ${example.proof.expression} does not equal ${example.proof.equals}` });
  if (!example.slip.startsWith("A common slip here:")) findings.push({ item: `${at}slip`, problem: "it must start 'A common slip here:'" });
  const slip = example.slipProof;
  if (slip && !proofHolds(slip)) findings.push({ item: `${at}slip`, problem: `the slip's proof ${slip.expression} does not equal ${slip.equals}` });
  else if (slip && example.proof && slip.equals === example.proof.equals) findings.push({ item: `${at}slip`, problem: "the slip's value equals the right answer" });
  return findings;
}

export const workedExample: Kind<WorkedExampleInput, WorkedExampleOutput> = {
  kind: "worked_example",
  classLevel: (input) => input.classLevel,
  maths: true,
  draft: (input) => request(input.classLevel, input.subject, input.skill),
  verify: (_input, draft) => workedExampleFindings(draft),
  rubric: rubric([
    "One problem on the skill named, solved in two to six steps a tutor says aloud, each step following from the one before.",
    "Every step's working is right and the final answer is right; where the answer comes with a proof, they agree.",
    "The slip is the mistake students of that class make most on this skill.",
  ]),
};
