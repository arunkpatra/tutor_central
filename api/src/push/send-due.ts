import type { Clock } from "../jobs/types.js";
import type { Pusher } from "./apns.js";
import type { OutboxDb } from "./db.js";
import { alertPayload, fetchPayload } from "./payload.js";

/** A minute between a refused push's tries (retry_notification keeps three). */
const RETRY_MS = 60_000;
/** Apple's "not now": too many requests, its own trouble, or no answer at all. */
const transient = (status: number) => status === 0 || status === 429 || status >= 500;

/** The minute tick's send (plan decision 7): each row due goes to every live token of its user; a token Apple retired is
 *  retired and never tried again; the row is sent when any device took it. A connection that dropped before Apple
 *  answered (no status) is tried once more at once: that is not Apple's answer (hand run 4). A row no device took that
 *  Apple refused for a while (a 429, a 5xx, no answer) is set due a minute later, three times at most (Phase 22,
 *  0068); else, or past the third, it is failed with each device's answer. No token is failed at once. */
export async function sendDue(
  deps: { outbox: OutboxDb; pusher: Pusher; clock: Clock },
  limit = 200,
): Promise<{ sent: number; failed: number; retired: number; retried: number }> {
  const counts = { sent: 0, failed: 0, retired: 0, retried: 0 };
  const rows = await deps.outbox.due(new Date(deps.clock.now()).toISOString(), limit);
  for (const row of rows) {
    const tokens = await deps.outbox.tokens(row.user_id);
    if (tokens.length === 0) {
      await deps.outbox.mark(row.id, "failed", { reason: "no_token" });
      counts.failed += 1;
      continue;
    }
    const payload = row.background
      ? fetchPayload({ id: row.id })
      : alertPayload({ id: row.id, kind: row.kind, title: row.title ?? "", body: row.body ?? "", link: row.link });
    const answers: unknown[] = [];
    let delivered = false;
    let later = false;
    for (const token of tokens) {
      const push = { token: token.token, environment: token.environment, payload, background: row.background };
      let answer = await deps.pusher.send(push);
      if (!answer.ok && answer.status === 0) answer = await deps.pusher.send(push);
      if (answer.ok) {
        delivered = true;
        answers.push({ token: token.id, apnsId: answer.apnsId });
        continue;
      }
      answers.push({ token: token.id, status: answer.status, reason: answer.reason });
      if (answer.retire) {
        await deps.outbox.retire(token.id);
        counts.retired += 1;
      } else if (transient(answer.status)) later = true;
    }
    if (!delivered && later && (await deps.outbox.retry(row.id, new Date(deps.clock.now() + RETRY_MS).toISOString()))) {
      counts.retried += 1;
      continue;
    }
    await deps.outbox.mark(row.id, delivered ? "sent" : "failed", answers);
    if (delivered) counts.sent += 1;
    else counts.failed += 1;
  }
  return counts;
}
