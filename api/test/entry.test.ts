import { expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { join } from "node:path";

const root = join(import.meta.dir, "..");

/** Where Vercel's Hono preset looks for the server, in its order (it took src/app.ts over src/index.ts once). */
const CANDIDATES = ["app", "index", "server", "src/app", "src/index", "src/server"].flatMap((f) => [`${f}.ts`, `${f}.js`]);

test("the first entry Vercel's Hono preset finds is src/index.ts", () => {
  expect(CANDIDATES.find((f) => existsSync(join(root, f)))).toBe("src/index.ts");
});

test("src/index.ts exports the server as its default", async () => {
  process.env.SUPABASE_URL ??= "http://127.0.0.1:54321";
  process.env.SUPABASE_ANON_KEY ??= "test";
  const entry = await import("../src/index.js");
  expect(typeof entry.default.fetch).toBe("function");
});
