import { expect, test } from "bun:test";
import { KINDS } from "./evals";
import { kindsChanged } from "./evals-changed";

// evals.yml runs the kinds a pull request touches (D101).
test("a prompt file names its kind", () => {
  expect(kindsChanged(["api/src/prompts/sheet.ts"])).toEqual(["sheet"]);
  expect(kindsChanged(["api/src/prompts/worked-example.ts", "api/src/agents/kinds/parse-school.ts"])).toEqual(["parse_school", "worked_example"]);
});

test("shared.ts, the agent, the check, the schemas or the provider name every kind", () => {
  for (const path of ["api/src/prompts/shared.ts", "api/src/agents/agent.ts", "api/src/agents/check.ts", "api/src/schemas.ts", "api/evals/provider.ts", "api/src/agents/kinds/rubric.ts"]) {
    expect({ path, kinds: kindsChanged([path]).length }).toEqual({ path, kinds: KINDS.length });
  }
});

test("evals-changed names no kind for a web change", () => {
  expect(kindsChanged(["web/app/page.tsx", "docs/spec.md", "api/src/routes/v2.ts"])).toEqual([]);
});

test("a rubric or a case names its kind; a prompt of a kind not on its agent names none", () => {
  expect(kindsChanged(["api/evals/check/rubric.md"])).toEqual(["check"]);
  expect(kindsChanged(["api/evals/parse_textbook/pages/maths-5.png"])).toEqual(["parse_textbook"]);
  expect(kindsChanged(["api/src/prompts/paper.ts"])).toEqual([]);
  expect(kindsChanged(["api/src/prompts/mock.ts"])).toEqual(["mock"]);
});

test("the maths free check and the nightly's runner name every kind (the review's finding 5)", () => {
  expect(kindsChanged(["api/src/agents/maths.ts"])).toHaveLength(KINDS.length);
  expect(kindsChanged(["api/src/evals/runner.ts"])).toHaveLength(KINDS.length);
});

test("the parents' shared rules name the four message kinds and the anchors; an anchor's case names its set (D110)", () => {
  const parents = ["anchor_hi", "anchor_kn", "can_do", "not_on_track", "note", "test_tomorrow"];
  expect(kindsChanged(["api/src/agents/kinds/message.ts"])).toEqual(parents);
  expect(kindsChanged(["api/src/prompts/message.ts"])).toEqual(parents);
  expect(kindsChanged(["api/src/agents/kinds/numbers.ts"])).toEqual(["anchor_hi", "anchor_kn", "can_do", "figure", "not_on_track", "note", "test_tomorrow"]);
  expect(kindsChanged(["api/evals/anchors/kn/cases.json"])).toEqual(["anchor_kn"]);
  expect(kindsChanged(["api/src/prompts/can-do.ts"])).toEqual(["can_do"]);
});
