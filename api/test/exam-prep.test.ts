import { expect, test } from "bun:test";
import { type PrepItem, revisionLines, weakestSkills } from "../src/plan/exam-prep.js";

// Each member's revision line for the batch's day (PlanMaker.exams and .revision): the set's number, the gap report's
// line after the mock, the holiday, the test day. The split itself is held by the shared cases.
const SCHOOL = "f0000000-0000-4000-8000-000000000001";
const DEV = { id: "a0000000-0000-4000-8000-000000000001", name: "Dev", classLevel: "8", schoolID: SCHOOL };
const MEHER = { id: "a0000000-0000-4000-8000-000000000002", name: "Meher", classLevel: "8", schoolID: SCHOOL };
const exam: PrepItem = {
  id: "e1",
  kind: "exam",
  audience: { school: SCHOOL, classLevel: "8" },
  title: "Science unit test",
  subject: "Science",
  date: "2026-11-12",
  portions: "Metals · Light",
  receivedAt: "2026-10-20T10:00:00+05:30",
};
const lines = (date: string, extra: Partial<Parameters<typeof revisionLines>[0]> = {}) =>
  revisionLines({ members: [DEV, MEHER], items: [exam], meetingDays: [1, 3, 5], date, chapters: {}, skills: {}, gapReports: {}, ...extra });

test("a revision day carries its index as the set's number, the day's skills and the portions", () => {
  const { revisions } = lines("2026-11-02");
  expect(revisions[DEV.id]).toMatchObject({ itemID: "e1", subject: "Science", examDate: "2026-11-12", day: { day: "2026-11-02", kind: "revise", index: 2 }, setNumber: 2, portions: ["Metals", "Light"] });
});

test("the mock day's set is the first; after the mock the set counts on from the revision days, with the report's line", () => {
  expect(lines("2026-11-09").revisions[DEV.id]).toMatchObject({ day: { kind: "mock" }, setNumber: 1 });
  const report = { schoolItemID: "e1", days: [{ line: "Revise metals with two short questions" }], bySkill: [{ skill: "Metals", right: 2, of: 5 }, { skill: "Light", right: 5, of: 5 }] };
  const after = lines("2026-11-11", { gapReports: { [DEV.id]: report } }).revisions;
  expect(after[DEV.id]).toMatchObject({ day: { kind: "afterMock" }, setNumber: 5, gapLine: "Revise metals with two short questions", gapSkills: ["Metals"] });
  expect(after[MEHER.id]?.gapLine).toBeUndefined();
});

test("a report kept for another exam is not used", () => {
  const report = { schoolItemID: "other", days: [{ line: "x" }], bySkill: [{ skill: "Metals", right: 0, of: 5 }] };
  expect(lines("2026-11-11", { gapReports: { [DEV.id]: report } }).revisions[DEV.id]).toMatchObject({ gapSkills: [] });
});

test("a member on holiday is left out and named; the test day has no revision", () => {
  const holiday: PrepItem = { id: "h1", kind: "holiday", audience: { student: MEHER.id }, title: "Away", date: "2026-11-02", receivedAt: "2026-10-20T10:00:00+05:30" };
  const out = lines("2026-11-02", { items: [exam, holiday] });
  expect(out.holidays).toEqual([MEHER.id]);
  expect(Object.keys(out.revisions)).toEqual([DEV.id]);
  expect(lines("2026-11-12").revisions).toEqual({});
});

test("the weakest skills that lost marks, lowest share first, ties in the mock's order", () => {
  expect(weakestSkills([{ skill: "A", right: 2, of: 4 }, { skill: "B", right: 4, of: 4 }, { skill: "C", right: 1, of: 2 }, { skill: "D", right: 0, of: 3 }], 6)).toEqual(["D", "A", "C"]);
});
