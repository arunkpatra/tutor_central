import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";
import { fakeObserve } from "../src/observe-fake.js";

const deps = { claude: fakeClaude({ refuse: true }), db: fakeDb(), apple: fakeApple({}) };

const app = makeApp({ observe: fakeObserve(), verify: async (t) => (t === "good" ? { id: "u1" } : null), ...deps });
const post = (headers: Record<string, string>) =>
  app.request("/ai/generate", { method: "POST", body: "{}", headers: { "content-type": "application/json", ...headers } });

test("no token → 401 in words", async () => {
  const r = await post({});
  expect(r.status).toBe(401);
  expect(await r.json()).toEqual({ error: "sign in again" });
});

test("a header that is not a bearer token → 401", async () => {
  expect((await post({ authorization: "Basic dXNlcjpwYXNz" })).status).toBe(401);
  expect((await post({ authorization: "Bearer " })).status).toBe(401);
});

test("an expired, unknown or deleted user's token → 401, never 500", async () => {
  const r = await post({ authorization: "Bearer expired" });
  expect(r.status).toBe(401);
  expect(await r.json()).toEqual({ error: "sign in again" });
});

test("an unreachable Supabase answers 503 in connection words, not 401 'sign in again' (D68)", async () => {
  const down = makeApp({ observe: fakeObserve(), verify: async () => "unreachable", ...deps });
  const r = await down.request("/ai/generate", { method: "POST", body: "{}", headers: { authorization: "Bearer good" } });
  expect(r.status).toBe(503);
  expect(await r.json()).toEqual({ error: "Couldn't reach the service. Try again.", reason: "unreachable" });
  const failing = makeApp({ observe: fakeObserve(), verify: async () => { throw new Error("fetch failed"); }, ...deps });
  const thrown = await failing.request("/ai/generate", { method: "POST", body: "{}", headers: { authorization: "Bearer x" } });
  expect(thrown.status).toBe(503);
});

test("a good token reaches the route", async () => {
  expect((await post({ authorization: "Bearer good" })).status).toBe(400);
});

test("health needs no token", async () => {
  expect((await app.request("/health")).status).toBe(200);
});
