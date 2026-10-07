import { createClient } from "@supabase/supabase-js";
import { makeApp } from "./app";
import { env } from "./env";

/** Verifies a Supabase access token by asking Supabase for its user. One call per request; a JWKS cache is a later
 *  optimisation. */
const verify = async (token: string) => {
  const client = createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser(token);
  return error || !data.user ? null : { id: data.user.id };
};

/** Vercel's Hono preset and `bun --hot` both serve this default export. */
export default makeApp({ verify });
