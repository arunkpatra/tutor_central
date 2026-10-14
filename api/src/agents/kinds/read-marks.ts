import type { DecodedImage } from "../../images.js";
import { request } from "../../prompts/read-marks.js";
import type { ReadMarksDraftOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";

export type ReadMarksAgentInput = { pages: DecodedImage[]; studentName: string; studentId: string; subjects: string[] };

const ISO = /^\d{4}-\d{2}-\d{2}$/;

/** Marks read from a report card or a marked test (P14-Marks-Reading): each score within its maximum, a date ISO or
 *  none; a photo with no marks refused before any check. The tutor checks every row before it is kept. */
export const readMarks: Kind<ReadMarksAgentInput, ReadMarksDraftOutput> = {
  kind: "read_marks",
  student: (input) => ({ id: input.studentId, name: input.studentName }),
  draft: (input) => request(input.pages, input.studentName, input.subjects),
  empty: (draft) => draft.marks.length === 0,
  verify: (_input, draft) => {
    const findings: Finding[] = [];
    for (const row of draft.marks) {
      const item = `${row.subject} · ${row.test}`;
      if (row.score > row.max) findings.push({ item, problem: `${row.score} of ${row.max}` });
      if (row.date !== null && (!ISO.test(row.date) || Number.isNaN(Date.parse(row.date)))) findings.push({ item, problem: `the date ${row.date} is not YYYY-MM-DD` });
    }
    return findings;
  },
  rubric: [
    "- Each row is one subject's test as the page prints it: the subject, the test's name, the score and the maximum as printed; nothing is invented.",
    "- A date only when the page prints one, as YYYY-MM-DD; a row the page does not let you read is left out.",
  ].join("\n"),
};
