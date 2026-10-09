import { SQL } from "bun";
import { beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { anonClient, type Local, local, userClient } from "./client";

let l: Local;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
const stamp = Date.now();

/** Every table the app owns; each must keep one centre's rows from every other user. */
const CENTRE_TABLES = [
  "classes",
  "students",
  "attendance_sessions",
  "attendance_marks",
  "fee_invoices",
  "calendar_events",
  "tasks",
  "ai_generations",
  "message_log",
] as const;

beforeAll(async () => {
  l = await local();
  a = await userClient(l, `rls-a-${stamp}@example.com`);
  b = await userClient(l, `rls-b-${stamp}@example.com`);
  const { data, error } = await a.rpc("create_centre", { p_name: "Centre A", p_whatsapp: "+919999999999" });
  if (error) throw error;
  centreA = data as string;
});

test("every public table has row-level security and at least one policy", async () => {
  const db = new SQL(l.db);
  const rows = await db`
    select t.tablename, t.rowsecurity, count(p.policyname)::int as policies
    from pg_tables t left join pg_policies p on p.schemaname = t.schemaname and p.tablename = t.tablename
    where t.schemaname = 'public' group by t.tablename, t.rowsecurity order by t.tablename`;
  await db.close();
  const tables = rows.map((r: { tablename: string }) => r.tablename);
  expect(tables).toEqual([...CENTRE_TABLES, "centre_members", "centres", "profiles"].sort());
  for (const r of rows) expect({ table: r.tablename, rls: r.rowsecurity, policy: r.policies > 0 }).toEqual({ table: r.tablename, rls: true, policy: true });
});

test("a new member sees nothing until they create a centre", async () => {
  const { data, error } = await b.from("centres").select("id");
  expect(error).toBeNull();
  expect(data).toEqual([]);
});

test("the creator can read their centre, their owner membership and their profile", async () => {
  const { data } = await a.from("centres").select("id, name, whatsapp_number").eq("id", centreA);
  expect(data).toEqual([{ id: centreA, name: "Centre A", whatsapp_number: "+919999999999" }]);
  const m = await a.from("centre_members").select("role").eq("centre_id", centreA);
  expect(m.data).toEqual([{ role: "owner" }]);
  const p = await a.from("profiles").select("user_id");
  expect(p.data?.length).toBe(1);
  expect((await b.from("profiles").select("user_id")).data).toEqual([]);
});

test("anonymous cannot create a centre", async () => {
  const r = await anonClient(l).rpc("create_centre", { p_name: "Nobody" });
  expect(r.error).not.toBeNull();
});

test("rows of one centre are invisible to another user and to anonymous, in every table", async () => {
  const student = await a.from("students").insert({ centre_id: centreA, name: "Only A", parent_phone: "+919000000001" }).select("id").single();
  expect(student.error).toBeNull();
  const session = await a.from("attendance_sessions").insert({ centre_id: centreA, date: "2026-10-05" }).select("id").single();
  expect(session.error).toBeNull();
  const inserts: Record<(typeof CENTRE_TABLES)[number], Record<string, unknown> | null> = {
    classes: { name: "Class A" },
    students: null,
    attendance_sessions: null,
    attendance_marks: { session_id: session.data!.id, student_id: student.data!.id, status: "present" },
    fee_invoices: { student_id: student.data!.id, period: "2026-09-01", amount: 1000 },
    calendar_events: { title: "Parents meeting", date: "2026-10-10" },
    tasks: { title: "Buy chalk" },
    ai_generations: { kind: "homework", input: { topic: "Fractions" } },
    message_log: { student_id: student.data!.id, kind: "reminder" },
  };
  for (const [table, row] of Object.entries(inserts)) {
    if (row) expect((await a.from(table).insert({ centre_id: centreA, ...row })).error).toBeNull();
  }
  for (const table of CENTRE_TABLES) {
    expect({ table, rows: (await a.from(table).select("id")).data?.length }).toEqual({ table, rows: 1 });
    expect({ table, rows: (await b.from(table).select("id")).data }).toEqual({ table, rows: [] });
    expect({ table, rows: (await anonClient(l).from(table).select("id")).data ?? [] }).toEqual({ table, rows: [] });
  }
});

test("another user cannot insert into, update or delete from a centre they do not belong to", async () => {
  expect((await b.from("students").insert({ centre_id: centreA, name: "Intruder" })).error).not.toBeNull();
  const upd = await b.from("students").update({ name: "Renamed" }).eq("centre_id", centreA).select("id");
  expect(upd.data).toEqual([]);
  const del = await b.from("students").delete().eq("centre_id", centreA).select("id");
  expect(del.data).toEqual([]);
  expect((await b.from("centres").update({ name: "Taken" }).eq("id", centreA).select("id")).data).toEqual([]);
  expect((await a.from("students").select("name").eq("name", "Only A")).data?.length).toBe(1);
});

test("a user cannot add themselves to someone else's centre", async () => {
  const { data: who } = await b.auth.getUser();
  const r = await b.from("centre_members").insert({ centre_id: centreA, user_id: who.user!.id, role: "owner" });
  expect(r.error).not.toBeNull();
});

test("a row cannot point at another centre's student, class or session", async () => {
  const { data: centreB, error } = await b.rpc("create_centre", { p_name: "Centre B" });
  expect(error).toBeNull();
  const theirs = await b.from("students").insert({ centre_id: centreB, name: "B's student" }).select("id").single();
  const theirClass = await b.from("classes").insert({ centre_id: centreB, name: "B's class" }).select("id").single();
  const theirSession = await b.from("attendance_sessions").insert({ centre_id: centreB, date: "2026-10-05" }).select("id").single();
  const mine = await a.from("students").select("id").eq("name", "Only A").single();
  const mySession = await a.from("attendance_sessions").select("id").eq("centre_id", centreA).single();
  expect((await a.from("fee_invoices").insert({ centre_id: centreA, student_id: theirs.data!.id, period: "2026-08-01", amount: 1 })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centreA, name: "Mixed", class_id: theirClass.data!.id })).error).not.toBeNull();
  expect((await a.from("attendance_marks").insert({ centre_id: centreA, session_id: theirSession.data!.id, student_id: mine.data!.id, status: "absent" })).error).not.toBeNull();
  expect((await a.from("attendance_marks").insert({ centre_id: centreA, session_id: mySession.data!.id, student_id: theirs.data!.id, status: "absent" })).error).not.toBeNull();
  expect((await a.from("message_log").insert({ centre_id: centreA, student_id: theirs.data!.id, kind: "reminder" })).error).not.toBeNull();
});

