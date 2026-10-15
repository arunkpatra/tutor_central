import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 18: the sweep's retention (plan decision 27) through named functions the platform alone may call: exports past
// seven days named for removal, notifications past thirty days and the platform's own done jobs past seven days deleted.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let centreA: string;
let userA: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `retention-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Retention A" })).data as string;
  userA = (await a.auth.getUser()).data.user!.id;
});
afterAll(async () => {
  await svc.storage.from("exports").remove([`${centreA}/s/old-${stamp}.pdf`, `${centreA}/s/new-${stamp}.pdf`]);
  await sql.close();
});

test("old_exports names the exports made more than seven days ago, not the newer", async () => {
  const pdf = new Blob(["%PDF-1.7\n"], { type: "application/pdf" });
  await svc.storage.from("exports").upload(`${centreA}/s/old-${stamp}.pdf`, pdf);
  await svc.storage.from("exports").upload(`${centreA}/s/new-${stamp}.pdf`, pdf);
  await sql`update storage.objects set created_at = now() - interval '8 days' where bucket_id = 'exports' and name = ${`${centreA}/s/old-${stamp}.pdf`}`;
  const names = ((await svc.rpc("old_exports", { p_before: new Date(Date.now() - 7 * 86_400_000).toISOString(), p_limit: 100 })).data ?? []) as { name: string }[];
  expect(names.map((n) => n.name)).toContain(`${centreA}/s/old-${stamp}.pdf`);
  expect(names.map((n) => n.name)).not.toContain(`${centreA}/s/new-${stamp}.pdf`);
});

test("trim_platform deletes notifications past thirty days and done sweeps and reminder plans past seven, nothing else", async () => {
  const at = (days: number) => new Date(Date.now() - days * 86_400_000).toISOString();
  await sql`insert into public.notifications (centre_id, user_id, kind, key, due_at, title, body, state, created_at)
            values (${centreA}, ${userA}, 'fees', ${`fees:old-${stamp}`}, ${at(31)}, 't', 'b', 'sent', ${at(31)}),
                   (${centreA}, ${userA}, 'fees', ${`fees:new-${stamp}`}, ${at(29)}, 't', 'b', 'sent', ${at(29)})`;
  await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, finished_at)
            values (${centreA}, 'reminder_sweep', ${`r-old-${stamp}`}, 'done', ${at(8)}),
                   (${centreA}, 'reminder_sweep', ${`r-new-${stamp}`}, 'done', ${at(6)}),
                   (${centreA}, 'plan', ${`p-old-${stamp}`}, 'done', ${at(8)}),
                   (null, 'sweep', ${`s-old-${stamp}`}, 'done', ${at(8)}),
                   (${centreA}, 'reminder_sweep', ${`r-failed-${stamp}`}, 'failed', ${at(8)})`;
  const trimmed = (await svc.rpc("trim_platform", { p_now: new Date().toISOString() })).data as { notifications: number; jobs: number };
  expect(trimmed.notifications).toBeGreaterThanOrEqual(1);
  expect(trimmed.jobs).toBeGreaterThanOrEqual(2);
  const keys = (await sql`select key from public.notifications where user_id = ${userA}`).map((r: { key: string }) => r.key);
  expect(keys).toEqual([`fees:new-${stamp}`]);
  const left = (await sql`select idempotency_key from public.jobs where idempotency_key like ${`%-${stamp}`} order by 1`).map((r: { idempotency_key: string }) => r.idempotency_key);
  expect(left).toEqual([`p-old-${stamp}`, `r-failed-${stamp}`, `r-new-${stamp}`]);
});

test("a member can call neither", async () => {
  expect((await a.rpc("old_exports", { p_before: new Date().toISOString(), p_limit: 1 })).error?.code).toBe("42501");
  expect((await a.rpc("trim_platform", { p_now: new Date().toISOString() })).error?.code).toBe("42501");
});

