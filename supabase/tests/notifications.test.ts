import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 18: the tutor's reminder settings on the account (plan decision 6) and the notifications outbox the worker's
// tick sends (decision 7). The outbox's functions are the platform's alone.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let userA: string;
const stamp = Date.now();

const iso = (seconds: number) => new Date(Date.now() + seconds * 1000).toISOString();
const row = (key: string, minutes: number) => ({
  kind: key.split(":")[0],
  key,
  due_at: iso(minutes * 60),
  title: "t",
  body: "b",
  link: "tutorcentral://today",
});
const replace = (kinds: string[], from: string, rows: ReturnType<typeof row>[]) =>
  svc.rpc("replace_notifications", { p_centre: centreA, p_user: userA, p_kinds: kinds, p_from: from, p_rows: rows });

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `notifications-a-${stamp}@example.com`);
  b = await userClient(l, `notifications-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Notifications A" })).data as string;
  await b.rpc("create_centre", { p_name: "Notifications B" });
  userA = (await a.auth.getUser()).data.user!.id;
});
afterAll(async () => {
  await sql`delete from public.notifications where user_id = ${userA}`;
  await sql.close();
});

test("a tutor reads and writes their own reminder settings, not another's", async () => {
  expect((await a.from("reminder_settings").insert({ centre_id: centreA, class_minutes: 15 })).error).toBeNull();
  expect((await a.from("reminder_settings").select("class_minutes, plan_ready_on, notes_ready_on, fees_day, event_lead")).data).toEqual([
    { class_minutes: 15, plan_ready_on: true, notes_ready_on: true, fees_day: 5, event_lead: "hour1" },
  ]);
  expect((await a.from("reminder_settings").update({ fees_day: 10 }).eq("centre_id", centreA).select("fees_day")).data).toEqual([{ fees_day: 10 }]);
  expect((await b.from("reminder_settings").select("*")).data).toEqual([]);
  expect((await b.from("reminder_settings").insert({ centre_id: centreA })).error).not.toBeNull();
  expect((await b.from("reminder_settings").update({ fees_day: 1 }).eq("centre_id", centreA).select("id")).data).toEqual([]);
  expect((await a.from("reminder_settings").insert({ centre_id: centreA, class_minutes: 20 })).error).not.toBeNull();
  expect((await a.from("reminder_settings").update({ fees_day: 29 }).eq("centre_id", centreA)).error).not.toBeNull();
});

test("a member reads their own notifications and writes none", async () => {
  await replace(["class"], iso(0), [row("class:c1:t1", 30)]);
  expect((await a.from("notifications").select("key")).data).toEqual([{ key: "class:c1:t1" }]);
  expect((await b.from("notifications").select("key")).data).toEqual([]);
  expect((await a.from("notifications").insert({ centre_id: centreA, user_id: userA, kind: "class", key: "k", due_at: iso(1), title: "t", body: "b" })).error).not.toBeNull();
  expect((await a.rpc("replace_notifications", { p_centre: centreA, p_user: userA, p_kinds: [], p_from: iso(0), p_rows: [] })).error).not.toBeNull();
  const probe = crypto.randomUUID();
  const calls: [string, Record<string, unknown>][] = [
    ["due_notifications", { p_now: iso(0), p_limit: 1 }],
    ["mark_notification", { p_id: probe, p_state: "sent", p_apns: {} }],
    ["live_tokens", { p_user: userA }],
    ["retire_token", { p_id: probe }],
  ];
  for (const [fn, args] of calls) {
    expect({ fn, code: (await a.rpc(fn, args)).error?.code }).toEqual({ fn, code: "42501" });
  }
  await sql`delete from public.notifications where user_id = ${userA}`;
});

test("a replan cancels a future unsent row it no longer writes, keeps sent rows, and upserts the rest", async () => {
  await replace(["class"], iso(0), [row("class:c1:16:45", 45), row("class:c1:tomorrow", 1500)]);
  await sql`update public.notifications set state = 'sent' where key = 'class:c1:tomorrow'`;
  expect((await replace(["class"], iso(0), [row("class:c1:17:15", 75)])).data).toBe(1);
  const rows = await sql`select key, state from public.notifications where user_id = ${userA} order by key`;
  expect([...rows]).toEqual([
    { key: "class:c1:16:45", state: "cancelled" },
    { key: "class:c1:17:15", state: "due" },
    { key: "class:c1:tomorrow", state: "sent" },
  ]);
  // A row planned again after a cancel is due again; another kind's rows are left alone.
  await replace(["fees"], iso(0), [row("fees:2026-11", 60)]);
  await replace(["class"], iso(0), [row("class:c1:16:45", 45)]);
  const after = await sql`select key, state from public.notifications where user_id = ${userA} order by key`;
  expect([...after]).toEqual([
    { key: "class:c1:16:45", state: "due" },
    { key: "class:c1:17:15", state: "cancelled" },
    { key: "class:c1:tomorrow", state: "sent" },
    { key: "fees:2026-11", state: "due" },
  ]);
  await sql`delete from public.notifications where user_id = ${userA}`;
});

test("due rows come once to two takers; rows older than thirty minutes expire unsent", async () => {
  await replace(["fees"], iso(-3600), [row("fees:old", -45), row("fees:now", -1), row("fees:later", 10)]);
  const [x, y] = await Promise.all([svc.rpc("due_notifications", { p_now: iso(0) }), svc.rpc("due_notifications", { p_now: iso(0) })]);
  expect([...(x.data ?? []), ...(y.data ?? [])].map((n: { key: string }) => n.key)).toEqual(["fees:now"]);
  const states = await sql`select key, state, sent_at is not null as stamped from public.notifications where user_id = ${userA} order by key`;
  expect([...states]).toEqual([
    { key: "fees:later", state: "due", stamped: false },
    { key: "fees:now", state: "sent", stamped: true },
    { key: "fees:old", state: "expired", stamped: false },
  ]);
  await sql`delete from public.notifications where user_id = ${userA}`;
});

test("the sender marks a row with Apple's answer, reads live tokens and retires one", async () => {
  await replace(["class"], iso(-60), [row("class:c2:now", 0)]);
  const [n] = (await svc.rpc("due_notifications", { p_now: iso(1) })).data!;
  expect((await svc.rpc("mark_notification", { p_id: n.id, p_state: "failed", p_apns: { reason: "no_token" } })).error).toBeNull();
  expect((await sql`select state, apns from public.notifications where id = ${n.id}`)[0]).toEqual({ state: "failed", apns: { reason: "no_token" } });
  await a.from("device_tokens").insert({ device_id: `sim-${stamp}`, token: "tok-a", environment: "sandbox" });
  const tokens = (await svc.rpc("live_tokens", { p_user: userA })).data as { id: string; token: string; environment: string }[];
  expect(tokens.map((t) => [t.token, t.environment])).toEqual([["tok-a", "sandbox"]]);
  await svc.rpc("retire_token", { p_id: tokens[0].id });
  expect((await svc.rpc("live_tokens", { p_user: userA })).data).toEqual([]);
  await sql`delete from public.notifications where user_id = ${userA}`;
});
