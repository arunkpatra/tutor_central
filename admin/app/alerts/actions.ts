"use server";

import { notFound, redirect } from "next/navigation";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import { preview } from "@/lib/env";
import { idOf } from "@/lib/ids";
import { callerIp } from "@/lib/request";

/** Acknowledge an open alert (0046's admin_acknowledge_alert writes the audit row); one already acknowledged stays. */
export async function acknowledge(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const alert = idOf(String(form.get("alert") ?? ""), preview());
  if (!alert) notFound();
  await data().acknowledge(admin.userId, alert, await callerIp());
  redirect(form.get("show") === "newest" ? "/alerts?show=newest" : "/alerts");
}
