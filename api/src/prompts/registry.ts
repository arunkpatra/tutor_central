import type { ClaudeRequest } from "../claude.js";
import type { DecodedImage } from "../images.js";
import { rubrics as kindRubrics } from "../agents/kinds/index.js";
import { sha256 } from "../price.js";
import { GenerateInput, MakeInput, type PlanInput } from "../schemas.js";
import * as brief from "./brief.js";
import * as canDo from "./can-do.js";
import * as check from "./check.js";
import * as checkPaper from "./check-paper.js";
import * as figure from "./figure.js";
import * as gapReport from "./gap-report.js";
import * as homework from "./homework.js";
import * as mock from "./mock.js";
import * as notOnTrack from "./not-on-track.js";
import * as note from "./note.js";
import * as paper from "./paper.js";
import * as parseSchool from "./parse-school.js";
import * as parseTextbook from "./parse-textbook.js";
import * as placement from "./placement.js";
import * as plan from "./plan.js";
import * as progressNote from "./progress-note.js";
import * as readMarks from "./read-marks.js";
import * as scanRegister from "./scan-register.js";
import * as sheet from "./sheet.js";
import * as testTomorrow from "./test-tomorrow.js";
import * as workedExample from "./worked-example.js";
import * as worksheet from "./worksheet.js";

/** Every prompt file by its kind, with one fixed input (the seed's names, invented facts), so its words can be hashed:
 *  `api/src/prompts/versions.json` pins each kind's VERSION to the hash of what it sends (D74), and a change to the words
 *  without a new VERSION is a red check (test/prompt-versions.test.ts; `bun prompts --write` rewrites the table). A kind
 *  moved onto its agent (Task 6) adds its rubric to what is hashed. */
const centreId = "22222222-2222-2222-2222-222222222222";
const studentId = "33333333-3333-3333-3333-333333333333";
const image: DecodedImage = { mediaType: "image/png", base64: "iVBORw0KGgo=", bytes: 8 };
const person = { centreId, studentId, studentName: "Hemanth Reddy", parentName: "Lakshmi Reddy", centreName: "Bright Minds Tuition", language: "en", classLevel: "8" };
const make = (body: Record<string, unknown>) => MakeInput.parse({ centreId, ...body });
// biome-ignore lint/suspicious/noExplicitAny: each V1 builder takes its own kind's body.
const v1 = (body: Record<string, unknown>) => GenerateInput.parse({ centreId, ...body }) as any;
// biome-ignore lint/suspicious/noExplicitAny: each made builder takes its own kind's body.
const as = (v: unknown) => v as any;

type Entry = { version: string; build(): ClaudeRequest<unknown> };
const entry = (module: { VERSION: string }, build: () => ClaudeRequest<unknown>): Entry => ({ version: module.VERSION, build });

