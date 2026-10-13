import { expect, test } from "bun:test";
import { modelSourceFrom } from "../src/models-db.js";

// The platform's read of ai_models_current (0052), mapped to the API's rows.
const client = (answer: { data: unknown; error: { message: string } | null }) => ({
  calls: [] as string[],
  rpc(name: string) {
    this.calls.push(name);
    return Promise.resolve(answer);
  },
});

test("ai_models_current's rows are mapped to the API's", async () => {
  const c = client({ data: [{ kind: "sheet_to_5", step: "check", model: "claude-sonnet-5-5", effort: "medium", fallback_model: null, enabled: true, since: "2026-10-13T00:00:00Z" }], error: null });
  expect(await modelSourceFrom(c).current()).toEqual([{ kind: "sheet_to_5", step: "check", model: "claude-sonnet-5-5", effort: "medium", fallbackModel: null, enabled: true }]);
  expect(c.calls).toEqual(["ai_models_current"]);
});

test("an error answer throws, so the table keeps its last good rows", async () => {
  await expect(modelSourceFrom(client({ data: null, error: { message: "permission denied" } })).current()).rejects.toThrow(/permission denied/);
});
