import "server-only";
import { redirect } from "next/navigation";
import { preview } from "./env";
import { type Admin, type Decision, DOOR, decide } from "./gate";
import { sessionClient } from "./supabase/server";
import { serviceClient } from "./supabase/service";

const PREVIEW_ADMIN: Admin = { userId: "preview", email: "you@tutorcentral.in" };

/** What the gate says of this request: the session checked with Supabase's server (`getUser`), the assurance level,
 *  the verified TOTP factors, and the `admin_users` row read as the platform. */
export async function currentDecision(): Promise<Decision> {
  const session = await sessionClient();
  const { data: got } = await session.auth.getUser();
  const user = got.user;
  if (!user) return decide({ user: null, admin: null, verifiedFactors: 0, currentLevel: null });
  const [{ data: level }, { data: factors }, { data: row }] = await Promise.all([
    session.auth.mfa.getAuthenticatorAssuranceLevel(),
    session.auth.mfa.listFactors(),
    serviceClient().from("admin_users").select("user_id, email").eq("user_id", user.id).maybeSingle(),
  ]);
  return decide({
    user: { id: user.id, email: user.email ?? "" },
    admin: row ? { userId: row.user_id as string, email: row.email as string } : null,
    verifiedFactors: (factors?.totp ?? []).filter((f) => f.status === "verified").length,
    currentLevel: level?.currentLevel === "aal2" ? "aal2" : level?.currentLevel === "aal1" ? "aal1" : null,
  });
}

/** Every page but the door's calls this first: the admin, or a redirect to the door. `next` brings a verified admin
 *  back to the page asked for. In preview mode (D96) it answers a stand-in admin and reads nothing. */
export async function requireAdmin(next?: string): Promise<Admin> {
  if (preview()) return PREVIEW_ADMIN;
  const decision = await currentDecision();
  if (decision.to === "ok") return decision.admin;
  const door = DOOR[decision.to];
  redirect(decision.to === "verify" && next ? `${door}?next=${encodeURIComponent(next)}` : door);
}
