import { expect, test } from "bun:test";
import { candidate, feedbackSql, SEED_NAMES } from "./feedback-cases";

const row = {
  feedback_kind: "again",
  reason: "Less about marks",
  revised_length: null,
  kind: "note",
  created_at: "2026-10-14T10:00:00Z",
  input: {
    studentId: "a0000000-0000-4000-8000-000000000011",
    studentName: "Aarav Gupta",
    parentName: "Sunita Gupta",
    parentPhone: "+919876543210",
    centreId: "22222222-2222-2222-2222-222222222222",
    language: "hi",
    week: { taught: ["Fractions"], right: "Aarav got 14 of 20 right", practise: [], coming: [] },
    tutorSays: "Sunita ji, call me on 98765 43210 if Aarav needs help.",
  },
};

test("a feedback row becomes a candidate with the seed's names and no number, id or revised text", () => {
  const c = candidate(row);
  const text = JSON.stringify(c);
  for (const gone of ["Aarav", "Sunita", "Gupta", "9876543210", "98765 43210", "a0000000-0000-4000-8000-000000000011", "22222222-2222"]) expect(text).not.toContain(gone);
  expect(c.input.studentName).toBe(SEED_NAMES[0]);
  expect(c.input.parentName).toBe(SEED_NAMES[1]);
  expect((c.input.week as { right: string }).right).toBe(`${SEED_NAMES[0]?.split(" ")[0]} got 14 of 20 right`);
  expect(c.input).not.toHaveProperty("studentId");
  expect(c.input).not.toHaveProperty("parentPhone");
  expect(c).toMatchObject({ kind: "note", feedback: { kind: "again", reason: "Less about marks" } });
  expect(text).not.toContain("revised\"");
});

test("an edit keeps the revised text's length, never its words", () => {
  const c = candidate({ ...row, feedback_kind: "edit", reason: null, revised_length: 412 });
  expect(c.feedback).toEqual({ kind: "edit", reason: null, revisedLength: 412 });
});

test("the query reads the revised text's length alone, within the days and kinds asked", () => {
  const sql = feedbackSql(30, ["note", "sheet"]);
  expect(sql).toContain("length(f.revised::text)");
  expect(sql).not.toMatch(/select[^;]*f\\.revised[,\\s]/);
  expect(sql).toContain("interval '30 days'");
  expect(sql).toContain("('note', 'sheet')");
  expect(() => feedbackSql(30, ["note'; drop table x; --"])).toThrow();
});