// Phase 22 (D79, D117, 0068): what was sent about a student is reduced to a reference after 90 days.
test("an input older than 90 days becomes a reference; the output, the cost and a younger row stay", async () => {
  const [{ id: student }] = await sql`insert into public.students (centre_id, name, class_level, consent_at, consent_phone, consent_how)
    values (${centreA}, 'Dev', '8', now(), '+919876543210', 'whatsapp') returning id`;
  const row = async (days: number, extra: { student?: string | null; input?: Record<string, unknown> } = {}) => {
    const [{ id }] = await sql`insert into public.ai_generations (centre_id, kind, input, model, status, student_id, output, cost_paise, finished_at, created_at)
      values (${centreA}, 'note', ${JSON.stringify(extra.input ?? { student: "Dev", week: { right: 7 } })}::text::jsonb, 'claude-haiku-5-5', 'ok',
              ${extra.student === undefined ? student : extra.student}, 'Namaste', 37, now(), now() - make_interval(days => ${days})) returning id`;
    return id as string;
  };
  const old = await row(91);
  const young = await row(10);
  const group = await row(91, { student: null, input: { kind: "sheet", topic: "Fractions" } });
  const v1 = await row(91, { student: null, input: { studentName: "Dev", observations: "careless with signs" } });
  const reduced = (await svc.rpc("reduce_old_inputs", { p_before: new Date(Date.now() - 90 * 86_400_000).toISOString(), p_limit: 500 })).data as number;
  expect(reduced).toBeGreaterThanOrEqual(2);
  const read = async (id: string) => (await sql`select input, output, cost_paise, status from public.ai_generations where id = ${id}`)[0];
  expect(await read(old)).toMatchObject({ input: { kind: "note", student_id: student }, output: "Namaste", cost_paise: 37, status: "ok" });
  expect((await read(old)).input.reduced_at).toBeTruthy();
  expect((await read(old)).input).not.toHaveProperty("week");
  expect((await read(v1)).input).toMatchObject({ kind: "note", student_id: null });
  expect((await read(young)).input).toEqual({ student: "Dev", week: { right: 7 } });
  expect((await read(group)).input).toEqual({ kind: "sheet", topic: "Fractions" });
  // Done once: a second sweep leaves a reduced row as it is.
  const again = (await svc.rpc("reduce_old_inputs", { p_before: new Date(Date.now() - 90 * 86_400_000).toISOString(), p_limit: 500 })).data as number;
  expect(again).toBe(0);

  // The portal says reduced, not held, and shows no input.
  const call = (await svc.rpc("admin_call", { p_id: old })).data as { input_reduced: boolean; input_held: boolean; input: unknown; output: string };
  expect(call).toMatchObject({ input_reduced: true, input_held: false, input: null, output: "Namaste" });
  expect(((await svc.rpc("admin_call", { p_id: young })).data as { input_reduced: boolean }).input_reduced).toBe(false);
});

test("a replay of a reduced row answers its output", async () => {
  const key = `reduce-replay-${stamp}`;
  const first = (await a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: { topic: "x" }, p_model: "claude-haiku-5-5", p_key: key, p_input_hash: "h" })).data as { id: string };
  await svc.from("ai_generations").update({ status: "ok", output: "the sheet", finished_at: new Date().toISOString() }).eq("id", first.id);
  await sql`update public.ai_generations set student_id = (select id from public.students where centre_id = ${centreA} limit 1) where id = ${first.id}`;
  expect((await svc.rpc("reduce_old_inputs", { p_before: new Date(Date.now() + 60_000).toISOString(), p_limit: 500 })).data).toBeGreaterThanOrEqual(1);
  const again = (await a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: { topic: "x" }, p_model: "claude-haiku-5-5", p_key: key, p_input_hash: "h" })).data;
  expect(again).toMatchObject({ id: first.id, replay: true, output: "the sheet" });
});

test("a member reduces nothing", async () => {
  expect((await a.rpc("reduce_old_inputs", { p_before: new Date().toISOString(), p_limit: 1 })).error?.code).toBe("42501");
});
