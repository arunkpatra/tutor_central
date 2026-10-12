import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, userClient } from "./client";

// Phase 18: what a member may queue (plan decision 9): a plan, a note, an export, each limited to its kind and the
// centre's own rows, each answering the live job for the same subject (a second tap starts nothing).
let l: Local;
let sql: SQL;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let centreB: string;
let classA: string;
let studentA: string;
let userA: string;
const stamp = Date.now();

const istDay = (days = 0) => new Date(Date.now() + 5.5 * 3_600_000 + days * 86_400_000).toISOString().slice(0, 10);
const today = () => istDay(0);
const weekStart = () => {
  const d = new Date(`${today()}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
};
/** Each test asks afresh: the jobs a test leaves would answer the next one's ask. */
const clear = () => sql`delete from public.jobs where centre_id in (${centreA}, ${centreB})`;

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  a = await userClient(l, `requests-a-${stamp}@example.com`);
  b = await userClient(l, `requests-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Requests A" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Requests B" })).data as string;
  userA = (await a.auth.getUser()).data.user!.id;
  classA = (await a.from("classes").insert({ centre_id: centreA, name: "Evening batch", meeting_days: [1, 3, 5] }).select("id").single()).data!.id;
  studentA = (await a.from("students").insert({ centre_id: centreA, name: "Asked", class_id: classA }).select("id").single()).data!.id;
});
afterAll(async () => {
  await clear();
  await sql.close();
});

test("request_plan queues one plan job for the batch and day; a second ask answers the same job", async () => {
  await clear();
  const first = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  const again = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  expect(again).toBe(first);
  const [job] = await sql`select kind, idempotency_key, input, created_by from public.jobs where id = ${first}`;
  expect(job).toMatchObject({ kind: "plan", idempotency_key: `plan:${classA}:${today()}`, input: { class_id: classA, date: today() }, created_by: userA });
});

test("after a failed plan job, a new ask is a new job", async () => {
  await clear();
  const first = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  await sql`update public.jobs set state = 'failed' where id = ${first}`;
  const next = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  expect(next).not.toBe(first);
  expect((await sql`select idempotency_key from public.jobs where id = ${next}`)[0].idempotency_key).toStartWith(`plan:${classA}:${today()}:`);
});

test("choices make a replacing plan job", async () => {
  await clear();
  const choices = { groups: 2, subjects: { "1": "Science" } };
  const id = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today(), p_choices: choices })).data;
  expect((await sql`select input from public.jobs where id = ${id}`)[0].input).toMatchObject({ replace: true, choices });
});

test("a replacing ask while a plain job runs answers the plain job", async () => {
  await clear();
  const plain = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data;
  const again = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today(), p_choices: { groups: 1 } })).data;
  expect(again).toBe(plain);
});

test("a class of another centre, or a student of another centre, is refused", async () => {
  expect((await b.rpc("request_plan", { p_centre: centreB, p_class: classA, p_date: today() })).error?.message).toContain("not_found");
  expect((await b.rpc("request_export", { p_centre: centreB, p_student: studentA })).error?.message).toContain("not_found");
  expect((await b.rpc("request_note", { p_centre: centreB, p_student: studentA, p_week: weekStart() })).error?.message).toContain("not_found");
  expect((await b.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).error?.code).toBe("42501");
});

test("an archived batch is not planned, and a note's week starts on a Monday", async () => {
  const archived = (await a.from("classes").insert({ centre_id: centreA, name: "Gone", archived_at: new Date().toISOString() }).select("id").single()).data!.id;
  expect((await a.rpc("request_plan", { p_centre: centreA, p_class: archived, p_date: today() })).error?.message).toContain("not_found");
  const tuesday = new Date(`${weekStart()}T00:00:00Z`);
  tuesday.setUTCDate(tuesday.getUTCDate() + 1);
  expect((await a.rpc("request_note", { p_centre: centreA, p_student: studentA, p_week: tuesday.toISOString().slice(0, 10) })).error?.message).toContain("note_week");
});

test("request_export and request_note queue their own kind with the student", async () => {
  await clear();
  const e = (await a.rpc("request_export", { p_centre: centreA, p_student: studentA })).data;
  const n = (await a.rpc("request_note", { p_centre: centreA, p_student: studentA, p_week: weekStart() })).data;
  const rows = await sql`select kind, input from public.jobs where id in (${e}, ${n}) order by kind`;
  expect(rows).toEqual([
    { kind: "note_day", input: { student_id: studentA, week: weekStart() } },
    { kind: "export", input: { student_id: studentA } },
  ]);
  expect((await a.rpc("request_export", { p_centre: centreA, p_student: studentA })).data).toBe(e);
});

test("request_job queues nothing a request could not: another kind, or a subject outside the centre", async () => {
  const outside = await a.rpc("request_job", { p_centre: centreA, p_kind: "pdf", p_subject: studentA, p_input: { student_id: studentA } });
  expect(outside.error?.message).toContain("job_kind");
  const other = (await b.from("students").insert({ centre_id: centreB, name: "Other" }).select("id").single()).data!.id;
  const forged = await a.rpc("request_job", { p_centre: centreA, p_kind: "export", p_subject: other, p_input: { student_id: other } });
  expect(forged.error?.message).toContain("not_found");
});

test("a member still cannot call enqueue_job or insert a job", async () => {
  expect((await a.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "x" })).error).not.toBeNull();
  expect((await a.from("jobs").insert({ centre_id: centreA, kind: "export", idempotency_key: "y" })).error).not.toBeNull();
});
