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
  if (decision.to === "enrol") {
    const { data } = await session.auth.getUser();
    if (data.user) await audit(data.user.id, "sign_in", { reason: AUDITED.firstSignIn });
  }
  redirect(afterSignIn(decision, next));
}