export const PROMPTS: Record<string, Entry> = {
  paper: entry(paper, () => paper.request(v1({ kind: "paper", subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" }))),
  homework: entry(homework, () => homework.request(v1({ kind: "homework", subject: "Science", classLevel: "Class 8", topic: "Cell structure" }))),
  worksheet: entry(worksheet, () => worksheet.request(v1({ kind: "worksheet", subject: "Mathematics", classLevel: "Class 9", topic: "Linear equations", level: "medium" }))),
  progress_note: entry(progressNote, () => progressNote.request(v1({ kind: "progress_note", subject: "Mathematics", classLevel: "Class 10", studentId, studentName: "Hemanth Reddy", parentName: "Lakshmi Reddy", tutorName: "Meera", centreName: "Bright Minds Tuition", observations: "Careful with signs." }))),
  scan_register: entry(scanRegister, () => scanRegister.request(image) as ClaudeRequest<unknown>),
  check_paper: entry(checkPaper, () => checkPaper.request([image], "1. x = 5 (2 marks)", "Hemanth Reddy") as ClaudeRequest<unknown>),
  plan: entry(plan, () => plan.request({ centreId, month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] } as PlanInput) as ClaudeRequest<unknown>),
  sheet: entry(sheet, () => sheet.request(as(make({ kind: "sheet", classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], questions: 8 }))) as ClaudeRequest<unknown>),
  worked_example: entry(workedExample, () => workedExample.request("8", "Science", "Balance a chemical equation") as ClaudeRequest<unknown>),
  figure: entry(figure, () => figure.request("fraction_bar", "5", "Mathematics", "Compare simple fractions") as ClaudeRequest<unknown>),
  brief: entry(brief, () => brief.request("8", "Science", "Chemical reactions") as ClaudeRequest<unknown>),
  check: entry(check, () => check.request("8", "Science", ["Balance a chemical equation"]) as ClaudeRequest<unknown>),
  placement: entry(placement, () => placement.request("5", "Mathematics", ["The Fish Tale"]) as ClaudeRequest<unknown>),
  mock: entry(mock, () => mock.request(as(make({ kind: "mock", classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"], pattern: { marks: 25, durationMinutes: 40 } }))) as ClaudeRequest<unknown>),
  gap_report: entry(gapReport, () => gapReport.request(as(make({ kind: "gap_report", studentId, classLevel: "8", subject: "Science", daysLeft: 2, bySkill: [{ skill: "Balancing equations", right: 3, of: 10 }] }))) as ClaudeRequest<unknown>),
  test_tomorrow: entry(testTomorrow, () => testTomorrow.request(as(make({ kind: "test_tomorrow", ...person, subject: "Science", title: "Science unit test", date: "2026-10-08" }))) as ClaudeRequest<unknown>),
  note: entry(note, () => note.request(as(make({ kind: "note", ...person, week: { monday: "2026-10-05", taught: ["Balancing equations"], practise: [], coming: [] } }))) as ClaudeRequest<unknown>),
  can_do: entry(canDo, () => canDo.request(as(make({ kind: "can_do", ...person, classLevel: "2", ladder: { movedUp: [], canDo: ["Read words"], atHome: "Five words a day", next: [] } }))) as ClaudeRequest<unknown>),
  not_on_track: entry(notOnTrack, () => notOnTrack.request(as(make({ kind: "not_on_track", ...person, hard: ["Balancing equations"], reasons: [], doing: "The worked example again" }))) as ClaudeRequest<unknown>),
  parse_school: entry(parseSchool, () => parseSchool.request({ text: "Science unit test 3 on Friday 16 October.", image: null, today: "2026-10-13", schools: [], classLevels: ["8"] }) as ClaudeRequest<unknown>),
  parse_textbook: entry(parseTextbook, () => parseTextbook.request(image, "8", "Science") as ClaudeRequest<unknown>),
  read_marks: entry(readMarks, () => readMarks.request([image], "Hemanth Reddy", ["Mathematics"]) as ClaudeRequest<unknown>),
};

/** A kind's words as hashed: the shared and own system words and the turn's text of its sample request, and the rubric
 *  of a kind its agent checks. */
export function promptWords(kind: string, rubric?: string): string {
  const r = PROMPTS[kind]?.build();
  if (!r) throw new Error(`no prompt ${kind}`);
  return [r.system.shared, r.system.own, r.text, rubric ?? ""].join("\n---\n");
}

export type VersionTable = Record<string, { version: string; hash: string }>;

/** Each kind's VERSION and the hash of its words, as `versions.json` holds them. */
export function versionTable(rubrics: Record<string, string> = kindRubrics()): VersionTable {
  return Object.fromEntries(Object.entries(PROMPTS).map(([kind, e]) => [kind, { version: e.version, hash: sha256(promptWords(kind, rubrics[kind])) }]));
}

/** What is wrong with a written table against the prompts as they are: a kind whose words moved under the same version, a
 *  version moved with the same words, or a kind missing or left over. Empty when it holds. */
export function versionProblems(written: VersionTable, current: VersionTable): string[] {
  const problems: string[] = [];
  for (const [kind, now] of Object.entries(current)) {
    const was = written[kind];
    if (!was) problems.push(`${kind}: not in versions.json`);
    else if (was.hash !== now.hash && was.version === now.version) problems.push(`${kind}: its words changed; raise VERSION (now ${now.version})`);
    else if (was.hash === now.hash && was.version !== now.version) problems.push(`${kind}: VERSION changed with the same words`);
    else if (was.hash !== now.hash || was.version !== now.version) problems.push(`${kind}: versions.json is stale; run bun prompts --write`);
  }
  for (const kind of Object.keys(written)) if (!current[kind]) problems.push(`${kind}: in versions.json but no prompt`);
  return problems;
}
