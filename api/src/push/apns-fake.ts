import type { Push, PushAnswer, Pusher } from "./apns.js";

/** A pusher in memory (tests, and a local run without the APNs key): answers by token, else sent with an id of its own,
 *  and records each push. */
export function fakePusher(answers: Record<string, PushAnswer>): Pusher & { sent: Push[]; closed: number } {
  const sent: Push[] = [];
  const self = {
    sent,
    closed: 0,
    async send(p: Push): Promise<PushAnswer> {
      sent.push(p);
      return answers[p.token] ?? { ok: true, apnsId: `a-${p.token}` };
    },
    async close() {
      self.closed += 1;
    },
  };
  return self;
}
