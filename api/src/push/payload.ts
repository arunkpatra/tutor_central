/** What a push carries (D72): the words the tutor reads, the link a tap opens and the outbox row's id, never a student's
 *  or a tutor's name beyond the batch label in the words. */
export type PushPayload = Record<string, unknown>;

/** An alert: the title and body, the link, grouped on the lock screen by its kind. */
export function alertPayload(n: { id: string; kind: string; title: string; body: string; link: string | null }): PushPayload {
  return { aps: { alert: { title: n.title, body: n.body }, sound: "default", "thread-id": n.kind }, link: n.link, id: n.id };
}

/** A background push (the plan's fetch, plan decision 17): no words; the app reads today's plans into its copy. */
export function fetchPayload(n: { id: string }): PushPayload {
  return { aps: { "content-available": 1 }, fetch: "plan", id: n.id };
}
