"use server";

import { notFound, redirect } from "next/navigation";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import { preview } from "@/lib/env";
import { idOf } from "@/lib/ids";
import { callerIp } from "@/lib/request";

/** Back to the list the form came from (a `/jobs` path only), the job open and what happened. */
function back(form: FormData, job: string, done: "retried" | "cancelled" | "refused"): string {
  const from = String(form.get("back") ?? "");
  const url = new URL(from.startsWith("/jobs") && !from.startsWith("//") ? from : "/jobs", "http://portal.local");
  url.searchParams.delete("done");
  url.searchParams.set("open", job);
  url.searchParams.set("done", done);
  return `/jobs${url.search}`;
}

/** Retry a failed job from its failed step (0046's admin_retry_job writes the audit row). */
export async function retryJob(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const job = idOf(String(form.get("job") ?? ""), preview());
  if (!job) notFound();
  const ok = await data().retry(admin.userId, job, await callerIp());
  redirect(back(form, job, ok ? "retried" : "refused"));
}

/** Cancel a queued, waiting or running job (0046's admin_cancel_job writes the audit row). */
export async function cancelJob(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const job = idOf(String(form.get("job") ?? ""), preview());
  if (!job) notFound();
  const ok = await data().cancel(admin.userId, job, await callerIp());
  redirect(back(form, job, ok ? "cancelled" : "refused"));
}
