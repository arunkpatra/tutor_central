import { expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const root = join(import.meta.dir, "..");

/** Vercel's Hono preset (@vercel/hono): the entry is the first of these files whose source imports "hono". */
const CANDIDATES = ["app", "index", "server", "src/app", "src/index", "src/server"].flatMap((f) =>
  ["js", "cjs", "mjs", "ts", "cts", "mts"].map((ext) => `${f}.${ext}`),
);
const IMPORTS_HONO = /(?:from|require|import)\s*(?:\(\s*)?["']hono["']\s*(?:\))?/;

test("the entry Vercel's Hono preset picks is src/index.ts", () => {
  const picked = CANDIDATES.find((f) => existsSync(join(root, f)) && IMPORTS_HONO.test(readFileSync(join(root, f), "utf8")));
  expect(picked).toBe("src/index.ts");
});

test("src/index.ts exports the server as its default", async () => {
  process.env.SUPABASE_URL ??= "http://127.0.0.1:54321";
  process.env.SUPABASE_ANON_KEY ??= "test";
  const entry = await import("../src/index.js");
  expect(typeof entry.default.fetch).toBe("function");
});
