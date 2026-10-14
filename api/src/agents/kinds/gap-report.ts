import { request } from "../../prompts/gap-report.js";
import type { GapReportInput, GapReportOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";

/** A day's line is asked at 160 characters; a little room before it is a finding (the schema allows 200). */
const LINE = 180;

/** The gap report after a marked mock (P10-GapReport): one line per day left, each short; the student named for the
 *  consent gate only. */
export const gapReport: Kind<GapReportInput, GapReportOutput> = {
  kind: "gap_report",
  classLevel: (input) => input.classLevel,
  student: (input) => ({ id: input.studentId }),
  draft: (input) => request(input),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    if (draft.days.length !== input.daysLeft) findings.push({ item: "days", problem: `${input.daysLeft} ${input.daysLeft === 1 ? "day" : "days"} left, ${draft.days.length} ${draft.days.length === 1 ? "line" : "lines"}` });
    for (const day of draft.days) if (day.line.length > LINE) findings.push({ item: day.title, problem: "the line is longer than 160 characters" });
    return findings;
  },
  rubric: [
    "- The summary is one sentence on what the marked mock showed, from the tallies given; nothing the tallies do not say.",
    "- One line per day left, the weakest skills first, each something a tutor does in one class (a worked example, a short set, the key read together).",
    "- Sentence case, no exclamation marks; a day's title is short.",
  ].join("\n"),
};
