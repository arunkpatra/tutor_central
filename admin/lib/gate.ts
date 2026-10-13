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

/** A backslash, whitespace or a control character: none belongs in a path the door returns to. */
const unsafe = (ch: string) => ch === "\\" || /\s/.test(ch) || ch.charCodeAt(0) < 0x20 || ch.charCodeAt(0) === 0x7f;

/** A `next` the door may return to: a path of this site, never another origin. Browsers drop tabs and newlines from a
 *  URL ("/\t/evil" is "//evil"), so any whitespace or control character is refused, and the path must resolve on this
 *  site alone. */
export function sameSite(next: string | undefined | null): string | null {
  if (!next?.startsWith("/") || next.startsWith("//") || [...next].some(unsafe)) return null;
  const url = new URL(next, "https://portal.invalid");
  if (url.origin !== "https://portal.invalid") return null;
  // The normalised path is checked again: "/.//evil" resolves to "//evil".
  const path = `${url.pathname}${url.search}${url.hash}`;
  return path.startsWith("//") || path.startsWith("/\\") ? null : path;
}

/** Where the proxy sends a request with no session: Sign in, carrying the page asked for (the home page needs none). */
export function signInPath(pathname: string, search: string): string {
  const asked = `${pathname}${search}`;
  return asked === "/" ? "/sign-in" : `/sign-in?next=${encodeURIComponent(asked)}`;
}

/** Where a password sign-in goes: the code (carrying the page asked for), that page, or the door's other pages. */
export function afterSignIn(decision: Decision, next: string | null): string {
  const page = sameSite(next);
  if (decision.to === "ok") return page ?? "/centres";
  if (decision.to === "verify") return page ? `${DOOR.verify}?next=${encodeURIComponent(page)}` : DOOR.verify;
  return DOOR[decision.to];
}
