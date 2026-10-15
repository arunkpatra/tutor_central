import { createClient } from "@supabase/supabase-js";

/** One outbox row as the sender reads it (0038's `notifications`). */
export type OutboxRow = { id: string; user_id: string; kind: string; title: string | null; body: string | null; link: string | null; background: boolean };
export type LiveToken = { id: string; token: string; environment: "sandbox" | "production" };
/** A row the plan writes (`replace_notifications`'s rows). */
export type NotificationRow = { kind: string; key: string; due_at: string; title?: string; body?: string; link?: string; subject?: string; background?: boolean };

/** The outbox and the tokens, through 0038's named functions as the platform (D83). */
export type OutboxDb = {
  due(now: string, limit: number): Promise<OutboxRow[]>;
  tokens(user: string): Promise<LiveToken[]>;
  mark(id: string, state: "sent" | "failed", apns: unknown): Promise<void>;
  retire(tokenId: string): Promise<void>;
  /** retry_notification (0068): the row due again at a time; false past its third try. */
  retry(id: string, dueAt: string): Promise<boolean>;
  /** A user's plan of some kinds from a time on (`replace_notifications`): the count written. */
  replace(centre: string, user: string, kinds: string[], from: string, rows: NotificationRow[]): Promise<number>;
};

export function makeOutboxDb(url: string, serviceKey: string): OutboxDb {
  const db = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const check = (what: string, error: { message: string } | null) => {
    if (error) throw new Error(`the outbox could not ${what}: ${error.message}`);
  };
  return {
    async due(now, limit) {
      const { data, error } = await db.rpc("due_notifications", { p_now: now, p_limit: limit });
      check("be read", error);
      return (data ?? []) as OutboxRow[];
    },
    async tokens(user) {
      const { data, error } = await db.rpc("live_tokens", { p_user: user });
      check("read the tokens", error);
      return (data ?? []) as LiveToken[];
    },
    async mark(id, state, apns) {
      const { error } = await db.rpc("mark_notification", { p_id: id, p_state: state, p_apns: apns as never });
      check("be marked", error);
    },
    async retire(tokenId) {
      const { error } = await db.rpc("retire_token", { p_id: tokenId });
      check("retire a token", error);
    },
    async retry(id, dueAt) {
      const { data, error } = await db.rpc("retry_notification", { p_id: id, p_due_at: dueAt });
      check("set a row due again", error);
      return data === true;
    },
    async replace(centre, user, kinds, from, rows) {
      const { data, error } = await db.rpc("replace_notifications", { p_centre: centre, p_user: user, p_kinds: kinds, p_from: from, p_rows: rows as never });
      check("be written", error);
      return (data as number | null) ?? 0;
    },
  };
}

/** An outbox in memory for tests: the rows due, each user's tokens; records marks, retirements and replacements. */
export function fakeOutbox(rows: OutboxRow[], tokens: Record<string, LiveToken[]>) {
  const marks: { id: string; state: string; apns: unknown }[] = [];
  // As 0068 keeps them: a row set due again comes back at its time, three times at most.
  const retries: { id: string; dueAt: string }[] = [];
  const waiting: { row: OutboxRow; dueAt: string }[] = [];
  const taken = new Map<string, OutboxRow>();
  const retired: string[] = [];
  const replaced: { centre: string; user: string; kinds: string[]; from: string; rows: NotificationRow[] }[] = [];
  const outbox: OutboxDb & { marks: typeof marks; retired: string[]; replaced: typeof replaced; retries: typeof retries } = {
    marks,
    retired,
    replaced,
    retries,
    async due(now) {
      const back = waiting.filter((w) => w.dueAt <= now);
      for (const w of back) waiting.splice(waiting.indexOf(w), 1);
      const out = [...rows.splice(0, rows.length), ...back.map((w) => w.row)];
      for (const row of out) taken.set(row.id, row);
      return out;
    },
    async tokens(user) {
      return (tokens[user] ?? []).filter((t) => !retired.includes(t.id));
    },
    async mark(id, state, apns) {
      marks.push({ id, state, apns });
    },
    async retire(tokenId) {
      retired.push(tokenId);
    },
    async retry(id, dueAt) {
      if (retries.filter((r) => r.id === id).length >= 3) return false;
      retries.push({ id, dueAt });
      const row = taken.get(id);
      if (row) waiting.push({ row, dueAt });
      return true;
    },
    async replace(centre, user, kinds, from, written) {
      replaced.push({ centre, user, kinds, from, rows: written });
      return written.length;
    },
  };
  return outbox;
}
