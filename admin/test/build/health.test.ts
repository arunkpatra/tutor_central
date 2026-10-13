import { expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { join } from "node:path";

test("the build has the health route the smoke reads", () => {
  expect(existsSync(join(import.meta.dir, "..", "..", ".next", "server", "app", "health", "route.js"))).toBe(true);
});
