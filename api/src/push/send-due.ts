import type { Clock } from "../jobs/types.js";
import type { Pusher } from "./apns.js";
import type { OutboxDb } from "./db.js";
import { alertPayload, fetchPayload } from "./payload.js";

/** The minute tick's send (plan decision 7): each row due goes to every live token of its user; a token Apple retired is
 *  retired and never tried again; the row is sent when any device took it, else failed, with each device's answer. A
 *  429 or a 5xx fails this minute's row and is not retried: a reminder is late or not at all. */
export async function sendDue(deps: { outbox: OutboxDb; pusher: Pusher; clock: Clock }, limit = 200): Promise<{ sent: number; failed: number; retired: number }> {
  const counts = { sent: 0, failed: 0, retired: 0 };
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
    for (const token of tokens) {
      const answer = await deps.pusher.send({ token: token.token, environment: token.environment, payload, background: row.background });
      if (answer.ok) {
        delivered = true;
        answers.push({ token: token.id, apnsId: answer.apnsId });
        continue;
      }
      answers.push({ token: token.id, status: answer.status, reason: answer.reason });
      if (answer.retire) {
        await deps.outbox.retire(token.id);
        counts.retired += 1;
      }
    }
    await deps.outbox.mark(row.id, delivered ? "sent" : "failed", answers);
    if (delivered) counts.sent += 1;
    else counts.failed += 1;
  }
  return counts;
}
