import "server-only";
import { serviceClient } from "../supabase/service";
import type {
  Activity,
  Alerts,
  AuditRow,
  Call,
  Calls,
  Centre,
  Centres,
  Cost,
  Data,
  Errors,
  Job,
  JobRow,
  Jobs,
  Model,
  Models,
  Record,
  Tutor,
} from "./types";

/** One `admin_*` function, as the platform (D83, D94). A database error is thrown: the page's error, never a guess. */
export async function rpc<T>(fn: string, args: { [key: string]: unknown } = {}): Promise<T> {
  const { data, error } = await serviceClient().rpc(fn, args);
  if (error) throw new Error(`${fn}: ${error.message}`);
  return data as T;
}

/** The tutors' emails and sign-in times from the Auth admin API: SQL cannot read auth.users as the platform. */
async function withEmails(tutors: Tutor[]): Promise<Tutor[]> {
  const auth = serviceClient().auth.admin;
  return Promise.all(
    tutors.map(async (t) => {
      const { data } = await auth.getUserById(t.user_id);
      return {
        ...t,
        email: data.user?.email ?? null,
        last_sign_in: t.last_sign_in ?? data.user?.last_sign_in_at ?? null,
      };
    }),
  );
}

/** The real `Data`: each method one function call. Filled page by page (plan Tasks 5 to 12). */
export function realData(): Data {
  return {
    centres: (month) => rpc<Centres>("admin_centres", { p_month: month }),
    centre: async (id, month) => {
      const c = await rpc<Centre | null>("admin_centre", { p_centre: id, p_month: month });
      return c ? { ...c, tutors: await withEmails(c.tutors) } : null;
    },
    activity: (id, limit) => rpc<Activity[]>("admin_activity", { p_centre: id, p_limit: limit }),
    centreJobs: (id, limit) => rpc<JobRow[]>("admin_centre_jobs", { p_centre: id, p_limit: limit }),
    openRecord: (admin, centre, reason, ip) =>
      rpc<Record | null>("admin_open_record", { p_admin: admin, p_centre: centre, p_reason: reason, p_ip: ip }),
    record: (audit, admin) => rpc<Record | null>("admin_record_opened", { p_audit: audit, p_admin: admin }),
    cost: async (month, centre) => {
      const [tiles, byDay, byCentre, byStep, byMonth] = await Promise.all([
        rpc<Cost["tiles"]>("admin_cost_tiles", { p_month: month }),
        rpc<Cost["byDay"]>("admin_cost_by_day", { p_month: month, p_centre: centre }),
        rpc<Cost["byCentre"]>("admin_cost_by_centre", { p_month: month }),
        rpc<Cost["byStep"]>("admin_cost_by_step", { p_month: month, p_centre: centre }),
        rpc<Cost["byMonth"]>("admin_cost_by_month", { p_centre: centre }),
      ]);
      return { tiles, byDay, byCentre, byStep, byMonth };
    },
    calls: (f) =>
      rpc<Calls>("admin_calls", { p_day: f.day, p_centre: f.centre, p_kind: f.kind, p_status: f.status, p_limit: 200 }),
    call: (id) => rpc<Call | null>("admin_call", { p_id: id }),
    jobs: (f) =>
      rpc<Jobs>("admin_jobs", { p_day: f.day, p_state: f.state, p_kind: f.kind, p_centre: f.centre, p_limit: 200 }),
    job: (id) => rpc<Job | null>("admin_job", { p_id: id }),
    errors: async (hours, limit) => {
      const [byRoute, recent] = await Promise.all([
        rpc<Omit<Errors, "recent">>("admin_errors_by_route", { p_hours: hours }),
        rpc<Errors["recent"]>("admin_errors_recent", { p_limit: limit }),
      ]);
      return { ...byRoute, recent };
    },
    alerts: (openFirst) => rpc<Alerts>("admin_alerts", { p_open_first: openFirst }),
    audit: (f) =>
      rpc<AuditRow[]>("admin_audit", { p_days: f.days, p_admin: f.admin, p_action: f.action, p_limit: 300 }),
    acknowledge: (admin, alert, ip) =>
      rpc<boolean>("admin_acknowledge_alert", { p_admin: admin, p_alert: alert, p_ip: ip }),
    retry: (admin, job, ip) => rpc<boolean>("admin_retry_job", { p_admin: admin, p_job: job, p_ip: ip }),
    cancel: (admin, job, ip) => rpc<boolean>("admin_cancel_job", { p_admin: admin, p_job: job, p_ip: ip }),
    auditWrite: async (admin, action, centre, target, reason, ip) => {
      await rpc("admin_audit_write", {
        p_admin: admin,
        p_action: action,
        p_centre: centre,
        p_target: target,
        p_reason: reason,
        p_ip: ip,
      });
    },
    models: () => rpc<Models>("admin_models"),
    model: (kind) => rpc<Model | null>("admin_model", { p_kind: kind }),
    setModel: (admin, c, ip) =>
      rpc<string>("admin_set_model", {
        p_admin: admin,
        p_kind: c.kind,
        p_step: c.step,
        p_model: c.model,
        p_effort: c.effort,
        p_fallback: c.fallback,
        p_enabled: c.enabled,
        p_note: c.note,
        p_ip: ip,
      }),
    setAllowance: (admin, centre, calls, paise, reason, ip) =>
      rpc<boolean>("admin_set_allowance", {
        p_admin: admin,
        p_centre: centre,
        p_calls: calls,
        p_paise: paise,
        p_reason: reason,
        p_ip: ip,
      }),
    setLines: async (admin, l, ip) => {
      await rpc("admin_set_alert_lines", {
        p_admin: admin,
        p_cost_day_paise: l.cost_day_paise,
        p_error_rate_pct: l.error_rate_pct,
        p_error_rate_min_requests: l.error_rate_min_requests,
        p_stuck_minutes: l.stuck_minutes,
        p_ip: ip,
      });
    },
    adminEmail: async (admin) => {
      const { data } = await serviceClient().from("admin_users").select("email").eq("user_id", admin).maybeSingle();
      return (data?.email as string | undefined) ?? null;
    },
  };
}
