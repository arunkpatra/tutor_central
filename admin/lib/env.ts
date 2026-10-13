/** The portal's three variables (D83, D94): Vercel's Production environment of `tutor-central-admin` and
 *  `admin/.env.local`. The service key is read by `lib/supabase/service.ts` alone. */
export type Variable = "SUPABASE_URL" | "SUPABASE_ANON_KEY" | "SUPABASE_SERVICE_ROLE_KEY";

export function env(name: Variable): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is not set`);
  return value;
}

/** The commit this build serves (`TC_COMMIT` from deploy-admin.yml); "local" on a machine. The smoke reads it. */
export function commit(): string {
  return process.env.TC_COMMIT?.trim() || "local";
}

/** Preview mode (D96): every page from the checked-in fixtures, without a session, for the pictures. Refused in
 *  production, where it would serve fixtures to anyone. */
export function preview(): boolean {
  const on = process.env.ADMIN_PREVIEW === "1";
  if (on && process.env.VERCEL_ENV === "production") throw new Error("ADMIN_PREVIEW is for local runs");
  return on;
}

/** Where the portal runs, for the footer and the pages' eyebrow. */
export function environment(): "production" | "preview" | "local" {
  if (preview()) return "preview";
  return process.env.VERCEL_ENV === "production" ? "production" : "local";
}
