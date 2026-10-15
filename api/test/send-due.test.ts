import { expect, test } from "bun:test";
import { fakeClock } from "../src/jobs/db-fake.js";
import { fakePusher } from "../src/push/apns-fake.js";
import { fakeOutbox, type OutboxRow } from "../src/push/db.js";
import { sendDue } from "../src/push/send-due.js";

// The minute tick sends what is due (plan decision 7): every live token of the user, a retired token never again, a
// refusal recorded with Apple's answer. Review focus 1.
const USER = "u0000000-0000-4000-8000-000000000001";
const CLOCK = fakeClock();
const notif = (id: string, user: string, kind: string, background = false): OutboxRow => ({ id, user_id: user, kind, title: background ? null : "t", body: background ? null : "b", link: background ? null : "tutorcentral://today", background });
const tok = (id: string, token: string) => ({ id, token, environment: "sandbox" as const });

test("apns: a 410 retires the token and the other token still receives", async () => {
  const pusher = fakePusher({ "tok-old": { ok: false, status: 410, reason: "Unregistered", retire: true } });
  const outbox = fakeOutbox([notif("n1", USER, "class")], { [USER]: [tok("t1", "tok-old"), tok("t2", "tok-new")] });
  const r = await sendDue({ outbox, pusher, clock: CLOCK });
  expect(r).toEqual({ sent: 1, failed: 0, retired: 1, retried: 0 });
  expect(outbox.retired).toEqual(["t1"]);
  expect(pusher.sent.map((p) => p.token)).toEqual(["tok-old", "tok-new"]);
  expect(outbox.marks).toEqual([{ id: "n1", state: "sent", apns: [{ token: "t1", status: 410, reason: "Unregistered" }, { token: "t2", apnsId: "a-tok-new" }] }]);
});

test("apns: a BadDeviceToken retires it too; a 503 fails the row without retiring", async () => {
  const bad = await sendDue({
    outbox: fakeOutbox([notif("n1", USER, "class")], { [USER]: [tok("t1", "tok-bad")] }),
    pusher: fakePusher({ "tok-bad": { ok: false, status: 400, reason: "BadDeviceToken", retire: true } }),
    clock: CLOCK,
  });
  expect(bad).toEqual({ sent: 0, failed: 1, retired: 1, retried: 0 });
  const busy = fakeOutbox([notif("n2", USER, "class")], { [USER]: [tok("t2", "tok-busy")] });
  expect(await sendDue({ outbox: busy, pusher: fakePusher({ "tok-busy": { ok: false, status: 503, reason: "ServiceUnavailable", retire: false } }), clock: CLOCK })).toEqual({
    sent: 0,
    failed: 0,
    retired: 0,
    retried: 1,
  });
  expect(busy.retired).toEqual([]);
  expect(busy.retries).toEqual([{ id: "n2", dueAt: "2026-10-12T12:01:00.000Z" }]);
});

test("a user with no live token: the row is failed with reason no_token", async () => {
  const outbox = fakeOutbox([notif("n1", USER, "fees")], { [USER]: [] });
  await sendDue({ outbox, pusher: fakePusher({}), clock: CLOCK });
  expect(outbox.marks).toEqual([{ id: "n1", state: "failed", apns: { reason: "no_token" } }]);
});

test("a background row is sent as the plan's fetch, an alert with its words", async () => {
  const pusher = fakePusher({});
  await sendDue({ outbox: fakeOutbox([notif("n1", USER, "plan_ready"), notif("n2", USER, "plan_fetch", true)], { [USER]: [tok("t1", "tok")] }), pusher, clock: CLOCK });
  expect(pusher.sent.map((p) => [p.background ?? false, p.payload])).toEqual([
    [false, { aps: { alert: { title: "t", body: "b" }, sound: "default", "thread-id": "plan_ready" }, link: "tutorcentral://today", id: "n1" }],
    [true, { aps: { "content-available": 1 }, fetch: "plan", id: "n2" }],
  ]);
});

// Hand run 4: the sandbox dropped the stream ("stream ended unexpectedly", no status). That is no answer from Apple, so
// the push is tried once more at once; Apple's own 429 and 5xx are tried again a minute later (Phase 22).
test("a dropped connection (no status) is tried once more at once; a 503 a minute later", async () => {
  const dropped: Record<string, number> = {};
  const flaky = {
    sent: [] as string[],
    async send(p: { token: string }) {
      flaky.sent.push(p.token);
      dropped[p.token] = (dropped[p.token] ?? 0) + 1;
      if (p.token === "tok-drop" && dropped[p.token] === 1) return { ok: false as const, status: 0, reason: "stream ended unexpectedly", retire: false };
      if (p.token === "tok-busy") return { ok: false as const, status: 503, reason: "ServiceUnavailable", retire: false };
      return { ok: true as const, apnsId: `a-${p.token}` };
    },
    async close() {},
  };
  const outbox = fakeOutbox([notif("n1", USER, "notes_ready"), notif("n2", "u2", "class")], {
    [USER]: [tok("t1", "tok-drop")],
    u2: [tok("t2", "tok-busy")],
  });
  expect(await sendDue({ outbox, pusher: flaky, clock: CLOCK })).toEqual({ sent: 1, failed: 0, retired: 0, retried: 1 });
  expect(flaky.sent).toEqual(["tok-drop", "tok-drop", "tok-busy"]);
  expect(outbox.marks[0]).toEqual({ id: "n1", state: "sent", apns: [{ token: "t1", apnsId: "a-tok-drop" }] });
});

// Phase 22: a push Apple refused for a while (429, 5xx, no answer twice) is set due a minute later, three times at most
// (retry_notification, 0068); then it is failed. A retired token or no token is never tried again.
test("a push Apple refused is tried three times a minute apart, then failed", async () => {
  const clock = fakeClock();
  const outbox = fakeOutbox([notif("n1", USER, "alert")], { [USER]: [tok("t1", "tok-busy")] });
  const pusher = fakePusher({ "tok-busy": { ok: false, status: 429, reason: "TooManyRequests", retire: false } });
  const runs = [];
  for (let i = 0; i < 4; i++) {
    runs.push(await sendDue({ outbox, pusher, clock }));
    await clock.sleep(60_000);
  }
  expect(runs.map((r) => [r.retried, r.failed])).toEqual([[1, 0], [1, 0], [1, 0], [0, 1]]);
  expect(outbox.retries.map((r) => r.dueAt)).toEqual(["2026-10-12T12:01:00.000Z", "2026-10-12T12:02:00.000Z", "2026-10-12T12:03:00.000Z"]);
  expect(outbox.marks).toEqual([{ id: "n1", state: "failed", apns: [{ token: "t1", status: 429, reason: "TooManyRequests" }] }]);
});

test("a bad token is retired, never retried; no token is never retried", async () => {
  const bad = fakeOutbox([notif("n1", USER, "class")], { [USER]: [tok("t1", "tok-bad")] });
  await sendDue({ outbox: bad, pusher: fakePusher({ "tok-bad": { ok: false, status: 410, reason: "Unregistered", retire: true } }), clock: CLOCK });
  expect(bad.retries).toEqual([]);
  expect(bad.marks[0]).toMatchObject({ state: "failed" });
  const none = fakeOutbox([notif("n2", USER, "fees")], { [USER]: [] });
  await sendDue({ outbox: none, pusher: fakePusher({}), clock: CLOCK });
  expect(none.retries).toEqual([]);
});
