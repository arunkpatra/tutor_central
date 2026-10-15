"use server";

import { redirect } from "next/navigation";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import { callerIp } from "@/lib/request";
import { chosenKinds } from "./kinds";

/** Run golden sets now (D112, D116): one eval_run job for the chosen kinds with a golden set (none chosen: every kind),
 *  audited; busy while a run is queued or under way. */
export async function runEvals(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const kinds = chosenKinds(String(form.get("kinds") ?? ""));
  const job = await data().runEvals(admin.userId, kinds.length > 0 ? kinds : null, await callerIp());
  redirect(job ? `/evals?queued=${job}` : "/evals?queued=busy");
}
