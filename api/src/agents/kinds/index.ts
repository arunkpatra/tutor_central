import type { AIKind } from "../../db.js";
import type { Kind } from "../agent.js";
import { brief } from "./brief.js";
import { canDo } from "./can-do.js";
import { check } from "./check.js";
import { checkPaper } from "./check-paper.js";
import { figure } from "./figure.js";
import { gapReport } from "./gap-report.js";
import { mock } from "./mock.js";
import { note } from "./note.js";
import { notOnTrack } from "./not-on-track.js";
import { paper } from "./paper.js";
import { parseSchool } from "./parse-school.js";
import { parseTextbook } from "./parse-textbook.js";
import { placement } from "./placement.js";
import { progressNote } from "./progress-note.js";
import { homework, worksheet } from "./question-set.js";
import { readMarks } from "./read-marks.js";
import { scanRegister } from "./scan-register.js";
import { plan } from "./plan.js";
import { sheet } from "./sheet.js";
import { testTomorrow } from "./test-tomorrow.js";
import { workedExample } from "./worked-example.js";

/** Every kind on its agent (D99; the parents' four, the exam's four and V1's five from Phase 21). */
const KINDS = {
  sheet, worked_example: workedExample, figure, brief, check, placement, plan, parse_textbook: parseTextbook, parse_school: parseSchool,
  note, can_do: canDo, test_tomorrow: testTomorrow, not_on_track: notOnTrack,
  mock, gap_report: gapReport, check_paper: checkPaper, read_marks: readMarks,
  paper, homework, worksheet, progress_note: progressNote, scan_register: scanRegister,
} as const;

export function kindFor(kind: AIKind): Kind<unknown, unknown> | null {
  return ((KINDS as Record<string, unknown>)[kind] as Kind<unknown, unknown> | undefined) ?? null;
}

/** Each moved kind's rubric, by kind: the words its version pins (src/prompts/registry.ts). */
export function rubrics(): Record<string, string> {
  return Object.fromEntries(Object.entries(KINDS).map(([kind, spec]) => [kind, spec.rubric ?? ""]));
}

export { brief, canDo, check, checkPaper, figure, gapReport, homework, mock, note, notOnTrack, paper, parseSchool, parseTextbook, placement, plan, progressNote, readMarks, scanRegister, sheet, testTomorrow, workedExample, worksheet };