test("one attendance session per class and day, and one for all students per day", async () => {
  const again = await a.from("attendance_sessions").insert({ centre_id: centreA, date: "2026-10-05" });
  expect(again.error).not.toBeNull();
});

test("generate_fees inserts only the missing invoices, never for archived students, and is idempotent", async () => {
  const ins = await a.from("students").insert([
    { centre_id: centreA, name: "Two", monthly_fee: 500 },
    { centre_id: centreA, name: "Gone", monthly_fee: 500, archived_at: new Date().toISOString() },
  ]);
  expect(ins.error).toBeNull();
  const first = await a.rpc("generate_fees", { p_centre: centreA, p_period: "2026-10-01" });
  expect(first.error).toBeNull();
  expect(first.data).toBe(2); // "Only A" (no fee anywhere: 0) and "Two"; never "Gone"
  const amounts = await a.from("fee_invoices").select("amount, students(name)").eq("period", "2026-10-01").order("amount");
  expect(amounts.data?.map((r) => r.amount)).toEqual([0, 500]);
  const second = await a.rpc("generate_fees", { p_centre: centreA, p_period: "2026-10-01" });
  expect(second.data).toBe(0);
  const bad = await a.rpc("generate_fees", { p_centre: centreA, p_period: "2026-10-15" });
  expect(bad.error?.message).toContain("first of a month");
  const notMember = await b.rpc("generate_fees", { p_centre: centreA, p_period: "2026-11-01" });
  expect(notMember.error).not.toBeNull();
});

test("a paid invoice needs paid_at", async () => {
  const inv = await a.from("fee_invoices").select("id").eq("centre_id", centreA).eq("period", "2026-10-01").limit(1).single();
  const r = await a.from("fee_invoices").update({ status: "paid" }).eq("id", inv.data!.id);
  expect(r.error).not.toBeNull();
  const ok = await a.from("fee_invoices").update({ status: "paid", paid_at: new Date().toISOString(), paid_method: "upi" }).eq("id", inv.data!.id);
  expect(ok.error).toBeNull();
});

