import { afterEach, expect, test } from "bun:test";
import { preview } from "../../lib/env";

// D96: preview mode serves fixtures without a session; production refuses it.
afterEach(() => {
  delete process.env.ADMIN_PREVIEW;
  delete process.env.VERCEL_ENV;
});

test("preview is off with no variable", () => expect(preview()).toBe(false));

test("preview is on with ADMIN_PREVIEW=1 outside production", () => {
  process.env.ADMIN_PREVIEW = "1";
  expect(preview()).toBe(true);
  process.env.VERCEL_ENV = "preview";
  expect(preview()).toBe(true);
});

test("production refuses preview mode", () => {
  process.env.ADMIN_PREVIEW = "1";
  process.env.VERCEL_ENV = "production";
  expect(() => preview()).toThrow("ADMIN_PREVIEW is for local runs");
});

test("the portal does not start in production with preview mode: the module refuses at import", async () => {
  const proc = Bun.spawn(["bun", "-e", 'await import("./lib/env.ts")'], {
    cwd: `${import.meta.dir}/../..`,
    env: { ...process.env, ADMIN_PREVIEW: "1", VERCEL_ENV: "production" },
    stderr: "pipe",
    stdout: "ignore",
  });
  expect(await proc.exited).not.toBe(0);
  expect(await new Response(proc.stderr).text()).toContain("ADMIN_PREVIEW is for local runs");
});
