import "server-only";
import { headers } from "next/headers";

/** The caller's address for the audit: the first of Vercel's x-forwarded-for, else null. */
export async function callerIp(): Promise<string | null> {
  const forwarded = (await headers()).get("x-forwarded-for");
  return forwarded?.split(",")[0]?.trim() || null;
}
