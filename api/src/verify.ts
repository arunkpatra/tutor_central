import type { Verify } from "./auth.js";

/** The part of a Supabase client the verifier asks. */
type AuthClient = {
  auth: {
    getUser(
      token: string,
    ): Promise<{ data: { user: { id: string } | null }; error: { status?: number; message: string; name?: string } | null }>;
  };
};

/** Verifies a Supabase access token by asking Supabase for its user (one call per request). A 4xx is the token's fault
 *  (expired, malformed, a deleted user): null, so the app is told to sign in again. A failure to reach Supabase (a thrown
 *  fetch, a 5xx, a timeout or rate limit, a proxy's page that supabase-js marks retryable, an error with no status) is
 *  "unreachable", so a good token is never told to sign in again (D68). */
export function makeVerify(client: () => AuthClient): Verify {
  return async (token) => {
    try {
      const { data, error } = await client().auth.getUser(token);
      if (error) return isTokensFault(error) ? null : "unreachable";
      return data.user ? { id: data.user.id } : null;
    } catch {
      return "unreachable";
    }
  };
}

/** A 4xx about the token itself; never a timeout (408), a rate limit (429) or a retryable fetch failure. */
function isTokensFault(error: { status?: number; name?: string }): boolean {
  const { status } = error;
  if (status === undefined || status < 400 || status >= 500 || status === 408 || status === 429) return false;
  return error.name !== "AuthRetryableFetchError";
}
