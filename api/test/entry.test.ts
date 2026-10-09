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
  process.env.ANTHROPIC_API_KEY ??= "test";
  process.env.APPLE_TEAM_ID ??= "test";
  process.env.APPLE_KEY_ID ??= "test";
  process.env.APPLE_SIGNIN_KEY ??= "test";
  const entry = await import("../src/index.js");
  expect(typeof entry.default.fetch).toBe("function");
});

const SETTINGS = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "k",
  ANTHROPIC_API_KEY: "a",
  APPLE_TEAM_ID: "t",
  APPLE_KEY_ID: "k",
  APPLE_SIGNIN_KEY: "p",
};

test("the server refuses to start without its settings, so /health and the deploy's smoke fail", async () => {
  for (const missing of Object.keys(SETTINGS)) {
    const env: Record<string, string> = { PATH: process.env.PATH ?? "", ...SETTINGS };
    delete env[missing];
    const proc = Bun.spawn(["bun", "--no-env-file", "-e", "await import('./src/index.ts')"], { cwd: root, env, stdout: "pipe", stderr: "pipe" });
    const stderr = await new Response(proc.stderr).text();
    expect({ missing, code: await proc.exited }).not.toEqual({ missing, code: 0 });
    expect(stderr).toContain(`${missing} is not set`);
  }
});

test("with AI_FAKE=1 the server starts without the Anthropic key (local runs that cost nothing)", async () => {
  const env: Record<string, string> = { PATH: process.env.PATH ?? "", ...SETTINGS, AI_FAKE: "1" };
  delete env.ANTHROPIC_API_KEY;
  const proc = Bun.spawn(["bun", "--no-env-file", "-e", "await import('./src/index.ts')"], { cwd: root, env, stdout: "pipe", stderr: "pipe" });
  expect(await proc.exited).toBe(0);
});

test("with APPLE_FAKE=1 the server starts without the Apple key (a local deletion run touches no Apple)", async () => {
  const env: Record<string, string> = { PATH: process.env.PATH ?? "", ...SETTINGS, APPLE_FAKE: "1" };
  delete env.APPLE_TEAM_ID;
  delete env.APPLE_KEY_ID;
  delete env.APPLE_SIGNIN_KEY;
  const proc = Bun.spawn(["bun", "--no-env-file", "-e", "await import('./src/index.ts')"], { cwd: root, env, stdout: "pipe", stderr: "pipe" });
  expect(await proc.exited).toBe(0);
});
