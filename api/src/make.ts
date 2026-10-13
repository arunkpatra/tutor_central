import { fromRequest, type Kind } from "./agents/agent.js";
import type { ClaudeRequest } from "./claude.js";
import type { AIKind } from "./db.js";
import { request as briefRequest } from "./prompts/brief.js";
import { request as canDoRequest } from "./prompts/can-do.js";
import { request as checkRequest } from "./prompts/check.js";
import { request as figureRequest } from "./prompts/figure.js";
import { request as gapReportRequest } from "./prompts/gap-report.js";
import { request as mockRequest } from "./prompts/mock.js";
import { request as notOnTrackRequest } from "./prompts/not-on-track.js";
import { request as noteRequest } from "./prompts/note.js";
import { request as placementRequest } from "./prompts/placement.js";
import { request as sheetRequest } from "./prompts/sheet.js";
import { request as testTomorrowRequest } from "./prompts/test-tomorrow.js";
import { request as workedExampleRequest } from "./prompts/worked-example.js";
import { type MakeInput, mockMarks } from "./schemas.js";

/** One made kind's call, as `run` (a route) and `recordedCall` (a job) take it: the kind recorded, the request Claude is
 *  asked, the student it names (the gate asks their consent, D62; the name words a refusal), and an answer that holds
 *  nothing to use. */
export type Made = {
  kind: AIKind;
  request: ClaudeRequest<unknown>;
  student?: string;
  studentName?: string;
  empty?: (made: unknown) => boolean;
};

function made<T>(kind: AIKind, request: ClaudeRequest<T>, rest: { student?: string; studentName?: string; empty?: (made: T) => boolean } = {}): Made {
  return { kind, request: request as ClaudeRequest<unknown>, ...rest, empty: rest.empty as ((made: unknown) => boolean) | undefined };
}

/** The call for a body of `/ai/make` (plan/phase-18-plan.md decision 12): the route and the plan and note jobs build the
 *  same call for the same kind. */
export function makeRequest(v: MakeInput): Made {
  switch (v.kind) {
    case "sheet":
      return made("sheet", sheetRequest(v));
    case "worked_example":
      return made("worked_example", workedExampleRequest(v.classLevel, v.subject, v.skill));
    case "figure":
      // The template asked for is the template answered; another is an unfit answer.
      return made("figure", figureRequest(v.figure, v.classLevel, v.subject, v.skill), { empty: (answer) => answer.figure.kind !== v.figure });
    case "brief":
      return made("brief", briefRequest(v.classLevel, v.subject, v.chapter));
    case "check":
      return made("check", checkRequest(v.classLevel, v.subject, v.skills));
    case "placement":
      return made("placement", placementRequest(v.classLevel, v.subject, v.chapters));
    case "mock":
      // A mock whose marks do not sum to the pattern's is an unfit answer, refused in words (Phase 13 decision 12).
      return made("mock", mockRequest(v), { empty: (answer) => mockMarks(answer) !== v.pattern.marks });
    case "gap_report":
      return made("gap_report", gapReportRequest(v), { student: v.studentId });
    case "test_tomorrow":
      return made("test_tomorrow", testTomorrowRequest(v), { student: v.studentId, studentName: v.studentName });
    case "note":
      return made("note", noteRequest(v), { student: v.studentId, studentName: v.studentName });
    case "can_do":
      return made("can_do", canDoRequest(v), { student: v.studentId, studentName: v.studentName });
    case "not_on_track":
      return made("not_on_track", notOnTrackRequest(v), { student: v.studentId, studentName: v.studentName });
  }
}

/** The kind's agent for a body (D99): the route and the jobs run the same agent for the same kind. Task 6 gives the
 *  group material its own kinds; until then each is its request drafted alone. */
export function makeAgent(v: MakeInput): Kind<unknown, unknown> {
  const made = makeRequest(v);
  return fromRequest(made.kind, made.request, { student: made.student, studentName: made.studentName, empty: made.empty, classLevel: "classLevel" in v ? v.classLevel : undefined });
}
