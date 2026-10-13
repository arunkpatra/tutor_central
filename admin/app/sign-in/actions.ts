"use server";

import { redirect } from "next/navigation";
import { AUDITED } from "@/content/door";
import { currentDecision } from "@/lib/admin";
import { audit } from "@/lib/audit";
import { afterSignIn } from "@/lib/gate";
import { sessionClient } from "@/lib/supabase/server";

/** Email and password (D94), then the gate decides: the code, the set-up, or the refusal. */
export async function signIn(form: FormData): Promise<void> {
  const email = String(form.get("email") ?? "").trim();
  const password = String(form.get("password") ?? "");
  const session = await sessionClient();
  const { error } = await session.auth.signInWithPassword({ email, password });
  const next = String(form.get("next") ?? "") || null;
  if (error) redirect(`/sign-in?failed=1${next ? `&next=${encodeURIComponent(next)}` : ""}`);
  const decision = await currentDecision(session);
  // The door's two audited moments at a password sign-in: an admin's first, and a refusal (once here, not on each view
  // of the refusal page).
  const { data } = await session.auth.getUser();
  if (data.user && decision.to === "enrol") await audit(data.user.id, "sign_in", { reason: AUDITED.firstSignIn });
  if (data.user && decision.to === "refused")
    await audit(data.user.id, "refused", { target: { email: decision.email }, reason: AUDITED.refused });
  redirect(afterSignIn(decision, next));
}
