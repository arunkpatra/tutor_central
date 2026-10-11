import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

const deps = { claude: fakeClaude({ refuse: true }), db: fakeDb(), apple: fakeApple({}) };
const app = makeApp({ verify: async (t) => (t === "good" ? { id: "u1" } : null), commit: "abc1234", ...deps });
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const post = (path: string, body: string) => app.request(path, { method: "POST", headers: auth, body });

test("health answers with status and the commit it was deployed from", async () => {
  const r = await app.request("/health");
  expect(r.status).toBe(200);
  expect(await r.json()).toEqual({ ok: true, commit: "abc1234" });
  const unknown = makeApp({ verify: async () => null, ...deps });
  expect(await (await unknown.request("/health")).json()).toEqual({ ok: true, commit: "local" });
});

test("a body that is not JSON → 400, not 500", async () => {
  const r = await post("/ai/generate", "{not json");
  expect(r.status).toBe(400);
});

test("an unknown route → 404 in words", async () => {
  const r = await app.request("/nope");
  expect(r.status).toBe(404);
  expect(await r.json()).toEqual({ error: "no such route" });
});

test("the V2 routes of a later phase validate, then answer 501 until it", async () => {
  const centreId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718";
  const studentId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719";
  const path = "/ai/make";
  const body = { centreId, kind: "can_do", studentId, studentName: "Anu", tutorName: "Meera", language: "en", ladder: {} };
  const r = await post(path, JSON.stringify(body));
  expect({ status: r.status, body: await r.json() }).toEqual({ status: 501, body: { error: "not yet", route: path } });
  const bad = await post(path, JSON.stringify({ centreId }));
  expect(bad.status).toBe(400);
  const anon = await app.request(path, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
  expect(anon.status).toBe(401);
});
