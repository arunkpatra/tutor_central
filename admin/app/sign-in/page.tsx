import type { Metadata } from "next";
import { AuthFrame } from "@/components/Frame";
import { Field } from "@/components/parts";
import { SubmitButton } from "@/components/SubmitButton";
import { SIGN_IN } from "@/content/door";
import { PENDING } from "@/content/words";
import { sameSite } from "@/lib/gate";
import { signIn } from "./actions";

export const metadata: Metadata = { title: "Sign in" };

export default async function SignInPage({
  searchParams,
}: {
  searchParams: Promise<{ failed?: string; next?: string }>;
}) {
  const { failed, next } = await searchParams;
  return (
    <AuthFrame>
      <div className="pageTitle">
        <div className="eyebrow">{SIGN_IN.eyebrow}</div>
        <h1 className="t1">{SIGN_IN.title}</h1>
        <p className="lead">{SIGN_IN.lead}</p>
      </div>
      <form action={signIn} className="auth">
        <input type="hidden" name="next" value={sameSite(next) ?? ""} />
        <Field
          label={SIGN_IN.email}
          name="email"
          type="email"
          placeholder={SIGN_IN.emailHint}
          autoComplete="username"
          required
        />
        <Field label={SIGN_IN.password} name="password" type="password" autoComplete="current-password" required />
        {failed ? <p className="fieldError">{SIGN_IN.failed}</p> : null}
        <SubmitButton kind="primary" big working={PENDING.signIn}>
          {SIGN_IN.button}
        </SubmitButton>
      </form>
      <p className="note">{SIGN_IN.note}</p>
    </AuthFrame>
  );
}
