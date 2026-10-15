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

/** A number of 0 or more as typed: whole, or with a decimal where `decimal`. Null for anything else. */
function amount(form: FormData, name: string, decimal = false): number | null {
  const raw = String(form.get(name) ?? "").trim();
  if (!(decimal ? /^\d+(\.\d+)?$/ : /^\d+$/).test(raw)) return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

/** Save the lines (D113): a new `alert_lines` row from now; the cost line is typed in rupees and kept in paise. */
export async function saveLines(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const cost = amount(form, "cost_day", true);
  const rate = amount(form, "error_rate", true);
  const min = amount(form, "error_min");
  const stuck = amount(form, "stuck");
  if (cost === null || rate === null || rate > 100 || min === null || stuck === null) redirect("/alerts?bad=lines");
  await data().setLines(
    admin.userId,
    {
      cost_day_paise: Math.round(cost * 100),
      error_rate_pct: rate,
      error_rate_min_requests: min,
      stuck_minutes: stuck,
    },
    await callerIp(),
  );
  redirect("/alerts");
}
