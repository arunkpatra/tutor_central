import { expect, test } from "bun:test";
import { kindsChanged } from "./evals-changed";

// evals.yml runs the kinds a pull request touches (D101).
test("a prompt file names its kind", () => {
  expect(kindsChanged(["api/src/prompts/sheet.ts"])).toEqual(["sheet"]);
  expect(kindsChanged(["api/src/prompts/worked-example.ts", "api/src/agents/kinds/parse-school.ts"])).toEqual(["parse_school", "worked_example"]);
});

test("shared.ts, the agent, the check, the schemas or the provider name every kind", () => {
  for (const path of ["api/src/prompts/shared.ts", "api/src/agents/agent.ts", "api/src/agents/check.ts", "api/src/schemas.ts", "api/evals/provider.ts", "api/src/agents/kinds/rubric.ts"]) {
    expect({ path, kinds: kindsChanged([path]).length }).toEqual({ path, kinds: 9 });
  }
});

test("evals-changed names no kind for a web change", () => {
  expect(kindsChanged(["web/app/page.tsx", "docs/spec.md", "api/src/routes/v2.ts"])).toEqual([]);
});

test("a rubric or a case names its kind; a prompt of a kind not on its agent names none", () => {
  expect(kindsChanged(["api/evals/check/rubric.md"])).toEqual(["check"]);
  expect(kindsChanged(["api/evals/parse_textbook/pages/maths-5.png"])).toEqual(["parse_textbook"]);
  expect(kindsChanged(["api/src/prompts/mock.ts"])).toEqual([]);
});

test("the maths free check and the nightly's runner name every kind (the review's finding 5)", () => {
  expect(kindsChanged(["api/src/agents/maths.ts"])).toHaveLength(9);
  expect(kindsChanged(["api/src/evals/runner.ts"])).toHaveLength(9);
});
