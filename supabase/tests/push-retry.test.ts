import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 22 (0068): a push Apple refused for a while (429, 5xx, no answer) is set due again, three times at most.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let row: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `retry-a-${stamp}@example.com`);
  const centre = (await a.rpc("create_centre", { p_name: "Retry A" })).data as string;
  const me = (await a.auth.getUser()).data.user!.id;
  [{ id: row }] = await sql`insert into public.notifications (centre_id, user_id, kind, key, due_at, title, body, state, apns)
    values (${centre}, ${me}, 'fees', ${`fees:retry-${stamp}`}, now(), 't', 'b', 'failed', '[{"status":503}]') returning id`;
});
afterAll(async () => {
  await sql.close();
});

test("a push is set due again three times, then refused", async () => {
  const at = new Date(Date.now() + 60_000).toISOString();
  for (let i = 1; i <= 3; i++) {
    expect((await svc.rpc("retry_notification", { p_id: row, p_due_at: at })).data).toBe(true);
    const [n] = await sql`select state, attempts, apns, due_at from public.notifications where id = ${row}`;
    expect({ state: n.state, attempts: n.attempts, apns: n.apns }).toEqual({ state: "due", attempts: i, apns: null });
    expect(new Date(n.due_at).toISOString()).toBe(at);
    await sql`update public.notifications set state = 'failed' where id = ${row}`;
  }
  expect((await svc.rpc("retry_notification", { p_id: row, p_due_at: at })).data).toBe(false);
  expect((await sql`select state, attempts from public.notifications where id = ${row}`)[0]).toEqual({ state: "failed", attempts: 3 });
});

test("a member retries nothing", async () => {
  expect((await a.rpc("retry_notification", { p_id: row, p_due_at: new Date().toISOString() })).error?.code).toBe("42501");
});
