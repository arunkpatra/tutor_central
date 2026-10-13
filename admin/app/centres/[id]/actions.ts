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
