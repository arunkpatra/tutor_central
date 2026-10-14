import type { DecodedImage } from "../../images.js";
import { request } from "../../prompts/check-paper.js";
import type { CheckOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";

/** Marking from a photo (Check a paper, D73): the pages, the scheme's text, its questions and marks when the scheme is a
 *  stored paper or mock (none for a typed scheme), the student. */
export type CheckPaperAgentInput = {
  pages: DecodedImage[];
  scheme: string;
  schemeQuestions: { number: number; marks: number }[];
  studentName: string;
  studentId?: string;
};

/** Every scheme question marked once, out of the scheme's marks, never above them; a mark never above its own maximum.
 *  The marks are suggestions the tutor checks. */
export const checkPaper: Kind<CheckPaperAgentInput, CheckOutput> = {
  kind: "check_paper",
  student: (input) => (input.studentId ? { id: input.studentId, name: input.studentName } : undefined),
  draft: (input) => request(input.pages, input.scheme, input.studentName),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const seen = new Set<number>();
    for (const q of draft.questions) {
      if (seen.has(q.number)) findings.push({ item: `question ${q.number}`, problem: `question ${q.number} is marked twice` });
      seen.add(q.number);
      const scheme = input.schemeQuestions.find((s) => s.number === q.number);
      if (scheme && q.of !== scheme.marks) findings.push({ item: `question ${q.number}`, problem: `question ${q.number} is out of ${scheme.marks} in the scheme, not ${q.of}` });
      else if (q.marks > q.of) findings.push({ item: `question ${q.number}`, problem: `question ${q.number}: ${q.marks} marks of ${q.of}` });
    }
    for (const s of input.schemeQuestions) if (!seen.has(s.number)) findings.push({ item: `question ${s.number}`, problem: `question ${s.number} of the scheme is not marked` });
    return findings;
  },
  rubric: [
    "- Every question of the scheme is marked once, out of its marks in the scheme, never above them.",
    "- A mark agrees with what the pages show against the scheme's answer; a question with no answer on the pages gets 0 and the note 'Not attempted'.",
    "- Each note says in one line what was right or wrong; the summary is one line on what to work on.",
    "- Nothing is read that the pages do not show.",
    "- A part mark within the question's marks, for a part answer the pages show, is the tutor's to judge: never a finding.",
  ].join("\n"),
};
