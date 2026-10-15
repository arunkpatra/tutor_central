import { afterEach, expect, spyOn, test } from "bun:test";
import { fakeClock } from "../src/jobs/db-fake.js";
import { installModelTable, modelFor } from "../src/models.js";
import type { ModelRow, ModelSource } from "../src/models-db.js";

// Phase 22 (D113, review focus 1 and 2): the portal writes ai_models; the API's refresh must keep the last good row of a
// kind and step when a row names a model it cannot price, and reads the table at most once a minute.
let stop: (() => void) | null = null;
afterEach(() => {
  stop?.();
  stop = null;
});
const row = (model: string): ModelRow => ({ kind: "brief", step: "draft", model, effort: "high", fallbackModel: "claude-haiku-5-5", enabled: true });

test("a row with an unpriced model is refused and the table kept", async () => {
  let rows = [row("claude-sonnet-5-5")];
  const source: ModelSource = { current: async () => rows };
  const t = installModelTable(source);
  stop = t.stop;
  expect(await t.refresh()).toBe(true);
  expect(modelFor("brief", "draft")).toEqual({ model: "claude-sonnet-5-5", effort: "high", fallback: "claude-haiku-5-5", enabled: true });
  const errors = spyOn(console, "error").mockImplementation(() => {});
  rows = [row("claude-sonnet-6-0")];
  expect(await t.refresh()).toBe(true);
  expect(modelFor("brief", "draft")).toEqual({ model: "claude-sonnet-5-5", effort: "high", fallback: "claude-haiku-5-5", enabled: true });
  expect(errors).toHaveBeenCalledTimes(1);
  expect(String(errors.mock.calls[0]?.[0])).toContain("a model row is not priced");
  expect(String(errors.mock.calls[0]?.[0])).toContain("claude-sonnet-6-0");
  errors.mockRestore();
});

test("a table refreshed within the minute answers the row it had", async () => {
  const clock = fakeClock();
  let reads = 0;
  const source: ModelSource = {
    current: async () => {
      reads += 1;
      return [row(reads === 1 ? "claude-sonnet-5-5" : "claude-opus-5-5")];
    },
  };
  const t = installModelTable(source, clock);
  stop = t.stop;
  await t.fresh();
  await clock.sleep(10_000);
  await t.fresh();
  expect(reads).toBe(1);
  expect(modelFor("brief", "draft").model).toBe("claude-sonnet-5-5");
  await clock.sleep(51_000);
  await t.fresh();
  expect(reads).toBe(2);
  expect(modelFor("brief", "draft").model).toBe("claude-opus-5-5");
});
