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

test("the V2 routes validate, then answer 501 until their phase", async () => {
  const centreId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718";
  for (const [path, body] of [
    ["/ai/plan", { centreId, classId: null, date: "2026-10-12", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }],
    ["/ai/make", { centreId, kind: "brief", classLevel: "9", subject: "Science", chapter: "Motion" }],
    ["/ai/parse-school", { centreId, text: "FA2 on Monday" }],
  ] as const) {
    const r = await post(path, JSON.stringify(body));
    expect({ path, status: r.status, body: await r.json() }).toEqual({ path, status: 501, body: { error: "not yet", route: path } });
    const bad = await post(path, JSON.stringify({ centreId }));
    expect({ path, status: bad.status }).toEqual({ path, status: 400 });
    const anon = await app.request(path, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
    expect({ path, status: anon.status }).toEqual({ path, status: 401 });
  }
});

test("check-paper takes a mock's key and answers 501 for it until Phase 13, calling nothing", async () => {
  const centreId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718";
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString("base64");
  const body = { centreId, pages: [{ imageBase64: jpeg, mediaType: "image/jpeg" }], scheme: { kind: "mock", artefactId: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60720" }, studentName: "Dev" };
  const r = await post("/ai/check-paper", JSON.stringify(body));
  expect({ status: r.status, body: await r.json() }).toEqual({ status: 501, body: { error: "not yet", route: "/ai/check-paper" } });
  expect(deps.db.started).toEqual([]);
});