test("updated_at moves on update", async () => {
  const before = await a.from("tasks").select("id, updated_at").eq("centre_id", centreA).single();
  await Bun.sleep(20);
  const after = await a.from("tasks").update({ done_at: new Date().toISOString() }).eq("id", before.data!.id).select("updated_at").single();
  expect(new Date(after.data!.updated_at).getTime()).toBeGreaterThan(new Date(before.data!.updated_at).getTime());
});

test("archive_class detaches members and is refused to a non-member", async () => {
  const cls = await a.from("classes").insert({ centre_id: centreA, name: "To archive", monthly_fee: 900 }).select("id").single();
  expect(cls.error).toBeNull();
  const kept = await a.from("students").insert({ centre_id: centreA, name: "Keeps own fee", class_id: cls.data!.id, monthly_fee: 700 }).select("id").single();
  const plain = await a.from("students").insert({ centre_id: centreA, name: "On class fee", class_id: cls.data!.id }).select("id").single();
  expect((await b.rpc("archive_class", { p_class: cls.data!.id })).error).not.toBeNull();
  expect((await a.rpc("archive_class", { p_class: cls.data!.id })).error).toBeNull();
  const after = await a.from("classes").select("archived_at").eq("id", cls.data!.id).single();
  expect(after.data!.archived_at).not.toBeNull();
  const members = await a.from("students").select("name, class_id, monthly_fee, archived_at").in("id", [kept.data!.id, plain.data!.id]).order("name");
  expect(members.data).toEqual([
    { name: "Keeps own fee", class_id: null, monthly_fee: 700, archived_at: null },
    { name: "On class fee", class_id: null, monthly_fee: null, archived_at: null },
  ]);
  expect((await a.rpc("archive_class", { p_class: cls.data!.id })).error).toBeNull(); // idempotent
});

test("deleting a student cascades to invoices and marks and detaches message_log", async () => {
  const s = await a.from("students").insert({ centre_id: centreA, name: "Leaving", monthly_fee: 500 }).select("id").single();
  const session = await a.from("attendance_sessions").insert({ centre_id: centreA, date: "2026-10-06" }).select("id").single();
  expect((await a.from("fee_invoices").insert({ centre_id: centreA, student_id: s.data!.id, period: "2026-07-01", amount: 500 })).error).toBeNull();
  expect((await a.from("attendance_marks").insert({ centre_id: centreA, session_id: session.data!.id, student_id: s.data!.id, status: "present" })).error).toBeNull();
  const log = await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "reminder" }).select("id").single();
  expect((await a.from("students").delete().eq("id", s.data!.id)).error).toBeNull();
  expect((await a.from("fee_invoices").select("id").eq("student_id", s.data!.id)).data).toEqual([]);
  expect((await a.from("attendance_marks").select("id").eq("student_id", s.data!.id)).data).toEqual([]);
  expect((await a.from("message_log").select("student_id").eq("id", log.data!.id)).data).toEqual([{ student_id: null }]);
  expect((await a.from("attendance_sessions").select("id").eq("id", session.data!.id)).data?.length).toBe(1);
});

test("save_attendance makes the session and replaces its marks", async () => {
  const s1 = await a.from("students").insert({ centre_id: centreA, name: "Mark One" }).select("id").single();
  const s2 = await a.from("students").insert({ centre_id: centreA, name: "Mark Two" }).select("id").single();
  const cls = await a.from("classes").insert({ centre_id: centreA, name: "Marked class" }).select("id").single();
  const first = await a.rpc("save_attendance", {
    p_centre: centreA, p_class: cls.data!.id, p_date: "2026-10-07",
    p_marks: { [s1.data!.id]: "present", [s2.data!.id]: "absent" },
  });
  expect(first.error).toBeNull();
  const marks = await a.from("attendance_marks").select("student_id, status").eq("session_id", first.data as string).order("status");
  // An enum orders as declared: present, then absent.
  expect(marks.data).toEqual([{ student_id: s1.data!.id, status: "present" }, { student_id: s2.data!.id, status: "absent" }]);
  // Saving again replaces: Two is now present and One is no longer in the class.
  const second = await a.rpc("save_attendance", { p_centre: centreA, p_class: cls.data!.id, p_date: "2026-10-07", p_marks: { [s2.data!.id]: "present" } });
  expect(second.data).toBe(first.data);
  const after = await a.from("attendance_marks").select("student_id, status").eq("session_id", first.data as string);
  expect(after.data).toEqual([{ student_id: s2.data!.id, status: "present" }]);
  const session = await a.from("attendance_sessions").select("saved_at, created_at").eq("id", first.data as string).single();
  expect(new Date(session.data!.saved_at).getTime()).toBeGreaterThan(new Date(session.data!.created_at).getTime());
});

