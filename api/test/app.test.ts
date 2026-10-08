import { expect, test } from "bun:test";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

const deps = { claude: fakeClaude({ refuse: true }), db: fakeDb() };
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
