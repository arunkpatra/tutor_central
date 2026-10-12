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
  expect(r).toEqual({ sent: 1, failed: 0, retired: 1 });
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
  expect(bad).toEqual({ sent: 0, failed: 1, retired: 1 });
  const busy = fakeOutbox([notif("n2", USER, "class")], { [USER]: [tok("t2", "tok-busy")] });
  expect(await sendDue({ outbox: busy, pusher: fakePusher({ "tok-busy": { ok: false, status: 503, reason: "ServiceUnavailable", retire: false } }), clock: CLOCK })).toEqual({
    sent: 0,
    failed: 1,
    retired: 0,
  });
  expect(busy.retired).toEqual([]);
  expect(busy.marks[0]).toMatchObject({ state: "failed" });
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
