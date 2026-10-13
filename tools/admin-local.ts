#!/usr/bin/env bun
/** bun tools/admin-local.ts <email>: a local admin for the admin portal's hand runs (docs/runbooks/admin.md): an account
 *  made through the local stack's Auth admin API with a password printed once, on `admin_users`, pushing to the seed's
 *  tutor (meera@example.com) and centre. Test-only: it refuses any stack that is not on this Mac. */
import { createClient } from "@supabase/supabase-js";
import { sh } from "./lib/sh";

export function localOnly(url: string): string | null {
  const host = new URL(url).hostname;
  return host === "127.0.0.1" || host === "localhost" ? null : `admin-local makes test accounts on the local stack only, not ${url}`;
}

if (import.meta.main) {
  const email = process.argv[2];
  if (!email?.includes("@")) {
    console.error("usage: bun tools/admin-local.ts <email>");
    process.exit(2);
  }
  const status = await sh(["supabase", "status", "-o", "env"], { cwd: `${import.meta.dir}/../supabase` });
  const get = (k: string) => status.stdout.match(new RegExp(`^${k}="?([^"\\n]+)"?$`, "m"))?.[1] ?? "";
  const url = get("API_URL");
  const refused = url ? localOnly(url) : "local supabase is not running (cd supabase && supabase start)";
  if (refused) {
    console.error(refused);
    process.exit(1);
  }
  const db = createClient(url, get("SERVICE_ROLE_KEY"), { auth: { persistSession: false, autoRefreshToken: false } });
  const password = `local-admin-${crypto.randomUUID().slice(0, 8)}`;
  const made = await db.auth.admin.createUser({ email, password, email_confirm: true });
  if (made.error || !made.data.user) {
    console.error(`the account was not made: ${made.error?.message}`);
    process.exit(1);
  }
  const tutor = await db.auth.admin.listUsers();
  const meera = tutor.data.users.find((u) => u.email === "meera@example.com");
  const centre = meera ? (await db.from("centres").select("id").eq("owner_id", meera.id).maybeSingle()).data?.id : null;
  const row = await db.from("admin_users").insert({ user_id: made.data.user.id, email, notify_user_id: meera?.id ?? null, notify_centre_id: centre ?? null });
  if (row.error) {
    console.error(`the admin row was not written: ${row.error.message}`);
    process.exit(1);
  }
  console.log(`local admin ${email} made; password (shown once): ${password}`);
  console.log(meera ? "alert pushes go to the seed's tutor, meera@example.com" : "no seed tutor: alert pushes go nowhere");
}
