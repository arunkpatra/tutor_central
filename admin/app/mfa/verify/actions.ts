"use server";

import { redirect } from "next/navigation";
import { AUDITED } from "@/content/door";
import { currentDecision } from "@/lib/admin";
import { audit } from "@/lib/audit";
import { sameSite } from "@/lib/gate";
import { sessionClient } from "@/lib/supabase/server";

/** The code at each sign-in (and when aal2 has lapsed): the verified factor challenged, then the page asked for. */
export async function verify(form: FormData): Promise<void> {
  const decision = await currentDecision();
  if (decision.to !== "verify") redirect(decision.to === "ok" ? "/centres" : "/sign-in");
  const next = sameSite(String(form.get("next") ?? ""));
  const code = String(form.get("code") ?? "").replace(/\s/g, "");
  const session = await sessionClient();
  const { data: factors } = await session.auth.mfa.listFactors();
  const factor = (factors?.totp ?? []).find((f) => f.status === "verified");
  const { error } = factor ? await session.auth.mfa.challengeAndVerify({ factorId: factor.id, code }) : { error: true };
  if (error) redirect(`/mfa/verify?failed=1${next ? `&next=${encodeURIComponent(next)}` : ""}`);
  const { data } = await session.auth.getUser();
  if (data.user) await audit(data.user.id, "sign_in", { reason: AUDITED.verified });
  redirect(next ?? "/centres");
}
