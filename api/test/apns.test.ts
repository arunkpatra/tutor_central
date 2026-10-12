import { expect, test } from "bun:test";
import { answerOf, makeApnsPusher, type ProviderLike, retires } from "../src/push/apns.js";
import { alertPayload, fetchPayload } from "../src/push/payload.js";

// APNs through @parse/node-apn (D88): the payloads carry the words, the link and an opaque id, never a name (D72); Apple's
// answers map to sent, failed, or a token to retire. No network: the providers are stubbed.
test("the payloads carry the words, the link and an opaque id, never more", () => {
  expect(alertPayload({ id: "n1", kind: "plan_ready", title: "Evening batch: today’s plan is ready", body: "17:00–18:30 · 3 groups. Tap to see it.", link: "tutorcentral://today" })).toEqual({
    aps: { alert: { title: "Evening batch: today’s plan is ready", body: "17:00–18:30 · 3 groups. Tap to see it." }, sound: "default", "thread-id": "plan_ready" },
    link: "tutorcentral://today",
    id: "n1",
  });
  expect(fetchPayload({ id: "n2" })).toEqual({ aps: { "content-available": 1 }, fetch: "plan", id: "n2" });
});

test("a 410, a BadDeviceToken or a token not for the topic retires it; a 429 or a 5xx does not", () => {
  expect(retires(410, "Unregistered")).toBe(true);
  expect(retires(400, "BadDeviceToken")).toBe(true);
  expect(retires(400, "DeviceTokenNotForTopic")).toBe(true);
  expect(retires(400, "PayloadTooLarge")).toBe(false);
  expect(retires(429, "TooManyRequests")).toBe(false);
  expect(retires(503, "ServiceUnavailable")).toBe(false);
});

test("node-apn's answers map to sent with Apple's id, or failed with the status and reason", () => {
  expect(answerOf({ sent: [{ device: "t", "apns-id": "A-1" } as never], failed: [] })).toEqual({ ok: true, apnsId: "A-1" });
  expect(answerOf({ sent: [], failed: [{ device: "t", status: 410, response: { reason: "Unregistered" } }] })).toEqual({ ok: false, status: 410, reason: "Unregistered", retire: true });
  expect(answerOf({ sent: [], failed: [{ device: "t", error: new Error("socket hang up") }] })).toEqual({ ok: false, status: 0, reason: "socket hang up", retire: false });
});

test("one provider per environment, made at its first send and shut by close; an alert and a background push are typed as Apple asks", async () => {
  const made: boolean[] = [];
  const sent: { production: boolean; topic: string; pushType: string; priority: number; payload: unknown; to: string }[] = [];
  let shut = 0;
  const provider = (production: boolean): ProviderLike => {
    made.push(production);
    return {
      async send(n, to) {
        sent.push({ production, topic: n.topic, pushType: n.pushType, priority: n.priority, payload: n.rawPayload, to: to as string });
        return { sent: [{ device: to as string, "apns-id": `id-${to}` } as never], failed: [] };
      },
      async shutdown() {
        shut += 1;
      },
    };
  };
  const pusher = makeApnsPusher({ key: "k", keyId: "K", teamId: "T", topic: "in.tutorcentral.app" }, provider);
  expect(await pusher.send({ token: "a", environment: "sandbox", payload: alertPayload({ id: "n1", kind: "class", title: "t", body: "b", link: "l" }) })).toEqual({ ok: true, apnsId: "id-a" });
  await pusher.send({ token: "b", environment: "sandbox", payload: fetchPayload({ id: "n2" }), background: true });
  await pusher.send({ token: "c", environment: "production", payload: fetchPayload({ id: "n3" }), background: true });
  expect(made).toEqual([false, true]);
  expect(sent.map((s) => [s.to, s.production, s.topic, s.pushType, s.priority])).toEqual([
    ["a", false, "in.tutorcentral.app", "alert", 10],
    ["b", false, "in.tutorcentral.app", "background", 5],
    ["c", true, "in.tutorcentral.app", "background", 5],
  ]);
  await pusher.close();
  expect(shut).toBe(2);
});
