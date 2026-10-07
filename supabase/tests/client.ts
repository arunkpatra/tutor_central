import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { sh } from "../../tools/lib/sh";

export type Local = { url: string; anon: string; service: string; db: string };

/** The running local stack's addresses and keys, from `supabase status -o env`. */
export async function local(): Promise<Local> {
  const r = await sh(["supabase", "status", "-o", "env"], { cwd: `${import.meta.dir}/..` });
  if (r.code !== 0) throw new Error("local supabase is not running: supabase start");
  const get = (k: string) => {
    const v = r.stdout.match(new RegExp(`^${k}="?([^"\\n]+)"?$`, "m"))?.[1];
    if (!v) throw new Error(`supabase status has no ${k}`);
    return v;
  };
  return { url: get("API_URL"), anon: get("ANON_KEY"), service: get("SERVICE_ROLE_KEY"), db: get("DB_URL") };
}

const options = { auth: { persistSession: false, autoRefreshToken: false } };

/** A signed-in client for a fresh confirmed user with this email. */
export async function userClient(l: Local, email: string): Promise<SupabaseClient> {
  const admin = createClient(l.url, l.service, options);
  const password = "rls-test-password-1";
  const { error: createError } = await admin.auth.admin.createUser({ email, password, email_confirm: true });
  if (createError) throw createError;
  const c = createClient(l.url, l.anon, options);
  const { error } = await c.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return c;
}

export function anonClient(l: Local): SupabaseClient {
  return createClient(l.url, l.anon, options);
}
