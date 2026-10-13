/** A required environment variable; a missing one is a deployment mistake, said plainly. */
export function env(
  name:
    | "SUPABASE_URL"
    | "SUPABASE_ANON_KEY"
    | "SUPABASE_SERVICE_ROLE_KEY"
    | "WORKER_SECRET"
    | "ANTHROPIC_API_KEY"
    | "APPLE_TEAM_ID"
    | "APPLE_KEY_ID"
    | "APPLE_SIGNIN_KEY"
    | "APNS_KEY"
    | "APNS_KEY_ID"
    | "APNS_TEAM_ID"
    | "APNS_TOPIC"
    | "RESEND_API_KEY"
    | "ALERT_EMAIL"
    | "SMOKE_CENTRE_ID",
): string {
  const v = process.env[name];
  if (!v) throw new Error(`${name} is not set`);
  return v;
}
