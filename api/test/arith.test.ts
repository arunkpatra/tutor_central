import { expect, test } from "bun:test";
import { ArithError, evaluate, proofHolds } from "../src/agents/arith.js";

// A numeric key is verified by computation (D99): an arithmetic expression over numbers alone, evaluated without eval.
test("evaluates the four operations, powers right-associative, unary minus, parentheses and sqrt", () => {
  expect(evaluate("3*5+5")).toBe(20);
  expect(evaluate("(20-5)/3")).toBe(5);
  expect(evaluate("2^3^2")).toBe(512);
  expect(evaluate("sqrt(16)+1")).toBe(5);
  expect(evaluate("-4+6")).toBe(2);
  expect(evaluate(" 1000 * (1.1)^2 ")).toBeCloseTo(1210, 9);
  expect(evaluate("-2^2")).toBe(-4);
  expect(evaluate("2*-3")).toBe(-6);
  expect(evaluate("10/4")).toBe(2.5);
});

test("anything but numbers and the operators is refused", () => {
  for (const bad of ["x+1", "", "3+", "(1+2", "1+2)", "sqrt 4", "2**3", "process.exit()", "1e3", "3,5", "sqrt()", "4//2"]) {
    expect(() => evaluate(bad)).toThrow(ArithError);
  }
});

test("a proof holds within a millionth of its value", () => {
  expect(proofHolds({ expression: "3*5+5", equals: 20 })).toBe(true);
  expect(proofHolds({ expression: "3*6+5", equals: 20 })).toBe(false);
  expect(proofHolds({ expression: "1/3", equals: 0.3333333 })).toBe(true);
  expect(proofHolds({ expression: "x", equals: 1 })).toBe(false);
  expect(proofHolds({ expression: "1/0", equals: 0 })).toBe(false);
  expect(proofHolds({ expression: "5000*1.04^2", equals: 5408 })).toBe(true);
});
