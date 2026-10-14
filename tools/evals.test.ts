import { expect, test } from "bun:test";
import { KINDS, kindsAsked, testsFor } from "./evals";

// bun evals (D101): the tests promptfoo runs, written from the golden sets.
test("the tests for two kinds hold ten tests, each with the javascript assertion and the rubric graded by Opus 5.5", async () => {
  const tests = await testsFor(["sheet", "check"], { fake: false });
  expect(tests).toHaveLength(10);
  for (const t of tests) {
    expect(t.assert.map((a) => a.type)).toEqual(["javascript", "llm-rubric"]);
    expect(t.assert[1]).toMatchObject({ value: `file://${t.vars.kind}/rubric.md`, provider: { id: "anthropic:messages:claude-opus-5-5" } });
  }
});

test("the grader has room to think and still answer (it spent 2,048 tokens on a Kannada note's reasoning and wrote nothing)", async () => {
  const [first] = await testsFor(["note"], { fake: false });
  expect(first?.assert[1]).toMatchObject({ provider: { config: { max_tokens: 16000 } } });
});

test("an anchor set runs under the free checks alone until the speakers' labels come (D110)", async () => {
  const tests = await testsFor(["anchor_hi", "anchor_kn"], { fake: false });
  expect(tests).toHaveLength(16);
  expect(tests.every((t) => t.assert.map((a) => a.type).join() === "javascript")).toBe(true);
});

test("a fake run, or a case that expects a refusal, carries no rubric", async () => {
  expect((await testsFor(["sheet"], { fake: true })).every((t) => t.assert.length === 1)).toBe(true);
  const textbook = await testsFor(["parse_textbook"], { fake: false });
  expect(textbook.find((t) => t.vars.id === "textbook-preface")?.assert.map((a) => a.type)).toEqual(["javascript"]);
});

test("--kinds names the kinds or an anchor set; none means every kind; an unknown kind is refused", () => {
  expect(kindsAsked(["--kinds", "sheet,check"])).toEqual(["sheet", "check"]);
  expect(kindsAsked(["--kinds", "anchor_kn"])).toEqual(["anchor_kn"]);
  expect(kindsAsked([])).toHaveLength(KINDS.length);
  expect(() => kindsAsked(["--kinds", "sheet,nothing"])).toThrow("nothing has no golden set");
});

test("--cases keeps only the cases named", async () => {
  expect((await testsFor(["sheet"], { fake: false, cases: ["sheet-4-fractions"] })).map((t) => t.vars.id)).toEqual(["sheet-4-fractions"]);
});
