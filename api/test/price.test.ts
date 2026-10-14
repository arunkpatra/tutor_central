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

test("the prompt's hash is the SHA-256 of its shared and own system words", () => {
  const s = { shared: "s", own: "" };
  expect(promptHash(s)).toMatch(/^[0-9a-f]{64}$/);
  expect(promptHash(s)).toBe(promptHash({ shared: "s", own: "" }));
  expect(promptHash(s)).not.toBe(promptHash({ shared: "s", own: "t" }));
});

test("a cached token is priced at a tenth, a token written to the cache at a quarter more (plan decision 5)", () => {
  // 1,000 in, 1,000 cached, 100 out on Haiku 5.5: (0.10 + 0.01 + 0.05) ÷ 1,000 dollars → 1.36 paise → 1.
  expect(costPaise("claude-haiku-5-5", 1_000, 100, 1_000)).toBe(1);
  // A million read from the cache on Sonnet 5.5 is ₹17, a tenth of ₹170.
  expect(costPaise("claude-sonnet-5-5", 0, 0, 1_000_000)).toBe(1_700);
  // A million written to it is ₹212.50, a quarter over ₹170.
  expect(costPaise("claude-sonnet-5-5", 1_000_000, 0, 0, 1_000_000)).toBe(21_250);
});

test("a token written to the hour's cache is priced at twice the input (D108)", () => {
  // A million written for the hour on Sonnet 5.5 is ₹340, twice ₹170; at the batch's half, ₹170.
  expect(costPaise("claude-sonnet-5-5", 1_000_000, 0, 0, 1_000_000, 1, 1_000_000)).toBe(34_000);
  expect(costPaise("claude-sonnet-5-5", 1_000_000, 0, 0, 1_000_000, 0.5, 1_000_000)).toBe(17_000);
});

test("a cached token is priced by the model's own cached price (D109): Opus 5.5 at $0.20 a million", () => {
  // A million read from the cache on Opus 5.5: $0.20 → ₹17; on Haiku 5.5 $0.01 → ₹0.85.
  expect(costPaise("claude-opus-5-5", 0, 0, 1_000_000)).toBe(1_700);
  expect(costPaise("claude-haiku-5-5", 0, 0, 1_000_000)).toBe(85);
});
