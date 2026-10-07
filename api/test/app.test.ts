import { expect, test } from "bun:test";
import { makeApp } from "../src/make-app.js";

const app = makeApp({ verify: async (t) => (t === "good" ? { id: "u1" } : null), commit: "abc1234" });
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const post = (path: string, body: string) => app.request(path, { method: "POST", headers: auth, body });

test("health answers with status and the commit it was deployed from", async () => {
  const r = await app.request("/health");
  expect(r.status).toBe(200);
  expect(await r.json()).toEqual({ ok: true, commit: "abc1234" });
  const unknown = makeApp({ verify: async () => null });
  expect(await (await unknown.request("/health")).json()).toEqual({ ok: true, commit: "local" });
});

test("generate validates, then answers 501 with its contract until Phase 6", async () => {
  const bad = await post("/ai/generate", JSON.stringify({ kind: "paper" }));
  expect(bad.status).toBe(400);
  expect((await bad.json()).error).toContain("subject");
  const r = await post("/ai/generate", JSON.stringify({ kind: "homework", subject: "Maths", classLevel: "Class 8", topic: "Fractions" }));
  expect(r.status).toBe(501);
  expect(await r.json()).toEqual({ error: "not built yet", contract: "Phase 6", route: "/ai/generate" });
});

test("a body that is not JSON → 400, not 500", async () => {
  const r = await post("/ai/generate", "{not json");
  expect(r.status).toBe(400);
});

test("scan-register and check-paper validate and answer 501", async () => {
  const image = { imageBase64: "AAAA", mediaType: "image/png" };
  expect((await post("/ai/scan-register", JSON.stringify(image))).status).toBe(501);
  expect((await post("/ai/scan-register", JSON.stringify({ ...image, mediaType: "image/gif" }))).status).toBe(400);
  expect((await post("/ai/check-paper", JSON.stringify({ pages: [image], markingScheme: "Q1 5" }))).status).toBe(501);
});

test("an unknown route → 404 in words", async () => {
  const r = await app.request("/nope");
  expect(r.status).toBe(404);
  expect(await r.json()).toEqual({ error: "no such route" });
});
