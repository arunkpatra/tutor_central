import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";
import { fakeObserve } from "../src/observe-fake.js";

const centreId = "22222222-2222-2222-2222-222222222222";
const verify = async (t: string) => (t === "good" ? { id: "u1" } : null);
const paper = { kind: "paper", centreId, subject: "Mathematics", classLevel: "Class 10", topic: "Fractions" };
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const build = (observe = fakeObserve(), db = fakeDb()) => ({
  observe,
  db,
  app: makeApp({ verify, claude: fakeClaude({ answer: SAMPLE.paper }), db, apple: fakeApple({}), observe }),
});
const post = (app: ReturnType<typeof makeApp>, body: unknown, headers: Record<string, string> = {}) =>
  app.request("/ai/generate", {
    method: "POST",
    headers: { authorization: "Bearer good", "content-type": "application/json", ...headers },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });

test("a request without X-Request-Id gets one and the row records it", async () => {
  const { app, observe } = build();
  const r = await post(app, paper);
  expect(r.status).toBe(200);
  const id = r.headers.get("x-request-id");
  expect(id).toMatch(UUID);
  expect(observe.rows[0]).toMatchObject({ requestId: id, route: "/ai/generate", method: "POST", status: 200, userId: "u1", centreId });
  expect(observe.rows[0]?.latencyMs).toBeGreaterThanOrEqual(0);
});

test("a valid X-Request-Id is kept, a malformed one replaced", async () => {
  const { app, observe } = build();
  const mine = "0f9a1b2c-3d4e-4f5a-8b6c-7d8e9f0a1b2c";
  expect((await post(app, paper, { "x-request-id": mine })).headers.get("x-request-id")).toBe(mine);
  const replaced = (await post(app, paper, { "x-request-id": "not-a-uuid'; drop" })).headers.get("x-request-id");
  expect(replaced).toMatch(UUID);
  expect(replaced).not.toBe("not-a-uuid'; drop");
  expect(observe.rows.map((r) => r.requestId)).toEqual([mine, replaced as string]);
});

test("/health leaves no row", async () => {
  const { app, observe } = build();
  expect((await app.request("/health")).status).toBe(200);
  expect(observe.rows).toEqual([]);
});

test("a refusal's reason is on its row, and a request with no user has none", async () => {
  const { app, observe } = build(fakeObserve(), fakeDb({ consent: false }));
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString("base64");
  const r = await app.request("/ai/scan-register", {
    method: "POST",
    headers: { authorization: "Bearer good", "content-type": "application/json" },
    body: JSON.stringify({ centreId, imageBase64: jpeg, mediaType: "image/jpeg" }),
  });
  expect(r.status).toBe(403);
  expect(observe.rows[0]).toMatchObject({ status: 403, reason: "consent" });
  await app.request("/ai/generate", { method: "POST", body: "{}" });
  expect(observe.rows[1]).toMatchObject({ status: 401 });
  expect(observe.rows[1]?.userId).toBeUndefined();
});

test("the 21st call in a minute is 429 rate and leaves a row with reason rate", async () => {
  const observe = fakeObserve();
  observe.recent = 20;
  const { app, db } = build(observe);
  const r = await post(app, paper);
  expect(r.status).toBe(429);
  expect(await r.json()).toEqual({ error: "Too many requests in a minute. Try again shortly.", reason: "rate" });
  expect(db.started).toEqual([]);
  expect(observe.rows[0]).toMatchObject({ status: 429, reason: "rate" });
  observe.recent = 19;
  expect((await post(app, paper)).status).toBe(200);
});

test("one address past 60 a minute is 429 before any sign-in check", async () => {
  const { app } = build();
  const from = { "x-forwarded-for": "203.0.113.9, 10.0.0.1" };
  for (let i = 0; i < 60; i++) expect((await app.request("/ai/generate", { method: "POST", headers: from, body: "{}" })).status).toBe(401);
  const r = await app.request("/ai/generate", { method: "POST", headers: from, body: "{}" });
  expect(r.status).toBe(429);
  expect((await app.request("/ai/generate", { method: "POST", headers: { "x-forwarded-for": "203.0.113.10" }, body: "{}" })).status).toBe(401);
});

test("a body over the limit is 413 in words before any call", async () => {
  const { app, db } = build();
  const r = await post(app, JSON.stringify({ ...paper, topic: "x".repeat(4_500_000) }));
  expect(r.status).toBe(413);
  expect(await r.json()).toEqual({ error: "That's too many pages. Up to six, and try sharper, smaller photos." });
  expect(db.started).toEqual([]);
});

test("an unreachable observe does not fail the answer", async () => {
  const observe = fakeObserve({ failing: true });
  const { app } = build(observe);
  expect((await post(app, paper)).status).toBe(200);
});
