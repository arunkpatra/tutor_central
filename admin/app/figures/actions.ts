"use server";

import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import { callerIp } from "@/lib/request";

/** Send this week so far, now (D115): a weekly_report job through admin_send_report, audited; the job sends it. */
export async function sendReport(): Promise<void> {
  const admin = await requireAdmin();
  await data().sendReport(admin.userId, await callerIp());
  redirect("/figures?sent=1");
}
