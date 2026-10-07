import { createClient } from "@supabase/supabase-js";
import type { Hono } from "hono";
import type { Vars } from "./auth.js";
import { makeApp } from "./make-app.js";
import { env } from "./env.js";

/** Read at start: a deployment without them fails to boot, so /health and the deploy's smoke fail, instead of every
 *  tutor being told to sign in again. */
const supabaseUrl = env("SUPABASE_URL");
const supabaseAnonKey = env("SUPABASE_ANON_KEY");

/** Verifies a Supabase access token by asking Supabase for its user. One call per request; a JWKS cache is a later
 *  optimisation. */
const verify = async (token: string) => {
  const client = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser(token);
  return error || !data.user ? null : { id: data.user.id };
};

/** Vercel's Hono preset and `bun --hot` both serve this default export. The preset takes as its entry the first of
 *  app, index, server, src/app, src/index, src/server that imports "hono": this file (test/entry.test.ts). */
const app: Hono<Vars> = makeApp({ verify, commit: process.env.TC_COMMIT });
export default app;
