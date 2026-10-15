"use server";

import { cookies } from "next/headers";
import { notFound, redirect } from "next/navigation";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import { preview } from "@/lib/env";
import { idOf } from "@/lib/ids";
import { callerIp } from "@/lib/request";
import { reasonOf, recordCookie } from "./reason";

/** Open a centre's record (D78): the audit row and the record in one call; the page reads it by the row's id. */
export async function openRecord(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const id = idOf(String(form.get("centre") ?? ""), preview());
  if (!id) notFound();
  const reason = reasonOf(form);
  if (!reason) redirect(`/centres/${id}?ask=1&empty=1`);
  const record = await data().openRecord(admin.userId, id, reason, await callerIp());
  if (!record) notFound();
  (await cookies()).set(recordCookie(id), record.audit_id, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: `/centres/${id}/record`,
    maxAge: 600,
  });
  redirect(`/centres/${id}/record`);
}

/** A whole number of 0 or more as typed, else null. */
function whole(form: FormData, name: string): number | null {
  const raw = String(form.get(name) ?? "").trim();
  return /^\d{1,7}$/.test(raw) ? Number(raw) : null;
}

/** Change a centre's allowance (D113): calls a month and a cap in rupees (kept in paise; 0 is none), with a reason; the
 *  audit row keeps the old values. */
export async function setAllowance(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const id = idOf(String(form.get("centre") ?? ""), preview());
  if (!id) notFound();
  const reason = reasonOf(form);
  if (!reason) redirect(`/centres/${id}?allowance=1&empty=1`);
  const calls = whole(form, "calls");
  const cap = whole(form, "cap");
  if (calls === null || cap === null) redirect(`/centres/${id}?allowance=1&bad=1`);
  // No calls at all would refuse every draft; a centre is stopped by switching a kind off, not here.
  if (calls < 1) redirect(`/centres/${id}?allowance=1&bad=calls`);
  if (!(await data().setAllowance(admin.userId, id, calls, cap * 100, reason, await callerIp()))) notFound();
  redirect(`/centres/${id}`);
}
