import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { KNOWN_MODELS } from "../../content/models";

test("the portal's models are the API's price sheet's (api/models.json)", () => {
  const sheet = JSON.parse(readFileSync(join(import.meta.dir, "..", "..", "..", "api", "models.json"), "utf8")) as {
    models: Record<string, unknown>;
  };
  expect([...KNOWN_MODELS].sort() as string[]).toEqual(Object.keys(sheet.models).sort());
});
