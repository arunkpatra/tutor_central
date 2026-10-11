import type { Verify } from "./auth.js";

/** The part of a Supabase client the verifier asks. */
type AuthClient = {
  auth: {
    getUser(token: string): Promise<{ data: { user: { id: string } | null }; error: { status?: number; message: string } | null }>;
  };
};

/** Verifies a Supabase access token by asking Supabase for its user (one call per request). A 4xx is the token's fault
 *  (expired, malformed, a deleted user): null, so the app is told to sign in again. A failure to reach Supabase (a thrown
 *  fetch, a 5xx, an error with no status) is "unreachable", so a good token is never told to sign in again (D68). */
export function makeVerify(client: () => AuthClient): Verify {
  return async (token) => {
    try {
      const { data, error } = await client().auth.getUser(token);
      if (error) return error.status !== undefined && error.status >= 400 && error.status < 500 ? null : "unreachable";
      return data.user ? { id: data.user.id } : null;
    } catch {
      return "unreachable";
    }
  };
}
