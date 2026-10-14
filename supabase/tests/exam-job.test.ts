import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 21 (D106): exam preparation is one job per exam item (`exam_prep`, keyed `exam:<item>`), queued when a confirmed
// exam is in its window (the trigger) and each night for the rest (schedule_exam_preps); a member's ask wakes a waiting
// job; the platform writes the split on the item.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let centreB: string;
let itemA: string;
const stamp = Date.now();
const istDay = (days = 0) => new Date(Date.now() + 5.5 * 3_600_000 + days * 86_400_000).toISOString().slice(0, 10);
const exam = (days: number, title = "Science unit test 3") => ({
  centre_id: centreA, kind: "exam", title, subject: "Science", class_level: "8", date: istDay(days), confirmed_at: new Date().toISOString(),
});
const live = (item: string) =>
  sql`select id, kind, state, idempotency_key, input from public.jobs where centre_id = ${centreA} and idempotency_key like ${`exam:${item}%`} and state in ('queued', 'running', 'waiting')`;

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `exam-job-a-${stamp}@example.com`);
  b = await userClient(l, `exam-job-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Exam A" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Exam B" })).data as string;
  itemA = (await a.from("school_items").insert(exam(9)).select("id").single()).data!.id as string;
});
afterAll(async () => {
  await sql`delete from public.jobs where centre_id in (${centreA}, ${centreB})`;
  await sql.close();
});

test("a confirmed exam in its window queues one exam_prep job; the schedule queues no second", async () => {
  const [job] = await live(itemA);
  expect(job).toMatchObject({ kind: "exam_prep", state: "queued", idempotency_key: `exam:${itemA}`, input: { item_id: itemA } });
  await svc.rpc("schedule_exam_preps");
  expect(await live(itemA)).toHaveLength(1);
  await sql`update public.jobs set state = 'done', finished_at = now() where id = ${job.id}`;
  expect(await live(itemA)).toHaveLength(0);
  expect(((await svc.rpc("schedule_exam_preps")).data as number) >= 1).toBe(true);
  const [again] = await live(itemA);
  expect(again.idempotency_key).toStartWith(`exam:${itemA}:`);
  await svc.rpc("schedule_exam_preps");
  expect(await live(itemA)).toHaveLength(1);
});

test("request_exam_prep wakes a waiting job at once and refuses an item of another centre", async () => {
  const [job] = await live(itemA);
  await sql`update public.jobs set state = 'waiting', run_at = now() + interval '15 minutes' where id = ${job.id}`;
  const asked = await a.rpc("request_exam_prep", { p_centre: centreA, p_item: itemA });
  expect(asked.data).toBe(job.id);
  const [woken] = await sql`select run_at <= now() as due from public.jobs where id = ${job.id}`;
  expect(woken.due).toBe(true);
  expect((await b.rpc("request_exam_prep", { p_centre: centreA, p_item: itemA })).error?.message).toContain("not a member");
  expect((await b.rpc("request_exam_prep", { p_centre: centreB, p_item: itemA })).error?.message).toContain("not_found");
});

test("an exam out of its window, a past one or another kind of item queues nothing and is refused", async () => {
  const far = (await a.from("school_items").insert(exam(30, "Half-yearly")).select("id").single()).data!.id as string;
  const past = (await a.from("school_items").insert(exam(-1, "Last week's test")).select("id").single()).data!.id as string;
  const notice = (await a.from("school_items").insert({ centre_id: centreA, kind: "notice", title: "PTM", date: istDay(3), confirmed_at: new Date().toISOString() }).select("id").single()).data!.id as string;
  for (const item of [far, past, notice]) {
    expect(await live(item)).toHaveLength(0);
    expect((await a.rpc("request_exam_prep", { p_centre: centreA, p_item: item })).error?.message).toContain("not_found");
  }
  // A window set to 30 days brings the far exam in: the trigger queues it.
  await a.from("school_items").update({ window_days: 30 }).eq("id", far);
  expect(await live(far)).toHaveLength(1);
});

test("an exam not yet confirmed waits for its confirmation", async () => {
  const draft = (await a.from("school_items").insert({ ...exam(5, "Maths unit test"), confirmed_at: null }).select("id").single()).data!.id as string;
  expect(await live(draft)).toHaveLength(0);
  await a.from("school_items").update({ confirmed_at: new Date().toISOString() }).eq("id", draft);
  expect(await live(draft)).toHaveLength(1);
});

test("the platform writes the split and a member reads it", async () => {
  const split = [{ day: istDay(7), kind: "revise", index: 1, title: "Balancing equations", skills: ["Balance a chemical equation"], skill_ids: [] }];
  expect((await svc.from("school_items").update({ preparation: split }).eq("id", itemA)).error).toBeNull();
  const { data } = await a.from("school_items").select("preparation").eq("id", itemA).single();
  expect(data?.preparation).toEqual(split);
  expect((await svc.from("school_items").update({ preparation: { day: 1 } }).eq("id", itemA)).error?.message).toContain("check");
});

test("the portal names an exam's job by the exam's title", async () => {
  const [row] = await sql`select public.admin_job_subject('exam_prep', ${JSON.stringify({ item_id: itemA })}::text::jsonb, ${`exam:${itemA}`}) as subject`;
  expect(row.subject).toBe("Science unit test 3");
});
