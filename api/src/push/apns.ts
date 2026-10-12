import { Notification, Provider, type Responses, type ResponseFailure, type ResponseSent } from "@parse/node-apn";
import type { PushPayload } from "./payload.js";

/** One push to one device. `background` is the plan's fetch (push type background, priority 5); the rest are alerts. */
export type Push = { token: string; environment: "sandbox" | "production"; payload: PushPayload; background?: boolean };
export type PushAnswer = { ok: true; apnsId: string } | { ok: false; status: number; reason: string; retire: boolean };
export interface Pusher {
  send(p: Push): Promise<PushAnswer>;
  close(): Promise<void>;
}
export type ApnsConfig = { key: string; keyId: string; teamId: string; topic: string };
/** What the pusher needs of a node-apn provider (stubbed in tests: no network). */
export type ProviderLike = {
  send(n: Notification, to: string): Promise<Responses<ResponseSent, ResponseFailure>>;
  shutdown(): Promise<void>;
};

/** A token Apple will never deliver to again (D88): gone (410), malformed, or for another app. */
export function retires(status: number, reason: string): boolean {
  return status === 410 || (status === 400 && (reason === "BadDeviceToken" || reason === "DeviceTokenNotForTopic"));
}

/** node-apn's answer for one device as sent with Apple's id, or failed with the status and reason (a connection that
 *  failed has no status: 0, and its error's words). */
export function answerOf(r: Responses<ResponseSent, ResponseFailure>): PushAnswer {
  const sent = r.sent[0] as (ResponseSent & { "apns-id"?: string }) | undefined;
  if (sent) return { ok: true, apnsId: sent["apns-id"] ?? "" };
  const failed = r.failed[0];
  const status = failed?.status ?? 0;
  const reason = failed?.response?.reason ?? failed?.error?.message ?? "unknown";
  return { ok: false, status, reason, retire: retires(status, reason) };
}

const realProvider = (config: ApnsConfig) => (production: boolean): ProviderLike =>
  new Provider({ token: { key: config.key, keyId: config.keyId, teamId: config.teamId }, production });

/** The worker run's pusher (D88): one provider per APNs environment (`sandbox` for Debug builds and the simulator,
 *  `production` for TestFlight and the App Store), made at the environment's first send and shut by `close`. An alert
 *  expires after 30 minutes, a fetch after an hour: late is not useful. */
export function makeApnsPusher(config: ApnsConfig, provider: (production: boolean) => ProviderLike = realProvider(config)): Pusher {
  const providers = new Map<string, ProviderLike>();
  const of = (environment: Push["environment"]) => {
    let p = providers.get(environment);
    if (!p) {
      p = provider(environment === "production");
      providers.set(environment, p);
    }
    return p;
  };
  return {
    async send(push) {
      const n = new Notification();
      n.topic = config.topic;
      n.rawPayload = push.payload;
      n.pushType = push.background ? "background" : "alert";
      n.priority = push.background ? 5 : 10;
      n.expiry = Math.floor(Date.now() / 1000) + (push.background ? 3600 : 1800);
      try {
        return answerOf(await of(push.environment).send(n, push.token));
      } catch (e) {
        return { ok: false, status: 0, reason: e instanceof Error ? e.message : "unknown", retire: false };
      }
    },
    async close() {
      await Promise.all([...providers.values()].map((p) => p.shutdown()));
      providers.clear();
    },
  };
}
