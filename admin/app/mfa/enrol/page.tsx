import type { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { AuthFrame } from "@/components/Frame";
import { Button, Field } from "@/components/parts";
import { ENROL, WRONG_CODE } from "@/content/door";
import { currentDecision } from "@/lib/admin";
import { preview } from "@/lib/env";
import { DOOR } from "@/lib/gate";
import { sessionClient } from "@/lib/supabase/server";
import frame from "@/preview/frame.json";
import { enrol } from "./actions";
import { ENROLLING, type Enrolling, readEnrolling } from "./enrolling";

export const metadata: Metadata = { title: "Set up your authenticator" };

/** The key in groups of four, as the board writes it. */
function grouped(secret: string): string {
  return secret.match(/.{1,4}/g)?.join(" ") ?? secret;
}

/** A new factor with its square, or (after a wrong code) the same factor again: the phone has the square already. */
async function factor(failed: boolean): Promise<(Enrolling & { qr: string | null }) | null> {
  if (preview()) return { factorId: "preview", secret: frame.secret, qr: frame.qr };
  const decision = await currentDecision();
  if (decision.to !== "enrol") redirect(decision.to === "ok" ? "/centres" : DOOR[decision.to]);
  const session = await sessionClient();
  const { data: factors } = await session.auth.mfa.listFactors();
  const unverified = (factors?.all ?? []).filter((f) => f.factor_type === "totp" && f.status === "unverified");
  const kept = failed ? readEnrolling((await cookies()).get(ENROLLING)?.value) : null;
  if (kept && unverified.some((f) => f.id === kept.factorId)) return { ...kept, qr: null };
  // An abandoned attempt's factor is removed first, so the account holds one square at a time.
  for (const f of unverified) await session.auth.mfa.unenroll({ factorId: f.id });
  const { data, error } = await session.auth.mfa.enroll({
    factorType: "totp",
    friendlyName: ENROL.issuer,
    issuer: ENROL.issuer,
  });
  if (error || !data) return null;
  return { factorId: data.id, secret: data.totp.secret, qr: data.totp.qr_code };
}

export default async function EnrolPage({ searchParams }: { searchParams: Promise<{ failed?: string }> }) {
  const failed = Boolean((await searchParams).failed);
  const f = await factor(failed);
  return (
    <AuthFrame>
      <div className="pageTitle">
        <div className="eyebrow">{ENROL.eyebrow}</div>
        <h1 className="t1">{ENROL.title}</h1>
        {f?.qr ? <p className="lead">{ENROL.lead}</p> : null}
      </div>
      {f ? (
        <>
          <div className="qrRow">
            {/* biome-ignore lint/performance/noImgElement: Supabase's square is a data URL; next/image adds nothing to it. */}
            {f.qr ? <img className="qr" src={f.qr} alt={ENROL.squareAlt} width={168} height={168} /> : null}
            <div className="qrKey">
              <div className="note">{ENROL.key}</div>
              <div className="secret">{grouped(f.secret)}</div>
            </div>
          </div>
          <form action={enrol} className="auth">
            <input type="hidden" name="factor" value={f.factorId} />
            <input type="hidden" name="secret" value={f.secret} />
            <Field
              label={ENROL.code}
              name="code"
              placeholder={ENROL.codeHint}
              code
              autoComplete="one-time-code"
              required
              maxLength={6}
            />
            {failed ? <p className="fieldError">{WRONG_CODE}</p> : null}
            <Button kind="primary" big>
              {ENROL.button}
            </Button>
          </form>
          {f.qr ? null : (
            <a className="linkButton" href="/mfa/enrol">
              {ENROL.again}
            </a>
          )}
        </>
      ) : null}
      <p className="note">{ENROL.note}</p>
    </AuthFrame>
  );
}
