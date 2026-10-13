import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { AuthFrame } from "@/components/Frame";
import { Field } from "@/components/parts";
import { SubmitButton } from "@/components/SubmitButton";
import { VERIFY, WRONG_CODE } from "@/content/door";
import { PENDING } from "@/content/words";
import { currentDecision } from "@/lib/admin";
import { preview } from "@/lib/env";
import { DOOR, sameSite } from "@/lib/gate";
import { sessionClient } from "@/lib/supabase/server";
import frame from "@/preview/frame.json";
import { verify } from "./actions";

export const metadata: Metadata = { title: "Enter your code" };

/** Who is asking: only an admin at aal1 with a verified factor reaches the form. */
async function signedInAs(): Promise<string> {
  if (preview()) return frame.email;
  const decision = await currentDecision();
  if (decision.to !== "verify") redirect(decision.to === "ok" ? "/centres" : DOOR[decision.to]);
  const { data } = await (await sessionClient()).auth.getUser();
  return data.user?.email ?? "";
}

export default async function VerifyPage({
  searchParams,
}: {
  searchParams: Promise<{ failed?: string; next?: string }>;
}) {
  const { failed, next } = await searchParams;
  const email = await signedInAs();
  return (
    <AuthFrame>
      <div className="pageTitle">
        <div className="eyebrow">{VERIFY.eyebrow}</div>
        <h1 className="t1">{VERIFY.title}</h1>
        <p className="lead">{VERIFY.lead}</p>
      </div>
      <form action={verify} className="auth">
        <input type="hidden" name="next" value={sameSite(next) ?? ""} />
        <Field
          label={VERIFY.code}
          name="code"
          placeholder={VERIFY.codeHint}
          code
          autoComplete="one-time-code"
          required
          maxLength={6}
        />
        {failed ? <p className="fieldError">{WRONG_CODE}</p> : null}
        <SubmitButton kind="primary" big working={PENDING.verify}>
          {VERIFY.button}
        </SubmitButton>
      </form>
      <div className="signedAs">
        <span className="dim">{VERIFY.signedInAs(email)}</span>
        <form action="/sign-out" method="post">
          <button type="submit" className="linkButton">
            {VERIFY.signOut}
          </button>
        </form>
      </div>
    </AuthFrame>
  );
}
