import { SQL } from "bun";
import { afterAll, beforeAll, beforeEach, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, userClient } from "./client";

// Phase 18: the day's jobs are written by pg_cron (plan decision 8), only for a centre in use (D91), and a change to a
// class, an event, a fee or the settings queues a reminder plan within the minute. Times are fixed through `p_now`, in
// 2030 so no other file's activity makes a centre look in use.
let l: Local;
let sql: SQL;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let centreB: string;
let classId: string;
const stamp = Date.now();

/** A batch of centre A made by its member; `days` are ISO weekdays (Monday 1). */
async function batch(opts: { days: number[]; start: string }): Promise<string> {
  const { data, error } = await a
    .from("classes")
    .insert({ centre_id: centreA, name: "Evening batch", meeting_days: opts.days, start_time: opts.start })
    .select("id")
    .single();
  if (error) throw error;
  classId = data.id as string;
  return classId;
}
/** The app opened at `at` (Phase 17's activity log). */
const opened = (at: string) => sql`insert into public.events (centre_id, user_id, kind, at)
  select ${centreA}, user_id, 'app_opened', ${at} from public.centre_members where centre_id = ${centreA}`;
const one = async (q: Promise<Record<string, unknown>[]>) => Object.values((await q)[0]!)[0];

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  a = await userClient(l, `schedules-a-${stamp}@example.com`);
  b = await userClient(l, `schedules-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Schedules A" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Schedules B" })).data as string;
});
beforeEach(async () => {
  await sql`delete from public.plans where centre_id = ${centreA}`;
  await sql`delete from public.classes where centre_id = ${centreA}`;
  await sql`delete from public.events where centre_id = ${centreA}`;
  await sql`delete from public.device_tokens where user_id in (select user_id from public.centre_members where centre_id in (${centreA}, ${centreB}))`;
  await sql`delete from public.reminder_settings where centre_id = ${centreA}`;
  await sql`delete from public.jobs`;
});
afterAll(async () => {
  await sql`delete from public.jobs`;
  await sql.close();
});

test("a batch meeting today in a centre in use gets one plan job at 05:30", async () => {
  await opened("2030-11-03T08:00:00+05:30");
  await batch({ days: [1], start: "17:00" });
  expect(await one(sql`select public.schedule_plans('2030-11-04T00:15:00+05:30')`)).toBe(1);
  expect(await one(sql`select public.schedule_plans('2030-11-04T00:30:00+05:30')`)).toBe(0);
  const jobs = await sql`select idempotency_key, input, (run_at at time zone 'Asia/Kolkata')::text as at from public.jobs where kind = 'plan'`;
  expect([...jobs]).toEqual([{ idempotency_key: `plan:${classId}:2030-11-04`, input: { class_id: classId, date: "2030-11-04" }, at: "2030-11-04 05:30:00" }]);
});

test("an early batch is planned two hours before it, never before 03:30", async () => {
  await opened("2030-11-03T08:00:00+05:30");
  await batch({ days: [1], start: "06:30" });
  await batch({ days: [1], start: "05:00" });
  await sql`select public.schedule_plans('2030-11-04T00:15:00+05:30')`;
  const times = await sql`select (run_at at time zone 'Asia/Kolkata')::time::text as t from public.jobs where kind = 'plan' order by run_at`;
  expect(times.map((r: { t: string }) => r.t)).toEqual(["03:30:00", "04:30:00"]);
});

test("a batch made later in the day is planned at once; one already begun is not", async () => {
  await opened("2030-11-03T08:00:00+05:30");
  await batch({ days: [1], start: "17:00" });
  await batch({ days: [1], start: "10:00" });
  expect(await one(sql`select public.schedule_plans('2030-11-04T14:00:00+05:30')`)).toBe(1);
  expect((await sql`select (run_at at time zone 'Asia/Kolkata')::text as at from public.jobs where kind = 'plan'`)[0].at).toBe("2030-11-04 14:00:00");
});

test("no plan job is written for a centre idle 14 days", async () => {
  await opened("2030-10-20T08:00:00+05:30");
  await batch({ days: [1], start: "17:00" });
  expect(await one(sql`select public.schedule_plans('2030-11-04T00:15:00+05:30')`)).toBe(0);
});

test("a batch with today's plan, a batch not meeting today and an archived batch get nothing", async () => {
  await opened("2030-11-03T08:00:00+05:30");
  const planned = await batch({ days: [1], start: "17:00" });
  await sql`insert into public.plans (centre_id, class_id, date) values (${centreA}, ${planned}, '2030-11-04')`;
  await batch({ days: [2], start: "17:00" });
  const archived = await batch({ days: [1], start: "17:00" });
  await sql`update public.classes set archived_at = now() where id = ${archived}`;
  expect(await one(sql`select public.schedule_plans('2030-11-04T00:15:00+05:30')`)).toBe(0);
});

test("a day already asked for by a member gets no second job", async () => {
  await opened("2030-11-03T08:00:00+05:30");
  const id = await batch({ days: [1], start: "17:00" });
  await sql`insert into public.jobs (centre_id, kind, idempotency_key, input, state)
            values (${centreA}, 'plan', ${`plan:${id}:2030-11-04`}, ${{ class_id: id, date: "2030-11-04" }}, 'failed')`;
  expect(await one(sql`select public.schedule_plans('2030-11-04T00:15:00+05:30')`)).toBe(0);
});

test("the note day is planned two hours before its time; Sunday 18:00 when unset", async () => {
  await opened("2030-11-09T08:00:00+05:30");
  const sunday = await batch({ days: [1, 3, 5], start: "17:00" });
  const saturday = await batch({ days: [2], start: "17:00" });
  await sql`update public.classes set note_weekday = 6, note_time = '10:00' where id = ${saturday}`;
  expect(await one(sql`select public.schedule_note_days('2030-11-10T00:15:00+05:30')`)).toBe(1);
  expect(await one(sql`select public.schedule_note_days('2030-11-10T00:30:00+05:30')`)).toBe(0);
  const [j] = await sql`select idempotency_key, input, (run_at at time zone 'Asia/Kolkata')::text as at from public.jobs where kind = 'note_day'`;
  expect(j).toEqual({ idempotency_key: `note_day:${sunday}:2030-11-10`, input: { class_id: sunday, date: "2030-11-10" }, at: "2030-11-10 16:00:00" });
});

test("no note day job for a centre idle 14 days", async () => {
  await batch({ days: [1], start: "17:00" });
  expect(await one(sql`select public.schedule_note_days('2030-11-10T00:15:00+05:30')`)).toBe(0);
});

test("a class change queues one reminder plan for its centre while one waits", async () => {
  const id = await batch({ days: [1], start: "17:00" });
  await a.from("classes").update({ start_time: "17:30" }).eq("id", id);
  await a.from("classes").update({ start_time: "17:45" }).eq("id", id);
  const rows = await sql`select input from public.jobs where kind = 'reminder_sweep' and centre_id = ${centreA}`;
  expect([...rows]).toEqual([{ input: { centre_id: centreA } }]);
});

test("an event, a fee and the settings each queue a reminder plan once the last one is taken", async () => {
  const taken = () => sql`update public.jobs set state = 'done' where kind = 'reminder_sweep' and centre_id = ${centreA}`;
  const count = async () => (await sql`select count(*)::int as n from public.jobs where kind = 'reminder_sweep' and centre_id = ${centreA}`)[0].n;
  await a.from("calendar_events").insert({ centre_id: centreA, title: "Parents meeting", date: "2030-11-05" });
  expect(await count()).toBe(1);
  await taken();
  const s = (await a.from("students").insert({ centre_id: centreA, name: "Fee" }).select("id").single()).data!.id;
  await a.from("fee_invoices").insert({ centre_id: centreA, student_id: s, period: "2030-11-01", amount: 1000 });
  expect(await count()).toBe(2);
  await taken();
  await a.from("reminder_settings").insert({ centre_id: centreA, class_minutes: 15 });
  expect(await count()).toBe(3);
});

test("schedule_reminders queues a plan for each centre with a live token, and none without", async () => {
  await a.from("device_tokens").insert({ device_id: `sim-a-${stamp}`, token: "aa", environment: "sandbox" });
  await b.from("device_tokens").insert({ device_id: `sim-b-${stamp}`, token: "bb", environment: "sandbox", retired_at: new Date().toISOString() });
  await sql`select public.schedule_reminders(now())`;
  await sql`select public.schedule_reminders(now())`;
  const rows = await sql`select centre_id from public.jobs where kind = 'reminder_sweep' and centre_id in (${centreA}, ${centreB})`;
  expect(rows.map((r: { centre_id: string }) => r.centre_id)).toEqual([centreA]);
});

test("the three schedules are on pg_cron", async () => {
  const jobs = await sql`select jobname, schedule from cron.job where jobname like 'schedule_%' order by jobname`;
  expect([...jobs]).toEqual([
    { jobname: "schedule_note_days", schedule: "*/15 * * * *" },
    { jobname: "schedule_plans", schedule: "*/15 * * * *" },
    { jobname: "schedule_reminders", schedule: "5 * * * *" },
  ]);
});
