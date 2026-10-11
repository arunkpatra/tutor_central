import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type GapReportInput, GapReportOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** The gap report after a marked mock (P10-GapReport): one sentence on what it showed and one line per day left. The
 *  tallies by skill are the app's arithmetic; the student is named only for the consent gate, never in the prompt. */
export function request(input: GapReportInput): ClaudeRequest<GapReportOutput> {
  return {
    model: modelFor("gap_report", input.classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You write a tutor's plan for the last days before a school test from a marked mock: one sentence on what it showed, then one line per day left.",
      "Each day's line names what to revise and how (a worked example, a short set, a sorting set, the key read together); the weakest skills first.",
      "Nothing a tutor cannot do in one class. A day's title is short (\"Thursday\", \"Friday morning\").",
      "Each day's line is at most 160 characters; the summary at most 180 characters.",
    ].join(" "),
    text: [
      `Class ${input.classLevel} ${input.subject}. ${input.daysLeft} ${input.daysLeft === 1 ? "day" : "days"} left.`,
      "By skill:",
      ...input.bySkill.map((row) => `${row.skill}: ${row.right} of ${row.of}${row.note ? ` (${row.note})` : ""}`),
    ].join("\n"),
    schema: GapReportOutput,
  };
}