test("save_attendance keeps all-students and a class apart on one day", async () => {
  const s = await a.from("students").select("id").eq("name", "Mark One").single();
  const everyone = await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-07", p_marks: { [s.data!.id]: "absent" } });
  expect(everyone.error).toBeNull();
  const sessions = await a.from("attendance_sessions").select("class_id").eq("centre_id", centreA).eq("date", "2026-10-07");
  expect(sessions.data?.length).toBe(2);
  const again = await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-07", p_marks: {} });
  expect(again.data).toBe(everyone.data);
  expect((await a.from("attendance_marks").select("id").eq("session_id", everyone.data as string)).data).toEqual([]);
});

test("save_attendance refuses a non-member, another centre's student and a bad mark", async () => {
  const s = await a.from("students").select("id").eq("name", "Mark One").single();
  expect((await b.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-08", p_marks: { [s.data!.id]: "present" } })).error).not.toBeNull();
  const theirs = await b.from("students").select("id").eq("name", "B's student").single();
  expect((await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-08", p_marks: { [theirs.data!.id]: "present" } })).error).not.toBeNull();
  expect((await a.rpc("save_attendance", { p_centre: centreA, p_class: null, p_date: "2026-10-08", p_marks: { [s.data!.id]: "late" } })).error).not.toBeNull();
  // A refused save leaves no session.
  expect((await a.from("attendance_sessions").select("id").eq("centre_id", centreA).eq("date", "2026-10-08")).data).toEqual([]);
});

test("an absence can be logged and read back by student and day", async () => {
  const s = await a.from("students").select("id").eq("name", "Mark One").single();
  const log = await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "absence" }).select("id, opened_at, channel").single();
  expect(log.error).toBeNull();
  expect(log.data!.channel).toBe("whatsapp_link");
  const read = await a.from("message_log").select("student_id, kind, opened_at").eq("centre_id", centreA).eq("kind", "absence").gte("opened_at", "2026-01-01");
  expect(read.data?.length).toBe(1);
});

test("an absence log carries the day the child was absent", async () => {
  const s = await a.from("students").select("id").eq("name", "Mark One").single();
  const log = await a.from("message_log")
    .insert({ centre_id: centreA, student_id: s.data!.id, kind: "absence", about_date: "2026-10-05" })
    .select("about_date").single();
  expect(log.error).toBeNull();
  expect(log.data!.about_date).toBe("2026-10-05");
  const read = await a.from("message_log").select("student_id").eq("centre_id", centreA).eq("about_date", "2026-10-05");
  expect(read.data?.length).toBe(1);
});

test("mark paid, undo and waive are plain updates the checks allow", async () => {
  const inv = await a.from("fee_invoices").select("id").eq("centre_id", centreA).eq("period", "2026-10-01").order("amount").limit(1).single();
  const paid = await a.from("fee_invoices").update({ status: "paid", paid_at: "2026-10-07T07:30:00+00:00", paid_method: "cash", waived_reason: null })
    .eq("id", inv.data!.id).select("status, paid_at, paid_method, waived_reason").single();
  expect(paid.error).toBeNull();
  expect(paid.data).toEqual({ status: "paid", paid_at: "2026-10-07T07:30:00+00:00", paid_method: "cash", waived_reason: null });
  // Undo: back to due, nothing paid.
  const undone = await a.from("fee_invoices").update({ status: "due", paid_at: null, paid_method: null }).eq("id", inv.data!.id).select("status, paid_at, paid_method").single();
  expect(undone.data).toEqual({ status: "due", paid_at: null, paid_method: null });
  // Waive keeps paid_at null; a waived fee marked paid later clears the reason.
  const waived = await a.from("fee_invoices").update({ status: "waived", waived_reason: "Joined mid-month" }).eq("id", inv.data!.id).select("status, paid_at, waived_reason").single();
  expect(waived.data).toEqual({ status: "waived", paid_at: null, waived_reason: "Joined mid-month" });
  expect((await a.from("fee_invoices").update({ status: "due", paid_at: "2026-10-07T07:30:00+00:00" }).eq("id", inv.data!.id)).error).not.toBeNull(); // due with paid_at is refused
  const back = await a.from("fee_invoices").update({ status: "due", waived_reason: null }).eq("id", inv.data!.id).select("status, waived_reason").single();
  expect(back.data).toEqual({ status: "due", waived_reason: null });
  expect((await b.from("fee_invoices").update({ status: "paid", paid_at: "2026-10-07T07:30:00+00:00" }).eq("id", inv.data!.id).select("id")).data).toEqual([]);
});

test("a reminder and a receipt are logged about a month and read back by it", async () => {
  const s = await a.from("students").select("id").eq("name", "Only A").single();
  const reminder = await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "reminder", about_date: "2026-10-01" }).select("kind, about_date, channel").single();
  expect(reminder.data).toEqual({ kind: "reminder", about_date: "2026-10-01", channel: "whatsapp_link" });
  expect((await a.from("message_log").insert({ centre_id: centreA, student_id: s.data!.id, kind: "receipt", about_date: "2026-10-01" })).error).toBeNull();
  const october = await a.from("message_log").select("kind").eq("centre_id", centreA).in("kind", ["reminder", "receipt"]).eq("about_date", "2026-10-01").order("kind");
  expect(october.data).toEqual([{ kind: "reminder" }, { kind: "receipt" }]); // enum order: reminder, receipt
  const september = await a.from("message_log").select("kind").eq("centre_id", centreA).in("kind", ["reminder", "receipt"]).eq("about_date", "2026-09-01");
  expect(september.data).toEqual([]);
});

