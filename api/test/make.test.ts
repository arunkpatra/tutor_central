import { expect, test } from "bun:test";
import { fakeClaude, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { JOB_AGENT_BUDGET_MS, recordedCall } from "../src/jobs/call.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import type { StepContext } from "../src/jobs/types.js";
import { makeAgent, makeRequest } from "../src/make.js";
import { request as briefRequest } from "../src/prompts/brief.js";
import { request as canDoRequest } from "../src/prompts/can-do.js";
import { request as checkRequest } from "../src/prompts/check.js";
import { request as figureRequest } from "../src/prompts/figure.js";
import { request as gapReportRequest } from "../src/prompts/gap-report.js";
import { request as mockRequest } from "../src/prompts/mock.js";
import { request as notOnTrackRequest } from "../src/prompts/not-on-track.js";
import { request as noteRequest } from "../src/prompts/note.js";
import { request as placementRequest } from "../src/prompts/placement.js";
import { request as sheetRequest } from "../src/prompts/sheet.js";
import { request as testTomorrowRequest } from "../src/prompts/test-tomorrow.js";
import { request as workedExampleRequest } from "../src/prompts/worked-example.js";
import { MakeInput } from "../src/schemas.js";

// One builder per made kind (plan/phase-18-plan.md decision 12): the route and the jobs build the same call. Each
// kind's expectations are the arguments `routes/v2.ts` gave `run` before the move.
const centreId = "22222222-2222-2222-2222-222222222222";
const studentId = "33333333-3333-3333-3333-333333333333";
const person = { studentId, studentName: "Dev Kumar", parentName: "Ramesh Kumar", centreName: "Bright Minds Tuition", language: "hi", classLevel: "8" };
const bodies: Record<string, Record<string, unknown>> = {
  sheet: { kind: "sheet", classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], questions: 8 },
  worked_example: { kind: "worked_example", classLevel: "8", subject: "Science", skill: "Balance a chemical equation" },
  figure: { kind: "figure", figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "Compare simple fractions" },
  brief: { kind: "brief", classLevel: "8", subject: "Science", chapter: "Chemical reactions" },
  check: { kind: "check", classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"] },
  placement: { kind: "placement", classLevel: "5", subject: "Mathematics", chapters: ["The Fish Tale"] },
  mock: { kind: "mock", classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"], pattern: { marks: 25, durationMinutes: 40 } },
  gap_report: { kind: "gap_report", studentId, classLevel: "8", subject: "Science", daysLeft: 2, bySkill: [{ skill: "Balancing equations", right: 3, of: 10 }] },
  test_tomorrow: { kind: "test_tomorrow", studentId, studentName: "Dev Kumar", centreName: "Bright Minds Tuition", language: "hi", subject: "Science", title: "Science unit test", date: "2026-10-08" },
  note: { kind: "note", ...person, week: { monday: "2026-10-05", taught: ["Balancing equations"], practise: [], coming: [] } },
  can_do: { kind: "can_do", ...person, classLevel: "2", ladder: { movedUp: [], canDo: ["Read words"], atHome: "Five words a day", next: [] } },
  not_on_track: { kind: "not_on_track", ...person, hard: ["Balancing equations"], reasons: [], doing: "Teaching it again with the worked example" },
};
const parsed = (kind: string) => MakeInput.parse({ centreId, ...bodies[kind] });

test("every made kind builds the route's call: its kind, its request, the student it names", () => {
  // biome-ignore lint/suspicious/noExplicitAny: each builder takes its own kind's body.
  const route: Record<string, (v: any) => { model: string; system: { shared: string; own: string } }> = {
    sheet: sheetRequest,
    worked_example: (v) => workedExampleRequest(v.classLevel, v.subject, v.skill),
    figure: (v) => figureRequest(v.figure, v.classLevel, v.subject, v.skill),
    brief: (v) => briefRequest(v.classLevel, v.subject, v.chapter),
    check: (v) => checkRequest(v.classLevel, v.subject, v.skills),
    placement: (v) => placementRequest(v.classLevel, v.subject, v.chapters),
    mock: mockRequest,
    gap_report: gapReportRequest,
    test_tomorrow: testTomorrowRequest,
    note: noteRequest,
    can_do: canDoRequest,
    not_on_track: notOnTrackRequest,
  };
  const personal = ["test_tomorrow", "note", "can_do", "not_on_track"];
  for (const kind of Object.keys(bodies)) {
    const v = parsed(kind);
    const made = makeRequest(v);
    const expected = route[kind]!(v);
    const got: Record<string, unknown> = { kind, made: made.kind, model: made.request.model, system: made.request.system };
    expect(got).toEqual({ kind, made: kind, model: expected.model, system: expected.system });
    expect({ kind, student: made.student ?? null }).toEqual({ kind, student: kind === "gap_report" || personal.includes(kind) ? studentId : null });
    expect({ kind, name: made.studentName ?? null }).toEqual({ kind, name: personal.includes(kind) ? "Dev Kumar" : null });
  }
});

test("a mock whose marks miss the pattern is empty; a figure of another template is empty", () => {
  const mock = makeRequest(parsed("mock"));
  const sections = (marks: number) => ({ sections: [{ name: "A", questions: [{ number: 1, text: "Q", answer: "A", marks, skill: "S" }] }] });
  expect(mock.empty?.(sections(25))).toBe(false);
  expect(mock.empty?.(sections(24))).toBe(true);
  const figure = makeRequest(parsed("figure"));
  expect(figure.empty?.(SAMPLE.figure)).toBe(false);
  expect(figure.empty?.({ figure: { kind: "number_line" }, caption: "x" })).toBe(true);
});

const ctx = (db = fakeDb(), claude = fakeClaude({ answer: SAMPLE.note })): StepContext => {
  const clock = fakeClock();
  return { db, jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" };
};

test("recordedCall passes the student to the gate and keys by the step unless a key is given", async () => {
  const db = fakeDb();
  const out = await recordedCall(ctx(db), { centre: centreId, input: parsed("note"), job: "job-1", step: "note:x", spec: makeAgent(parsed("note")) });
  expect(out.kind).toBe("ok");
  expect(db.started[0]).toMatchObject({ kind: "note", student: studentId, key: "job-1:note:x", job: "job-1" });
  await recordedCall(ctx(db), { centre: centreId, input: parsed("note"), job: "job-1", step: "note:y", key: "note:s:2026-10-05", spec: makeAgent(parsed("note")) });
  expect(db.started[1]).toMatchObject({ key: "note:s:2026-10-05" });
});

test("a personal kind without the parent's consent comes back failed student_consent and costs nothing", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  const out = await recordedCall(ctx(fakeDb({ studentConsent: false }), claude), { centre: centreId, input: {}, job: "job-1", step: "note", spec: makeAgent(parsed("note")) });
  expect(out).toEqual({ kind: "failed", reason: "student_consent" });
  expect(claude.requests).toHaveLength(0);
});

test("an empty answer is failed refused with its tokens recorded", async () => {
  const db = fakeDb();
  // The sample mock's marks do not sum to 99: an unfit mock, refused.
  const claude = fakeClaude({ answer: SAMPLE.mock });
  const odd = MakeInput.parse({ centreId, ...bodies.mock, pattern: { marks: 99, durationMinutes: 40 } });
  const out = await recordedCall(ctx(db, claude), { centre: centreId, input: {}, job: "job-1", step: "make:4", spec: makeAgent(odd) });
  expect(out).toMatchObject({ kind: "failed", reason: "refused" });
  expect(db.finished[0]).toMatchObject({ status: "failed", errorReason: "refused" });
  expect((db.finished[0] as { tokensIn: number }).tokensIn).toBeGreaterThan(0);
});

test("a job's agent has 170 s on the job's clock, so a slow draft still gets its repair (the review's finding 1)", async () => {
  const c = ctx(fakeDb());
  let drafts = 0;
  const claude = fakeClaude((r) => {
    if (r.system.shared.includes("You check")) {
      (c.clock as { advance(ms: number): void }).advance(15_000);
      return { answer: { pass: true, findings: [] } };
    }
    drafts += 1;
    (c.clock as { advance(ms: number): void }).advance(80_000);
    return { answer: drafts === 1 ? { ...SAMPLE.sheet, questions: SAMPLE.sheet.questions.map((q, i) => (i === 0 ? { ...q, proof: { expression: "3*6+5", equals: 20 } } : q)) } : SAMPLE.sheet };
  });
  const input = { kind: "sheet" as const, centreId, classLevel: "8" as const, subject: "Mathematics", skills: ["Linear equations"], questions: SAMPLE.sheet.questions.length, forHomework: false };
  const out = await recordedCall({ ...c, claude }, { centre: centreId, input, job: "job-1", step: "make:0", spec: makeAgent(input) });
  expect(out).toMatchObject({ kind: "ok", repaired: true });
  expect(JOB_AGENT_BUDGET_MS).toBe(170_000);
});
