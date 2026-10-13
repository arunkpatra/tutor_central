import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { AuthFrame } from "@/components/Frame";
import { REFUSED } from "@/content/door";
import { currentDecision } from "@/lib/admin";
import { preview } from "@/lib/env";
import { DOOR } from "@/lib/gate";
import frame from "@/preview/frame.json";

export const metadata: Metadata = { title: "Not an admin" };

/** A signed-in account not on the admin list: named, nothing read (the sign-in wrote the attempt to the audit). */
async function refusedEmail(): Promise<string> {
  if (preview()) return frame.refused;
  const decision = await currentDecision();
  if (decision.to !== "refused") redirect(decision.to === "ok" ? "/centres" : DOOR[decision.to]);
  return decision.email;
}

export default async function RefusedPage() {
  const email = await refusedEmail();
  return (
    <AuthFrame>
      <div className="pageTitle">
        <div className="eyebrow refused">{REFUSED.eyebrow}</div>
        <h1 className="t1">{REFUSED.title}</h1>
        <p className="lead">{REFUSED.lead(email)}</p>
      </div>
      <form action="/sign-out" method="post">
        <button type="submit" className="btn secondary big">
          {REFUSED.signOut}
        </button>
      </form>
      <p className="note">{REFUSED.note}</p>
    </AuthFrame>
  );
}
