import { createClient } from "@supabase/supabase-js";
import type { Hono } from "hono";
import type { Vars } from "./auth.js";
import { anthropicClaude } from "./claude.js";
import { fakeClaude, localScript } from "./claude-fake.js";
import { makeDb } from "./db.js";
import { env } from "./env.js";
import { makeApp } from "./make-app.js";

/** Read at start: a deployment without them fails to boot, so /health and the deploy's smoke fail, instead of every
 *  tutor being told to sign in again. AI_FAKE=1 (local runs only, never in Vercel) answers from the fake, so a hand
 *  run costs nothing while the consent, the limit and the record still run against the database. */
const supabaseUrl = env("SUPABASE_URL");
const supabaseAnonKey = env("SUPABASE_ANON_KEY");
const claude = process.env.AI_FAKE === "1" ? fakeClaude(localScript) : anthropicClaude(env("ANTHROPIC_API_KEY"));

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
const app: Hono<Vars> = makeApp({
  verify,
  commit: process.env.TC_COMMIT,
  claude,
  db: makeDb(supabaseUrl, supabaseAnonKey),
});
export default app;
