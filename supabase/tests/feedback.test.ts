import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 21 (D107): a tutor's feedback on a generation (an edit at Send, a reason at Make it again or Write again, a
// replacement at Use my own), written only through record_feedback; and a batched call marked by the platform (D108).
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let student: string;
let note: string;
let sheet: string;
const stamp = Date.now();

const generation = async (kind: string, studentId: string | null, status = "ok") => {
  const me = (await a.auth.getUser()).data.user!.id;
  const [{ id }] = await sql`insert into public.ai_generations (centre_id, kind, input, model, status, student_id, user_id)
    values (${centreA}, ${kind}, '{}'::jsonb, 'claude-haiku-5-5', ${status}, ${studentId}, ${me}) returning id`;
  return id as string;
};

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `feedback-a-${stamp}@example.com`);
  b = await userClient(l, `feedback-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Feedback A" })).data as string;
  await b.rpc("create_centre", { p_name: "Feedback B" });
  student = (await a.from("students").insert({ centre_id: centreA, name: "Dev Kumar", class_level: "8" }).select("id").single()).data!.id as string;
  note = await generation("note", student);
  sheet = await generation("sheet", null);
});
afterAll(async () => {
  // A student's insert queues the centre's reminder plan (0045): left due, a later file's claim would take it.
  await sql`delete from public.jobs where centre_id = ${centreA}`;
  await sql.close();
});

test("a member records an edit, a reason and a replacement on their own generation", async () => {
  const edit = await a.rpc("record_feedback", { p_centre: centreA, p_generation: note, p_kind: "edit", p_reason: null, p_revised: "नमस्ते रमेश जी" });
  const again = await a.rpc("record_feedback", { p_centre: centreA, p_generation: note, p_kind: "again", p_reason: " Less about marks ", p_revised: null });
  const own = await a.rpc("record_feedback", { p_centre: centreA, p_generation: sheet, p_kind: "replace", p_reason: null, p_revised: { photo: true } });
  for (const r of [edit, again, own]) expect(r.error).toBeNull();
  const rows = (await a.from("generation_feedback").select("generation_id, student_id, kind, reason, revised").order("created_at")).data;
  expect(rows).toEqual([
    { generation_id: note, student_id: student, kind: "edit", reason: null, revised: "नमस्ते रमेश जी" },
    { generation_id: note, student_id: student, kind: "again", reason: "Less about marks", revised: null },
    { generation_id: sheet, student_id: null, kind: "replace", reason: null, revised: { photo: true } },
  ]);
});

test("again without a reason is refused; edit or replace without what was sent is refused", async () => {
  expect((await a.rpc("record_feedback", { p_centre: centreA, p_generation: note, p_kind: "again", p_reason: "  ", p_revised: null })).error).not.toBeNull();
  expect((await a.rpc("record_feedback", { p_centre: centreA, p_generation: note, p_kind: "edit", p_reason: null, p_revised: null })).error).not.toBeNull();
  expect((await a.rpc("record_feedback", { p_centre: centreA, p_generation: note, p_kind: "liked", p_reason: "x", p_revised: null })).error).not.toBeNull();
  expect((await a.rpc("record_feedback", { p_centre: centreA, p_generation: note, p_kind: "again", p_reason: "x".repeat(201), p_revised: null })).error).not.toBeNull();
});

test("a member writes feedback only through the function", async () => {
  const direct = await a.from("generation_feedback").insert({ centre_id: centreA, generation_id: note, kind: "again", reason: "shorter" });
  expect(direct.error?.message).toContain("feedback_through_the_function");
});

test("a member of another centre records nothing and reads nothing", async () => {
  expect((await b.rpc("record_feedback", { p_centre: centreA, p_generation: note, p_kind: "again", p_reason: "shorter", p_revised: null })).error?.message).toContain("not a member");
  expect((await b.from("generation_feedback").select("id")).data).toEqual([]);
});

test("a feedback row goes with the student", async () => {
  const other = (await a.from("students").insert({ centre_id: centreA, name: "Riya Sharma", class_level: "5" }).select("id").single()).data!.id as string;
  const theirs = await generation("can_do", other);
  await a.rpc("record_feedback", { p_centre: centreA, p_generation: theirs, p_kind: "again", p_reason: "Warmer", p_revised: null });
  expect((await a.from("generation_feedback").select("id").eq("student_id", other)).data).toHaveLength(1);
  await a.from("students").delete().eq("id", other);
  expect((await sql`select id from public.generation_feedback where student_id = ${other}`).length).toBe(0);
});

test("a call is not batched until the platform marks it so at the finish", async () => {
  const pending = await generation("sheet", null, "pending");
  expect((await sql`select batched from public.ai_generations where id = ${pending}`)[0].batched).toBe(false);
  expect((await svc.from("ai_generations").update({ status: "ok", batched: true, finished_at: new Date().toISOString() }).eq("id", pending)).error).toBeNull();
  expect((await sql`select batched from public.ai_generations where id = ${pending}`)[0].batched).toBe(true);
});
