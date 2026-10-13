import "server-only";
import { serviceClient } from "../supabase/service";
import type { Activity, Centre, Centres, Data, JobRow, Tutor } from "./types";

/** One `admin_*` function, as the platform (D83, D94). A database error is thrown: the page's error, never a guess. */
export async function rpc<T>(fn: string, args: { [key: string]: unknown } = {}): Promise<T> {
  const { data, error } = await serviceClient().rpc(fn, args);
  if (error) throw new Error(`${fn}: ${error.message}`);
  return data as T;
}

const notYet = (what: string) => (): never => {
  throw new Error(`${what} is not built yet`);
};

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
    openRecord: notYet("openRecord"),
    record: notYet("record"),
    cost: notYet("cost"),
    calls: notYet("calls"),
    call: notYet("call"),
    jobs: notYet("jobs"),
    job: notYet("job"),
    errors: notYet("errors"),
    alerts: notYet("alerts"),
    audit: notYet("audit"),
    acknowledge: notYet("acknowledge"),
    retry: notYet("retry"),
    cancel: notYet("cancel"),
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
    adminEmail: async (admin) => {
      const { data } = await serviceClient().from("admin_users").select("email").eq("user_id", admin).maybeSingle();
      return (data?.email as string | undefined) ?? null;
    },
  };
}
