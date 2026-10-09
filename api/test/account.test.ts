import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

function appWith(apple = fakeApple({})) {
  return makeApp({ verify: async (t) => (t === "good" ? { id: "u1" } : null), claude: fakeClaude({}), db: fakeDb(), apple });
}
const post = (app: ReturnType<typeof makeApp>, body: unknown, token = "good") =>
  app.request("/account/revoke-apple", {
    method: "POST",
    body: JSON.stringify(body),
    headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
  });

test("a good code is revoked and answers 204", async () => {
  const apple = fakeApple({});
  const r = await post(appWith(apple), { code: "c.abc" });
  expect(r.status).toBe(204);
  expect(apple.revoked).toEqual(["c.abc"]);
});

test("no token → 401; a missing or empty code → 400 with the issue", async () => {
  expect((await post(appWith(), { code: "c" }, "nope")).status).toBe(401);
  const r = await post(appWith(), {});
  expect(r.status).toBe(400);
  expect(((await r.json()) as { error: string }).error).toContain("code");
  expect((await post(appWith(), { code: "" })).status).toBe(400);
});

test("a code Apple refuses → 400 in words; Apple unreachable → 502 in words", async () => {
  const refused = await post(appWith(fakeApple({ refuse: true })), { code: "stale" });
  expect(refused.status).toBe(400);
  expect(await refused.json()).toEqual({ error: "Apple didn't accept the confirmation. Try again." });
  const down = await post(appWith(fakeApple({ unreachable: true })), { code: "c" });
  expect(down.status).toBe(502);
  expect(await down.json()).toEqual({ error: "Apple didn't answer. Try again in a minute." });
});
