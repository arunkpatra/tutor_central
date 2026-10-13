import "server-only";
import { serviceClient } from "../supabase/service";
import type { Data } from "./types";

/** One `admin_*` function, as the platform (D83, D94). A database error is thrown: the page's error, never a guess. */
export async function rpc<T>(fn: string, args: { [key: string]: unknown } = {}): Promise<T> {
  const { data, error } = await serviceClient().rpc(fn, args);
  if (error) throw new Error(`${fn}: ${error.message}`);
  return data as T;
}

const notYet = (what: string) => (): never => {
  throw new Error(`${what} is not built yet`);
};

/** The real `Data`: each method one function call. Filled page by page (plan Tasks 5 to 12). */
export function realData(): Data {
  return {
    centres: notYet("centres"),
    centre: notYet("centre"),
    activity: notYet("activity"),
    centreJobs: notYet("centreJobs"),
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
