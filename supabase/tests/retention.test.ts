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
