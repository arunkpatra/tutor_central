import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";
import { fakeObserve } from "../src/observe-fake.js";

const deps = { claude: fakeClaude({ refuse: true }), db: fakeDb(), apple: fakeApple({}) };
const app = makeApp({ observe: fakeObserve(), verify: async (t) => (t === "good" ? { id: "u1" } : null), commit: "abc1234", ...deps });
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const post = (path: string, body: string) => app.request(path, { method: "POST", headers: auth, body });

test("health answers with status and the commit it was deployed from", async () => {
  const r = await app.request("/health");
  expect(r.status).toBe(200);
  expect(await r.json()).toEqual({ ok: true, commit: "abc1234" });
  const unknown = makeApp({ observe: fakeObserve(), verify: async () => null, ...deps });
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

test("the parents' kinds are live (Phase 14): a whole body reaches Claude, a skeleton one is a 400", async () => {
  const centreId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718";
  const studentId = "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719";
  const path = "/ai/make";
  const ladder = { movedUp: [], canDo: ["Read short sentences"], atHome: "One page a day", next: [] };
  const body = { centreId, kind: "can_do", studentId, studentName: "Anu", tutorName: "Meera", centreName: "Bright Minds", classLevel: "2", language: "en", ladder };
  const r = await post(path, JSON.stringify(body));
  expect(r.status).toBe(422); // this app's fake refuses every call: the body reached Claude
  expect((await post(path, JSON.stringify({ ...body, ladder: {} }))).status).toBe(400);
  const bad = await post(path, JSON.stringify({ centreId }));
  expect(bad.status).toBe(400);
  const anon = await app.request(path, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
  expect(anon.status).toBe(401);
});

test("a request for AI work reads the model table first; /health does not (D100)", async () => {
  let reads = 0;
  const withTable = makeApp({ observe: fakeObserve(), verify: async () => ({ id: "u1" }), ...deps, models: { fresh: async () => void (reads += 1) } });
  await withTable.request("/health");
  expect(reads).toBe(0);
  await withTable.request("/ai/generate", { method: "POST", headers: auth, body: "{not json" });
  expect(reads).toBe(1);
});
