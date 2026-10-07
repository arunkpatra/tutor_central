import { afterAll, expect, test } from "bun:test";
import { smoke } from "./smoke";

let commit = "abc";
let healthStatus = 200;
let aiStatus = 401;
const server = Bun.serve({
  port: 0,
  fetch(req) {
    const path = new URL(req.url).pathname;
    if (path === "/health") return Response.json({ ok: true, commit }, { status: healthStatus });
    if (path === "/ai/generate") return Response.json({ error: "sign in again" }, { status: aiStatus });
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
