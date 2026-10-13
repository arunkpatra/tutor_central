"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { AUDITED } from "@/content/door";
import { currentDecision } from "@/lib/admin";
import { audit } from "@/lib/audit";
import { sessionClient } from "@/lib/supabase/server";
import { ENROLLING } from "./enrolling";

/** The first code proves the square was scanned; the factor is verified and the session is aal2. */
export async function enrol(form: FormData): Promise<void> {
  const decision = await currentDecision();
  if (decision.to !== "enrol") redirect("/mfa/enrol");
  const factorId = String(form.get("factor") ?? "");
  const secret = String(form.get("secret") ?? "");
  const code = String(form.get("code") ?? "").replace(/\s/g, "");
  const session = await sessionClient();
  const { error } = await session.auth.mfa.challengeAndVerify({ factorId, code });
  const store = await cookies();
  if (error) {
    store.set(ENROLLING, JSON.stringify({ factorId, secret }), {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/mfa",
      maxAge: 600,
    });
    redirect("/mfa/enrol?failed=1");
  }
  store.delete({ name: ENROLLING, path: "/mfa" });
  const { data } = await session.auth.getUser();
  if (data.user) await audit(data.user.id, "enrol_totp", { reason: AUDITED.enrolled });
  redirect("/centres");
}
