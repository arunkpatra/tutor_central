import "server-only";
import { data } from "./data";
import { callerIp } from "./request";

/** One audit row for this request (D77, D78): who, what, which centre, why, from where. */
export async function audit(
  admin: string,
  action: string,
  {
    centre = null,
    target = {},
    reason = null,
  }: { centre?: string | null; target?: { [key: string]: unknown }; reason?: string | null } = {},
): Promise<void> {
  await data().auditWrite(admin, action, centre, target, reason, await callerIp());
}
