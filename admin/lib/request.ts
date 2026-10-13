import "server-only";
import { headers } from "next/headers";

/** The caller's address for the audit: the first of Vercel's x-forwarded-for, else null. */
export async function callerIp(): Promise<string | null> {
  try {
    const forwarded = (await headers()).get("x-forwarded-for");
    return forwarded?.split(",")[0]?.trim() || null;
  } catch {
    // No request (a unit test calling an action): no address.
    return null;
  }
}
