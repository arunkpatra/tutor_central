/** The admin portal's door (D94), as a pure function: who is asking, whether they are on `admin_users`, how many
 *  verified second factors they have and the session's assurance level. `requireAdmin` (lib/admin.ts) reads these and
 *  redirects by the answer. */
export type Admin = { userId: string; email: string };

export type Decision =
  | { to: "sign-in" }
  | { to: "refused"; email: string }
  | { to: "enrol" }
  | { to: "verify" }
  | { to: "ok"; admin: Admin };

export type GateInput = {
  user: { id: string; email: string } | null;
  admin: Admin | null;
  verifiedFactors: number;
  currentLevel: "aal1" | "aal2" | null;
};

export function decide({ user, admin, verifiedFactors, currentLevel }: GateInput): Decision {
  if (!user) return { to: "sign-in" };
  if (!admin) return { to: "refused", email: user.email };
  if (verifiedFactors === 0) return { to: "enrol" };
  if (currentLevel !== "aal2") return { to: "verify" };
  return { to: "ok", admin };
}

/** The page each decision but `ok` sends to. */
export const DOOR = { "sign-in": "/sign-in", refused: "/refused", enrol: "/mfa/enrol", verify: "/mfa/verify" } as const;

/** A `next` the verify page may return to: a path of this site, never another origin. */
export function sameSite(next: string | undefined | null): string | null {
  if (!next?.startsWith("/") || next.startsWith("//") || next.includes("\\")) return null;
  return next;
}
