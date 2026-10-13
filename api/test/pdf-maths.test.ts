import { expect, test } from "bun:test";
import cases from "../../tools/contract/maths-cases.json" with { type: "json" };
import { splitMaths, typstOf } from "../src/pdf/maths.js";

// Mathematics in the PDFs (D102): the text split into words and formulae by the rules the phone shares
// (tools/contract/maths-cases.json, copied for MathSplitTests by bun contract).
test("every shared case splits as the phone splits it", () => {
  for (const c of cases) expect({ name: c.name, runs: splitMaths(c.text) as unknown }).toEqual({ name: c.name, runs: c.runs });
});

test("typstOf writes words as strings, inline maths as #mi and a display formula as #mitex, the LaTeX escaped", () => {
  expect(typstOf("Solve $3x + 5 = 20$.")).toBe('#"Solve ";#mi("3x + 5 = 20");#".";');
  expect(typstOf("$$x = 1$$")).toBe('#mitex("x = 1");');
  expect(typstOf('$\\text{say "hi"}$')).toBe('#mi("\\\\text{say \\"hi\\"}");');
  expect(typstOf("Plain.")).toBe('#"Plain.";');
});

test("typstOf with maths off writes the formulae as their words (the fallback for a formula Typst cannot draw)", () => {
  expect(typstOf("Solve $3x + 5 = 20$.", { maths: false })).toBe('#"Solve 3x + 5 = 20.";');
});
