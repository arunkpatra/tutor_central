import { createClient } from "@supabase/supabase-js";
import type { NotificationRow, OutboxDb } from "../push/db.js";
import { type Alert, DEFAULT_LINES, type Facts, type Lines } from "./lines.js";

/** What the alerts job reads and writes, through 0046's named functions as the platform (D83). */
export type AlertsSource = {
  facts(now: Date): Promise<Facts>;
  /** alert_lines_current (0066): the lines the portal set, or the seed's when the table answers no row. */
  lines(): Promise<Lines>;
  /** raise_alert: true for a new key, false for one raised before. */
  raise(alert: Alert): Promise<boolean>;
  /** admin_push_targets: the tutor accounts (and centres) whose iPhones get the alert pushes. */
  targets(): Promise<{ user: string; centre: string }[]>;
  /** The push rows, through the outbox's replace_notifications (cancelling nothing). */
  notify(centre: string, user: string, rows: NotificationRow[], now: Date): Promise<void>;
};

type RawLines = { cost_day_paise: number; error_rate_pct: number | string; error_rate_min_requests: number; stuck_minutes: number };

type RawFacts = {
  failed_jobs: { id: string; kind: string; centre_id: string | null; finished_at: string }[];
  cost_today: { centre_id: string; paise: number }[];
  requests_hour: { total: number; errors: number };
  stuck_jobs: { id: string; kind: string; centre_id: string | null; since: string }[];
};

export function makeAlertsDb(url: string, serviceKey: string, outbox: OutboxDb): AlertsSource {
  const db = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const check = (what: string, error: { message: string } | null) => {
    if (error) throw new Error(`the alerts could not ${what}: ${error.message}`);
  };
  return {
    async facts(now) {
      const { data, error } = await db.rpc("alert_facts", { p_now: now.toISOString() });
      check("read their facts", error);
      const raw = data as RawFacts;
      return {
        failedJobs: raw.failed_jobs.map((j) => ({ id: j.id, kind: j.kind, centreId: j.centre_id, finishedAt: new Date(j.finished_at).toISOString() })),
        costToday: raw.cost_today.map((c) => ({ centreId: c.centre_id, paise: Number(c.paise) })),
        requestsHour: { total: Number(raw.requests_hour.total), errors: Number(raw.requests_hour.errors) },
        stuckJobs: raw.stuck_jobs.map((j) => ({ id: j.id, kind: j.kind, centreId: j.centre_id, since: j.since })),
      };
    },
    async lines() {
      const { data, error } = await db.rpc("alert_lines_current");
      check("read their lines", error);
      const row = ((data ?? []) as RawLines[])[0];
      if (!row) return DEFAULT_LINES;
      return {
        costDayPaise: Number(row.cost_day_paise),
        errorRatePct: Number(row.error_rate_pct),
        errorRateMinRequests: Number(row.error_rate_min_requests),
        stuckMinutes: Number(row.stuck_minutes),
      };
    },
    async raise(alert) {
      const { data, error } = await db.rpc("raise_alert", {
        p_key: alert.key,
        p_kind: alert.kind,
        p_centre: alert.centreId as string,
        p_threshold: alert.threshold,
        p_value: alert.value,
        p_message: alert.message,
      });
      check("raise one", error);
      return data === true;
    },
    async targets() {
      const { data, error } = await db.rpc("admin_push_targets");
      check("read the push targets", error);
      return ((data ?? []) as { user_id: string; centre_id: string }[]).map((t) => ({ user: t.user_id, centre: t.centre_id }));
    },
    async notify(centre, user, rows, now) {
      await outbox.replace(centre, user, [], now.toISOString(), rows);
    },
  };
}

/** A source in memory for tests: the facts, targets and lines given; raise answers false for a key raised before. */
export function fakeAlertsSource(facts: Facts, targets: { user: string; centre: string }[], lines: Lines = DEFAULT_LINES) {
  const raised: Alert[] = [];
  const notified: { centre: string; user: string; rows: NotificationRow[] }[] = [];
  const source: AlertsSource & { raised: Alert[]; notified: typeof notified } = {
    raised,
    notified,
    async facts() {
      return facts;
    },
    async lines() {
      return lines;
    },
    async raise(alert) {
      if (raised.some((a) => a.key === alert.key)) return false;
      raised.push(alert);
      return true;
    },
    async targets() {
      return targets;
    },
    async notify(centre, user, rows) {
      notified.push({ centre, user, rows });
    },
  };
  return source;
}