test("the centre's payment settings are the owner's to change", async () => {
  const set = await a.from("centres").update({ upi_id: "meera@okhdfcbank", payment_link: "https://pay.example/meera", send_receipts: false, upi_confirmed_at: null })
    .eq("id", centreA).select("upi_id, payment_link, send_receipts, upi_confirmed_at").single();
  expect(set.data).toEqual({ upi_id: "meera@okhdfcbank", payment_link: "https://pay.example/meera", send_receipts: false, upi_confirmed_at: null });
  expect((await a.from("centres").update({ upi_id: "not an id" }).eq("id", centreA)).error).not.toBeNull();
  const confirmed = await a.from("centres").update({ upi_confirmed_at: "2026-10-07T07:35:00+00:00" }).eq("id", centreA).select("upi_confirmed_at").single();
  expect(confirmed.data!.upi_confirmed_at).toBe("2026-10-07T07:35:00+00:00");
  expect((await b.from("centres").update({ upi_id: "thief@bank" }).eq("id", centreA).select("id")).data).toEqual([]);
});

test("generate_fees for a second month skips nothing and counts what it made", async () => {
  const active = await a.from("students").select("id").eq("centre_id", centreA).is("archived_at", null);
  const made = await a.rpc("generate_fees", { p_centre: centreA, p_period: "2026-11-01" });
  expect(made.error).toBeNull();
  expect(made.data).toBe(active.data!.length);
  expect((await a.rpc("generate_fees", { p_centre: centreA, p_period: "2026-11-01" })).data).toBe(0);
});

test("start_ai_generation records a pending call for a member and refuses a non-member", async () => {
  const r = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: { topic: "Fractions" }, p_model: "claude-sonnet-5-5" });
  expect(r.error).toBeNull();
  const row = await a.from("ai_generations").select("kind, status, input, model, output").eq("id", r.data as string).single();
  expect(row.data).toEqual({ kind: "paper", status: "pending", input: { topic: "Fractions" }, model: "claude-sonnet-5-5", output: null });
  const theirs = await b.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
  expect(theirs.error?.message).toContain("ai_not_a_member");
  // The member finishes the row with a plain update; the other user cannot see it.
  const done = await a
    .from("ai_generations")
    .update({ status: "ok", output: "{}", tokens_in: 10, tokens_out: 20 })
    .eq("id", r.data as string)
    .select("status, tokens_in")
    .single();
  expect(done.data).toEqual({ status: "ok", tokens_in: 10 });
  expect((await b.from("ai_generations").select("id").eq("id", r.data as string)).data).toEqual([]);
});

