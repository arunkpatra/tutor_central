import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 22 (D113, migration 0066): the portal's controls. A model change and the alert lines are new rows, the allowance an
// update of the centre's columns; each writes its audit row; a member calls none of them. An internal centre is not an
// active one.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let centreB: string;
let userB: string;
let adminId: string;
let adminEmail: string;
const stamp = Date.now();
const india = (d: Date) => new Date(d.getTime() + 5.5 * 3600_000).toISOString().slice(0, 10);
const month = `${india(new Date()).slice(0, 8)}01`;

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `controls-a-${stamp}@example.com`);
  b = await userClient(l, `controls-b-${stamp}@example.com`);
  userB = (await b.auth.getUser()).data.user!.id;
  centreA = (await a.rpc("create_centre", { p_name: "Controls A", p_whatsapp: "+919999999999" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Controls B", p_whatsapp: "+919999999998" })).data as string;
  adminEmail = `controls-admin-${stamp}@example.com`;
  const admin = await userClient(l, adminEmail);
  adminId = (await admin.auth.getUser()).data.user!.id;
  await sql`insert into public.admin_users (user_id, email) values (${adminId}, ${adminEmail})`;
});
afterAll(async () => {
  // Both tables are append-only even for the platform: the rows this file wrote go by the database's owner, so the other
  // files see the seed.
  await sql`delete from public.ai_models where set_by = ${adminEmail}`;
  await sql`delete from public.alert_lines where set_by = ${adminEmail}`;
  await sql.close();
});

const setModel = (args: Record<string, unknown>) =>
  svc.rpc("admin_set_model", { p_admin: adminId, p_step: "draft", p_model: "claude-sonnet-5-5", p_effort: "medium", p_fallback: "claude-haiku-5-5", p_enabled: true, p_note: null, p_ip: null, ...args });

test("a model change is a new row with the admin's name, the newest row is current, and the audit names it", async () => {
  const { data, error } = await setModel({ p_kind: "brief", p_effort: "high", p_note: "high effort: the slips were shallow", p_ip: "127.0.0.1" });
  expect(error).toBeNull();
  expect(data as string).toMatch(/^[0-9a-f-]{36}$/);
  const current = (await svc.rpc("ai_models_current")).data as { kind: string; step: string; effort: string }[];
  expect(current.find((r) => r.kind === "brief" && r.step === "draft")?.effort).toBe("high");
  const rows = await svc.from("ai_models").select("set_by, note").eq("kind", "brief").eq("step", "draft").order("since", { ascending: false });
  expect(rows.data?.[0]).toEqual({ set_by: adminEmail, note: "high effort: the slips were shallow" });
  const audit = await svc.from("admin_audit").select("action, target, reason, ip").eq("admin_user_id", adminId).order("created_at", { ascending: false }).limit(1).single();
  expect(audit.data).toMatchObject({ action: "set_model", target: { kind: "brief", step: "draft", effort: "high", enabled: true }, reason: "high effort: the slips were shallow", ip: "127.0.0.1" });
  const model = (await svc.rpc("admin_model", { p_kind: "brief" })).data as { current: { step: string; effort: string; set_by: string }[]; history: { note: string | null }[] };
  expect(model.current.map((c) => c.step)).toEqual(["draft", "check", "repair"]);
  expect(model.current[0]).toMatchObject({ effort: "high", set_by: adminEmail });
  expect(model.history[0]?.note).toBe("high effort: the slips were shallow");
  expect(model.history.length).toBe(4);
});

test("switching a kind off is a disabled draft row; the reads say so; switching on is another row", async () => {
  const before = ((await svc.rpc("admin_models")).data as { tiles: { off: number } }).tiles.off;
  await setModel({ p_kind: "mock", p_effort: "high", p_enabled: false, p_note: "a wrong marks total in two mocks" });
  const current = (await svc.rpc("ai_models_current")).data as { kind: string; step: string; enabled: boolean }[];
  expect(current.find((r) => r.kind === "mock" && r.step === "draft")?.enabled).toBe(false);
  type Models = { tiles: { kinds: number; off: number; changes_month: number; last_change: string | null }; rows: { kind: string; draft: { enabled: boolean }; changed_by: string; note: string }[] };
  const models = (await svc.rpc("admin_models")).data as Models;
  expect(models.tiles.off).toBe(before + 1);
  expect(models.tiles.kinds).toBeGreaterThanOrEqual(22);
  expect(models.tiles.changes_month).toBeGreaterThanOrEqual(2);
  expect(models.tiles.last_change).not.toBeNull();
  expect(models.rows.find((r) => r.kind === "mock")).toMatchObject({ draft: { enabled: false }, changed_by: adminEmail, note: "a wrong marks total in two mocks" });
  await setModel({ p_kind: "mock", p_effort: "high", p_enabled: true, p_note: "switched on" });
  expect(((await svc.rpc("admin_models")).data as Models).tiles.off).toBe(before);
});

test("a kind with no row is refused, and so is a step or an effort the table does not know; a kind never held reads null", async () => {
  expect((await setModel({ p_kind: "nonsense" })).error?.message).toContain("unknown_kind");
  expect((await setModel({ p_kind: "brief", p_step: "grade" })).error).not.toBeNull();
  expect((await setModel({ p_kind: "brief", p_effort: "max" })).error).not.toBeNull();
  expect((await svc.rpc("admin_model", { p_kind: "nonsense" })).data).toBeNull();
});

test("the lines: the seed is the code's constants, a new row is current, the alerts read carries it", async () => {
  const seed = (await svc.rpc("alert_lines_current")).data as { cost_day_paise: number; error_rate_pct: number; error_rate_min_requests: number; stuck_minutes: number; set_by: string }[];
  expect(seed[0]).toMatchObject({ cost_day_paise: 6000, error_rate_pct: 5, error_rate_min_requests: 20, stuck_minutes: 10, set_by: "seed 0066" });
  const id = (await svc.rpc("admin_set_alert_lines", { p_admin: adminId, p_cost_day_paise: 9000, p_error_rate_pct: 4.5, p_error_rate_min_requests: 30, p_stuck_minutes: 15, p_ip: null })).data;
  expect(id).toMatch(/^[0-9a-f-]{36}$/);
  expect(((await svc.rpc("alert_lines_current")).data as { cost_day_paise: number }[])[0]?.cost_day_paise).toBe(9000);
  const alerts = (await svc.rpc("admin_alerts", { p_open_first: true })).data as { lines: { stuck_minutes: number; error_rate_pct: number; set_by: string } };
  expect(alerts.lines).toMatchObject({ stuck_minutes: 15, error_rate_pct: 4.5, set_by: adminEmail });
  const audit = await svc.from("admin_audit").select("action, target").eq("admin_user_id", adminId).eq("action", "set_alert_lines").single();
  expect(audit.data?.target).toEqual({ cost_day_paise: 9000, error_rate_pct: 4.5, error_rate_min_requests: 30, stuck_minutes: 15 });
  expect((await svc.rpc("admin_set_alert_lines", { p_admin: adminId, p_cost_day_paise: -1, p_error_rate_pct: 5, p_error_rate_min_requests: 20, p_stuck_minutes: 10, p_ip: null })).error).not.toBeNull();
});

test("the stuck line's minutes decide which running jobs the facts name", async () => {
  // The lines above say 15 minutes: a job with no step for 12 is not stuck, one for 20 is.
  const [{ id: twelve }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, started_at)
    values (${centreA}, 'plan', ${`stuck-12-${stamp}`}, 'running', now() - interval '12 minutes') returning id`;
  const [{ id: twenty }] = await sql`insert into public.jobs (centre_id, kind, idempotency_key, state, started_at)
    values (${centreA}, 'plan', ${`stuck-20-${stamp}`}, 'running', now() - interval '20 minutes') returning id`;
  const facts = (await svc.rpc("alert_facts", { p_now: new Date().toISOString() })).data as { stuck_jobs: { id: string }[] };
  const ids = facts.stuck_jobs.map((j) => j.id);
  expect(ids).toContain(twenty);
  expect(ids).not.toContain(twelve);
  await sql`delete from public.jobs where id in (${twelve}, ${twenty})`;
});

test("the allowance: the next call meets the new allowance, the audit keeps the old values, no reason is refused", async () => {
  const set = (calls: number, reason: string) => svc.rpc("admin_set_allowance", { p_admin: adminId, p_centre: centreA, p_calls: calls, p_paise: 0, p_reason: reason, p_ip: null });
  expect((await set(1, "  ")).error?.message).toContain("reason_required");
  expect((await set(1, "a test")).data).toBe(true);
  expect((await svc.rpc("admin_set_allowance", { p_admin: adminId, p_centre: crypto.randomUUID(), p_calls: 1, p_paise: 0, p_reason: "gone", p_ip: null })).data).toBe(false);
  const call = (key: string) => a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: {}, p_model: "claude-haiku-5-5", p_key: key, p_input_hash: key });
  expect((await call(`allow-1-${stamp}`)).error).toBeNull();
  expect((await call(`allow-2-${stamp}`)).error?.message).toContain("ai_limit_reached");
  const audit = await svc.from("admin_audit").select("centre_id, target, reason").eq("action", "set_allowance").eq("admin_user_id", adminId).order("created_at", { ascending: false }).limit(1).single();
  expect(audit.data).toEqual({ centre_id: centreA, target: { calls: 1, paise: 0, before: { calls: 600, paise: 0 } }, reason: "a test" });
  // A member still cannot change it.
  await a.from("centres").update({ ai_allowance: 900 }).eq("id", centreA);
  expect((await svc.from("centres").select("ai_allowance").eq("id", centreA).single()).data?.ai_allowance).toBe(1);
  expect((await svc.rpc("admin_set_allowance", { p_admin: adminId, p_centre: centreA, p_calls: -5, p_paise: 0, p_reason: "x", p_ip: null })).error).not.toBeNull();
});

test("an internal centre is not an active centre, and a member cannot mark one", async () => {
  await b.from("events").insert({ centre_id: centreB, kind: "app_opened", at: new Date().toISOString() });
  const active = async () => ((await svc.rpc("admin_centres", { p_month: month })).data as { tiles: { active_week: number } }).tiles.active_week;
  const counted = await active();
  await b.from("centres").update({ internal: true }).eq("id", centreB);
  expect((await svc.from("centres").select("internal").eq("id", centreB).single()).data?.internal).toBe(false);
  await svc.from("centres").update({ internal: true }).eq("id", centreB);
  expect(await active()).toBe(counted - 1);
  await svc.from("centres").update({ internal: false }).eq("id", centreB);
  expect(userB).toBeTruthy();
});

test("a member calls none of the writers or the reads", async () => {
  const calls: [string, Record<string, unknown>][] = [
    ["admin_set_model", { p_admin: adminId, p_kind: "brief", p_step: "draft", p_model: "x", p_effort: "low", p_fallback: null, p_enabled: true, p_note: null, p_ip: null }],
    ["admin_set_alert_lines", { p_admin: adminId, p_cost_day_paise: 1, p_error_rate_pct: 1, p_error_rate_min_requests: 1, p_stuck_minutes: 1, p_ip: null }],
    ["admin_set_allowance", { p_admin: adminId, p_centre: centreA, p_calls: 900, p_paise: 0, p_reason: "x", p_ip: null }],
    ["admin_models", {}],
    ["admin_model", { p_kind: "brief" }],
    ["alert_lines_current", {}],
  ];
  for (const [fn, args] of calls) expect({ fn, code: (await a.rpc(fn, args)).error?.code }).toEqual({ fn, code: "42501" });
  expect((await a.from("alert_lines").select("id")).data ?? []).toEqual([]);
});
