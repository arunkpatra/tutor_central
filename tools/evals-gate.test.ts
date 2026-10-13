import { expect, test } from "bun:test";
import { failedCases, gate, withRetries } from "./evals-gate";

// The evals' gate (D101): every case passes its schema, verify and expectations; the rubric at 85% or more per kind.
const result = (kind: string, js: boolean, rubric: boolean | null, extra: { repaired?: boolean; cost?: number } = {}) => ({
  vars: { kind, id: `${kind}-x` },
  cost: extra.cost ?? 0.001,
  response: { metadata: { repaired: extra.repaired ?? false } },
  gradingResult: {
    componentResults: [
      { pass: js, assertion: { type: "javascript" }, reason: js ? "ok" : "count 5, expected 6" },
      ...(rubric === null ? [] : [{ pass: rubric, assertion: { type: "llm-rubric" }, reason: "graded" }]),
    ],
  },
});
const results = (rows: ReturnType<typeof result>[]) => ({ results: { results: rows } });
const many = (kind: string, passes: number, of: number) => Array.from({ length: of }, (_, i) => result(kind, true, i < passes));

test("a kind at 80% on the rubric fails, naming it; at 85% it passes", () => {
  const low = gate(results([...many("sheet", 4, 5), ...many("check", 5, 5)]), { fake: false });
  expect(low.ok).toBe(false);
  expect(low.failures).toEqual(["sheet: the rubric passed 4 of 5 (80%), under 85%"]);
  const at = gate(results([...many("sheet", 17, 20)]), { fake: false });
  expect(at.ok).toBe(true);
});

test("a schema, verify or expectation failure fails whatever the rubric", () => {
  const out = gate(results([result("figure", false, true), ...many("figure", 4, 4)]), { fake: false });
  expect(out.ok).toBe(false);
  expect(out.failures).toEqual(["figure: figure-x: count 5, expected 6"]);
});

test("a fake run reads the rubric as skipped; the table names the cases, the passes, the repaired and the cost", () => {
  const out = gate(results([result("sheet", true, null, { repaired: true, cost: 0.02 }), result("sheet", true, null)]), { fake: true });
  expect(out.ok).toBe(true);
  expect(out.table).toContain("| sheet | 2 | 2/2 | skipped | 1 | ₹1.79 |");
});

test("a case the provider could not run is a failure", () => {
  const out = gate({ results: { results: [{ vars: { kind: "brief", id: "b1" }, error: "timeout", gradingResult: null }] } }, { fake: false });
  expect(out.failures).toEqual(["brief: b1: timeout"]);
});

// D103: a case that fails gets one fresh run; it counts as failed only if it fails again.
const one = (id: string, js: boolean, rubric: boolean, cost = 0.01) => ({ ...result("check", js, rubric, { cost }), vars: { kind: "check", id } });

test("the failed cases are named for their retry: a free check or the rubric failed, or the provider could not run", () => {
  const first = results([one("a", true, true), one("b", true, false), one("c", false, true)]);
  expect(failedCases(first)).toEqual(["b", "c"]);
});

test("a case that passes on its retry counts as passed; one that fails twice counts as failed; both runs are paid", () => {
  const first = results([one("a", true, true), one("b", true, false), one("c", true, false), one("d", true, true), one("e", true, true)]);
  const retry = results([one("b", true, true), one("c", true, false)]);
  const merged = withRetries(first, retry);
  const out = gate(merged, { fake: false });
  expect(out.ok).toBe(false);
  expect(out.failures).toEqual(["check: the rubric passed 4 of 5 (80%), under 85%"]);
  expect(out.table).toContain("| check | 5 | 5/5 | 80% (4/5) | 0 | ₹5.95 |");
  const green = gate(withRetries(first, results([one("b", true, true), one("c", true, true)])), { fake: false });
  expect(green.ok).toBe(true);
});
