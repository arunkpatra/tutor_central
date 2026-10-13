import { expect, test } from "bun:test";
import { family, modelName } from "../../content/models";

test("a model's id in the boards' words", () => {
  expect(modelName("claude-sonnet-5-5")).toBe("Sonnet 5.5");
  expect(modelName("claude-haiku-5-5")).toBe("Haiku 5.5");
  expect(family("claude-opus-5-5")).toBe("Opus");
  expect(modelName("something-else")).toBe("something-else");
  expect(modelName(null)).toBe("—");
});
