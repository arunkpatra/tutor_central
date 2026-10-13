import { expect, test } from "bun:test";
import { kindsAsked, testsFor } from "./evals";

// bun evals (D101): the tests promptfoo runs, written from the golden sets.
test("the tests for two kinds hold ten tests, each with the javascript assertion and the rubric graded by Opus 5.5", async () => {
  const tests = await testsFor(["sheet", "check"], { fake: false });
  expect(tests).toHaveLength(10);
  for (const t of tests) {
    expect(t.assert.map((a) => a.type)).toEqual(["javascript", "llm-rubric"]);
    expect(t.assert[1]).toMatchObject({ value: `file://${t.vars.kind}/rubric.md`, provider: "anthropic:messages:claude-opus-5-5" });
  }
});

test("a fake run, or a case that expects a refusal, carries no rubric", async () => {
  expect((await testsFor(["sheet"], { fake: true })).every((t) => t.assert.length === 1)).toBe(true);
  const textbook = await testsFor(["parse_textbook"], { fake: false });
  expect(textbook.find((t) => t.vars.id === "textbook-preface")?.assert.map((a) => a.type)).toEqual(["javascript"]);
});

test("--kinds names the kinds; none means all nine; an unknown kind is refused", () => {
  expect(kindsAsked(["--kinds", "sheet,check"])).toEqual(["sheet", "check"]);
  expect(kindsAsked([])).toHaveLength(9);
  expect(() => kindsAsked(["--kinds", "sheet,nothing"])).toThrow("nothing has no golden set");
});

test("--cases keeps only the cases named", async () => {
  expect((await testsFor(["sheet"], { fake: false, cases: ["sheet-4-fractions"] })).map((t) => t.vars.id)).toEqual(["sheet-4-fractions"]);
});
