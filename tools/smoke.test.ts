import { afterAll, expect, test } from "bun:test";
import { smoke } from "./smoke";


let commit = "abc";
let healthStatus = 200;
let aiStatus = 401;
let questions: unknown[] = [{ prompt: "1/2 + 1/4" }];
let tickStatus = 200;
let health: { pdf: number; apns: boolean } = { pdf: 1, apns: true };
const seen: { make?: { headers: Headers; body: Record<string, unknown> }; token?: { headers: Headers; body: Record<string, unknown> }; tick?: Headers } = {};
const server = Bun.serve({
  port: 0,
  async fetch(req) {
    const url = new URL(req.url);
    const path = url.pathname;
    if (path === "/health") return Response.json({ ok: true, commit }, { status: healthStatus });
    if (path === "/ai/generate") return Response.json({ error: "sign in again" }, { status: aiStatus });
    if (path === "/auth/v1/token" && url.searchParams.get("grant_type") === "password") {
      seen.token = { headers: req.headers, body: (await req.json()) as Record<string, unknown> };
      return Response.json({ access_token: "the-token" });
    }
    if (path === "/ai/make") {
      seen.make = { headers: req.headers, body: (await req.json()) as Record<string, unknown> };
      return Response.json({ id: "g1", result: { questions } });
    }
    if (path === "/jobs/health") return Response.json(health, { status: req.headers.get("authorization") === "Bearer s" ? 200 : 401 });
    if (path === "/jobs/tick") {
      seen.tick = req.headers;
      return Response.json({ claimed: 0 }, { status: tickStatus });
    }
    return new Response("no", { status: 404 });
  },
});
const site = `http://localhost:${server.port}`;
afterAll(() => server.stop());

test("passes when health reports the commit and the AI routes refuse a missing token", async () => {
  commit = "abc";
  healthStatus = 200;
  aiStatus = 401;
  expect(await smoke(site, "abc", { attempts: 1, waitMs: 0 })).toEqual([]);
});

test("fails when the site serves another commit", async () => {
  commit = "old";
  const problems = await smoke(site, "abc", { attempts: 2, waitMs: 0 });
  expect(problems.join("\n")).toContain("serves old, not abc");
});

test("fails when health is not 200", async () => {
  commit = "abc";
  healthStatus = 500;
  expect((await smoke(site, "abc", { attempts: 1, waitMs: 0 })).join("\n")).toContain("/health answered 500");
});

test("fails when an AI route lets a request without a token through", async () => {
  healthStatus = 200;
  aiStatus = 400;
  expect((await smoke(site, "abc", { attempts: 1, waitMs: 0 })).join("\n")).toContain("/ai/generate without a token answered 400");
});

test("fails in words when the site cannot be reached", async () => {
  const problems = await smoke("http://localhost:1", "abc", { attempts: 1, waitMs: 0 });
  expect(problems.join("\n")).toContain("could not reach");
});

const account = () => ({ url: site, anon: "anon-key", email: "smoke@example.com", password: "pw", centre: "c-1" });

test("the smoke signs in and makes one check", async () => {
  commit = "abc";
  healthStatus = 200;
  aiStatus = 401;
  questions = [{ prompt: "1/2 + 1/4" }];
  expect(await smoke(site, "abc", { attempts: 1, waitMs: 0, account: account() })).toEqual([]);
  expect(seen.token?.headers.get("apikey")).toBe("anon-key");
  expect(seen.token?.body).toEqual({ email: "smoke@example.com", password: "pw" });
  expect(seen.make?.headers.get("authorization")).toBe("Bearer the-token");
  expect(seen.make?.headers.get("idempotency-key")).toBe("smoke-abc");
  expect(seen.make?.headers.get("x-request-id")).toMatch(/^[0-9a-f-]{36}$/);
  expect(seen.make?.body).toMatchObject({ kind: "check", centreId: "c-1" });
});

test("an empty answer fails the smoke", async () => {
  questions = [];
  const problems = await smoke(site, "abc", { attempts: 1, waitMs: 0, account: account() });
  expect(problems.join("\n")).toContain("no question");
  questions = [{ prompt: "x" }];
});

test("a tick without 200 fails the smoke", async () => {
  tickStatus = 401;
  const problems = await smoke(site, "abc", { attempts: 1, waitMs: 0, workerSecret: "s" });
  expect(problems.join("\n")).toContain("/jobs/tick answered 401");
  tickStatus = 200;
  expect(await smoke(site, "abc", { attempts: 1, waitMs: 0, workerSecret: "s" })).toEqual([]);
  expect(seen.tick?.get("authorization")).toBe("Bearer s");
});

test("without an account the two old checks still run", async () => {
  seen.make = undefined;
  expect(await smoke(site, "abc", { attempts: 1, waitMs: 0 })).toEqual([]);
  expect(seen.make).toBeUndefined();
});

test("the worker's health must render a page and reach APNs (plan decision 26)", async () => {
  expect(await smoke(site, "abc", { attempts: 1, waitMs: 0, workerSecret: "s" })).toEqual([]);
  health = { pdf: 0, apns: true };
  expect((await smoke(site, "abc", { attempts: 1, waitMs: 0, workerSecret: "s" })).join("\n")).toContain("/jobs/health rendered no page");
  health = { pdf: 1, apns: false };
  expect((await smoke(site, "abc", { attempts: 1, waitMs: 0, workerSecret: "s" })).join("\n")).toContain("/jobs/health could not reach APNs");
  health = { pdf: 1, apns: true };
});
