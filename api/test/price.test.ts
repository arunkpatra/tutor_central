import { expect, test } from "bun:test";
import { costPaise, promptHash } from "../src/price.js";

test("a call is priced in paise by api/models.json", () => {
  expect(costPaise("claude-haiku-5-5", 1_000_000, 0)).toBe(850);
  expect(costPaise("claude-sonnet-5-5", 812, 1460)).toBe(138);
  expect(costPaise("claude-opus-5-5", 0, 1_000_000)).toBe(170_000);
});

test("an unknown model or no tokens has no price", () => {
  expect(costPaise("unknown", 1, 1)).toBeNull();
  expect(costPaise("claude-haiku-5-5", null, null)).toBeNull();
});

test("the prompt's hash is the SHA-256 of its system words", () => {
  expect(promptHash("s")).toMatch(/^[0-9a-f]{64}$/);
  expect(promptHash("s")).toBe(promptHash("s"));
  expect(promptHash("s")).not.toBe(promptHash("t"));
});
