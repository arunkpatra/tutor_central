import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, userClient } from "./client";

// Phase 18: a parent's withdrawal is recorded once, with how and the day (D79; P18-Consent-Withdraw), and stops the
// student's queued note requests at once.
let l: Local;
let sql: SQL;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let userA: string;
const stamp = Date.now();

/** The day in India, `days` from today (Postgres' `current_date` is UTC). */
const istDay = (days = 0) => new Date(Date.now() + 5.5 * 3_600_000 + days * 86_400_000).toISOString().slice(0, 10);
const today = () => istDay(0);
const tomorrow = () => istDay(1);
/** The Monday of this week in India. */
const weekStart = () => {
  const d = new Date(`${today()}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
};

async function student(c: SupabaseClient, centre: string, extra: Record<string, unknown> = {}): Promise<string> {
  const { data, error } = await c.from("students").insert({ centre_id: centre, name: "Withdrawn", ...extra }).select("id").single();
  if (error) throw error;
  return data.id as string;
}
const studentWithConsent = (c: SupabaseClient, centre: string, day: string) =>
  student(c, centre, { consent_at: `${day}T10:00:00+05:30`, consent_phone: "+919811111111", consent_how: "in_person" });

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  a = await userClient(l, `consent-a-${stamp}@example.com`);
  b = await userClient(l, `consent-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Consent A" })).data as string;
  await b.rpc("create_centre", { p_name: "Consent B" });
  userA = (await a.auth.getUser()).data.user!.id;
});
afterAll(async () => {
  await sql.close();
});

test("withdraw_consent records one withdrawn event with how and the day, and clears the columns", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  const { data, error } = await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: today() });
  expect(error).toBeNull();
  const events = await sql`select kind, how, (at at time zone 'Asia/Kolkata')::date::text as day, by_user from public.consent_events
                           where student_id = ${id} order by created_at`;
  expect(events.map((e: { kind: string }) => e.kind)).toEqual(["given", "withdrawn"]);
  expect(events[1]).toMatchObject({ how: "call", day: today(), by_user: userA });
  const [s] = await sql`select consent_at, consent_phone, consent_how from public.students where id = ${id}`;
  expect(s).toEqual({ consent_at: null, consent_phone: null, consent_how: null });
  expect(data).toBe((await sql`select id from public.consent_events where student_id = ${id} and kind = 'withdrawn'`)[0].id);
});

test("an earlier day is recorded as that day", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "whatsapp", p_on: "2026-10-03" });
  const [e] = await sql`select how, (at at time zone 'Asia/Kolkata')::date::text as day from public.consent_events
                        where student_id = ${id} and kind = 'withdrawn'`;
  expect(e).toEqual({ how: "whatsapp", day: "2026-10-03" });
});

test("a day before the agreement, or after today, is refused", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-05");
  expect((await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: "2026-10-04" })).error?.message).toContain("consent_day");
  expect((await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: tomorrow() })).error?.message).toContain("consent_day");
  expect((await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "letter", p_on: today() })).error?.message).toContain("consent_how");
});

test("a student without consent has nothing to withdraw", async () => {
  const id = await student(a, centreA);
  expect((await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: today() })).error?.message).toContain("consent_not_given");
});

test("another centre's member cannot withdraw", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  expect((await b.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: today() })).error?.code).toBe("42501");
});

test("a clear of the columns still records a withdrawal (build 27's Remove)", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  await a.from("students").update({ consent_at: null, consent_phone: null, consent_how: null }).eq("id", id);
  const kinds = await sql`select kind from public.consent_events where student_id = ${id} order by created_at`;
  expect(kinds.map((k: { kind: string }) => k.kind)).toEqual(["given", "withdrawn"]);
});

test.skip("withdraw_consent cancels the student's queued note request", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  const job = (await a.rpc("request_note", { p_centre: centreA, p_student: id, p_week: weekStart() })).data as string;
  await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "in_person", p_on: today() });
  expect((await sql`select state from public.jobs where id = ${job}`)[0].state).toBe("cancelled");
});