test("start_ai_generation refuses a scan without consent and allows a paper", async () => {
  await a.from("centres").update({ ai_consent_at: null }).eq("id", centreA);
  for (const kind of ["scan_register", "check_paper", "progress_note"]) {
    const r = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: kind, p_input: {}, p_model: "m" });
    expect(r.error?.message).toContain("ai_consent_missing");
  }
  expect((await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "homework", p_input: {}, p_model: "m" })).error).toBeNull();
  await a.from("centres").update({ ai_consent_at: new Date().toISOString() }).eq("id", centreA);
  expect((await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "scan_register", p_input: {}, p_model: "m" })).error).toBeNull();
});

test("the limit counts only calls that did not fail, per kind group, over 24 hours", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.ai_generations where centre_id = ${centreA}`;
    // 40 generations in the last day (two of them failed, which do not count), and one older than a day.
    await sql`insert into public.ai_generations (centre_id, kind, input, status, created_at)
      select ${centreA}::uuid, 'worksheet', '{}', 'ok', now() - interval '1 hour' from generate_series(1, 38)`;
    await sql`insert into public.ai_generations (centre_id, kind, input, status)
      values (${centreA}, 'paper', '{}', 'failed'), (${centreA}, 'paper', '{}', 'failed')`;
    await sql`insert into public.ai_generations (centre_id, kind, input, status, created_at)
      values (${centreA}, 'paper', '{}', 'ok', now() - interval '25 hours')`;
    const thirtyNinth = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "progress_note", p_input: {}, p_model: "m" });
    expect(thirtyNinth.error).toBeNull();
    const fortieth = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
    expect(fortieth.error).toBeNull();
    const fortyFirst = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
    expect(fortyFirst.error?.message).toContain("ai_limit_reached");
    expect(fortyFirst.error?.details).toBe("40");
    // Scans have their own count of 20, untouched by the generations.
    expect((await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "scan_register", p_input: {}, p_model: "m" })).error).toBeNull();
    await sql`insert into public.ai_generations (centre_id, kind, input, status)
      select ${centreA}::uuid, 'check_paper', '{}', 'ok' from generate_series(1, 20)`;
    const check = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "check_paper", p_input: {}, p_model: "m" });
    expect(check.error?.details).toBe("20");
  } finally {
    await sql`delete from public.ai_generations where centre_id = ${centreA}`;
    await sql.close();
  }
});

test("a member cannot delete, backdate or re-kind a call, and failed calls meet a hard cap", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.ai_generations where centre_id = ${centreA}`;
    const r = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
    const id = r.data as string;
    expect((await a.from("ai_generations").delete().eq("id", id)).error).not.toBeNull();
    expect((await a.from("ai_generations").update({ created_at: "2020-01-01T00:00:00Z" }).eq("id", id)).error).not.toBeNull();
    expect((await a.from("ai_generations").update({ kind: "scan_register" }).eq("id", id)).error).not.toBeNull();
    expect((await a.from("ai_generations").update({ status: "failed" }).eq("id", id)).error).toBeNull();
    // 59 more marked failed: 60 started in the day, none counted by the soft rule, and the hard cap refuses the 61st.
    await sql`insert into public.ai_generations (centre_id, kind, input, status)
      select ${centreA}::uuid, 'homework', '{}', 'failed' from generate_series(1, 59)`;
    const capped = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" });
    expect(capped.error?.message).toContain("ai_limit_reached");
    expect(capped.error?.details).toBe("40");
  } finally {
    await sql`delete from public.ai_generations where centre_id = ${centreA}`;
    await sql.close();
  }
});

test("a refused start leaves no row", async () => {
  const before = (await a.from("ai_generations").select("id").eq("centre_id", centreA)).data?.length ?? 0;
  await a.from("centres").update({ ai_consent_at: null }).eq("id", centreA);
  await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "check_paper", p_input: {}, p_model: "m" });
  expect((await a.from("ai_generations").select("id").eq("centre_id", centreA)).data?.length).toBe(before);
});

test("ai_status has pending and anonymous cannot start a generation", async () => {
  const sql = new SQL(l.db);
  const values = await sql`select enumlabel from pg_enum where enumtypid = 'public.ai_status'::regtype order by enumsortorder`;
  expect([...values].map((v) => v.enumlabel)).toEqual(["ok", "failed", "pending"]);
  await sql.close();
  const anon = anonClient(l);
  expect((await anon.rpc("start_ai_generation", { p_centre: centreA, p_kind: "paper", p_input: {}, p_model: "m" })).error).not.toBeNull();
});

