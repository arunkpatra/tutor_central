/** A required environment variable; a missing one is a deployment mistake, said plainly. */
export function env(name: "SUPABASE_URL" | "SUPABASE_ANON_KEY" | "ANTHROPIC_API_KEY"): string {
  const v = process.env[name];
  if (!v) throw new Error(`${name} is not set`);
  return v;
}
