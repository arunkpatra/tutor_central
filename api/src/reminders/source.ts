import { createClient } from "@supabase/supabase-js";
import type { Database } from "../generated/database.js";
import type { ReminderSource } from "../jobs/kinds/reminder-sweep.js";
import { addDays } from "../plan/dates.js";
import type { OutboxDb } from "../push/db.js";
import { settingsOf } from "./settings.js";

/** The reminder plan's reads through the service role (D83); every query names the job's centre. */
export function makeReminderSource(url: string, serviceKey: string, outbox: OutboxDb): ReminderSource {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const must = <T>(r: { data: T; error: { message: string } | null }, what: string): NonNullable<T> => {
    if (r.error || r.data === null || r.data === undefined) throw new Error(`${what}: ${r.error?.message ?? "nothing"}`);
    return r.data as NonNullable<T>;
  };
  return {
    async read(centre, today) {
      const month = `${today.slice(0, 7)}-01`;
      const since = new Date(Date.now() - 60 * 86_400_000).toISOString();
      const [classes, students, events, invoices, members, settings] = await Promise.all([
        client.from("classes").select("id, name, meeting_days, start_time, end_time").eq("centre_id", centre).is("archived_at", null),
        client.from("students").select("class_id").eq("centre_id", centre).is("archived_at", null),
        client.from("calendar_events").select("id, title, date, start_time, end_time, note").eq("centre_id", centre).gte("date", today).lte("date", addDays(today, 14)),
        client.from("fee_invoices").select("amount").eq("centre_id", centre).eq("period", month).eq("status", "due"),
        client.from("centre_members").select("user_id").eq("centre_id", centre),
        client.from("reminder_settings").select("user_id, class_on, class_minutes, events_on, event_lead, fees_on, fees_day, plan_ready_on, notes_ready_on").eq("centre_id", centre),
      ]);
      const ids = must(members, "centre_members").map((m) => m.user_id);
      const tokens = ids.length
        ? must(await client.from("device_tokens").select("user_id").in("user_id", ids).is("retired_at", null).gt("last_seen_at", since), "device_tokens")
        : [];
      const reachable = [...new Set(tokens.map((t) => t.user_id))];
      const counts: Record<string, number> = {};
      for (const s of must(students, "students")) if (s.class_id) counts[s.class_id] = (counts[s.class_id] ?? 0) + 1;
      const due = must(invoices, "fee_invoices");
      const rows = must(settings, "reminder_settings");
      return {
        today,
        classes: must(classes, "classes").map((c) => ({ id: c.id, name: c.name, days: c.meeting_days, start: c.start_time, end: c.end_time })),
        memberCounts: counts,
        events: must(events, "calendar_events").map((e) => ({ id: e.id, title: e.title, date: e.date, start: e.start_time, end: e.end_time, note: e.note })),
        dueFees: due.length ? { count: due.length, total: due.reduce((n, i) => n + i.amount, 0) } : null,
        users: reachable.map((user) => ({ user, settings: settingsOf(rows.find((r) => r.user_id === user) ?? null) })),
      };
    },
    replace: (centre, user, kinds, from, rows) => outbox.replace(centre, user, kinds, from, rows),
  };
}