test("only the owner can delete the centre, and it cascades", async () => {
  expect((await b.rpc("delete_centre", { p_centre: centreA })).error).not.toBeNull();
  expect((await a.rpc("delete_centre", { p_centre: centreA })).error).toBeNull();
  for (const table of [...CENTRE_TABLES, "centres", "centre_members"]) {
    expect({ table, rows: (await a.from(table).select("*")).data }).toEqual({ table, rows: [] });
  }
});

test("delete_account removes the user, their centre and every row the cascade reaches; another user is untouched", async () => {
  const c = await userClient(l, `rls-del-${stamp}@example.com`);
  const d = await userClient(l, `rls-keep-${stamp}@example.com`);
  const centreC = (await c.rpc("create_centre", { p_name: "Centre C", p_whatsapp: null })).data as string;
  const centreD = (await d.rpc("create_centre", { p_name: "Centre D", p_whatsapp: null })).data as string;
  await c.from("students").insert({ centre_id: centreC, name: "Gone Soon" });
  await d.from("students").insert({ centre_id: centreD, name: "Stays" });
  const userC = (await c.auth.getUser()).data.user?.id as string;
  expect((await c.rpc("delete_account")).error).toBeNull();
  const sql = new SQL(l.db);
  try {
    const users = await sql`select count(*)::int as n from auth.users where id = ${userC}`;
    expect(users[0].n).toBe(0);
    const identities = await sql`select count(*)::int as n from auth.identities where user_id = ${userC}`;
    expect(identities[0].n).toBe(0);
    for (const table of [...CENTRE_TABLES, "centre_members"]) {
      const rows = await sql`select count(*)::int as n from public.${sql(table)} where centre_id = ${centreC}`;
      expect({ table, n: rows[0].n }).toEqual({ table, n: 0 });
    }
    expect((await sql`select count(*)::int as n from public.centres where id = ${centreC}`)[0].n).toBe(0);
    expect((await sql`select count(*)::int as n from public.profiles where user_id = ${userC}`)[0].n).toBe(0);
  } finally {
    await sql.close();
  }
  expect((await d.from("students").select("name").eq("centre_id", centreD)).data).toEqual([{ name: "Stays" }]);
});

test("anonymous cannot call delete_account", async () => {
  expect((await anonClient(l).rpc("delete_account")).error).not.toBeNull();
});

test("create_centre writes the tutor's name on their profile", async () => {
  const c = await userClient(l, `rls-c-${stamp}@example.com`);
  const { data: centreC, error } = await c.rpc("create_centre", {
    p_name: "Centre C",
    p_whatsapp: null,
    p_display_name: "Meera Nair",
  });
  expect(error).toBeNull();
  const { data: profile } = await c.from("profiles").select("display_name").single();
  expect(profile?.display_name).toBe("Meera Nair");
  const { data: centre } = await c
    .from("centres")
    .select("name, whatsapp_number")
    .eq("id", centreC as string)
    .single();
  expect(centre).toEqual({ name: "Centre C", whatsapp_number: null });
});

test("create_centre refuses a malformed WhatsApp number in words the app can match", async () => {
  const d = await userClient(l, `rls-d-${stamp}@example.com`);
  const { error } = await d.rpc("create_centre", { p_name: "Centre D", p_whatsapp: "98765 43210" });
  expect(error?.code).toBe("23514"); // check_violation: the app validates first (PhoneNumber); this is the floor
});

test("anonymous gets no grant on a table or function made after migration 0001", async () => {
  const sql = new SQL(l.db);
  await sql`create table public.zz_probe (id int)`;
  await sql`create function public.zz_probe_fn() returns int language sql as 'select 1'`;
  try {
    const grants = await sql`select grantee, privilege_type from information_schema.role_table_grants
      where table_name = 'zz_probe' and grantee = 'anon'`;
    expect([...grants]).toEqual([]);
    const fn = await sql`select grantee from information_schema.role_routine_grants
      where routine_name = 'zz_probe_fn' and grantee in ('anon', 'PUBLIC')`;
    expect([...fn]).toEqual([]);
  } finally {
    await sql`drop function public.zz_probe_fn()`;
    await sql`drop table public.zz_probe`;
    await sql.close();
  }
});
