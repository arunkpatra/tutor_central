import type { MiddlewareHandler } from "hono";

/** Who a Supabase access token belongs to; null when it is expired, malformed or for a deleted user; "unreachable" when
 *  Supabase could not be asked (src/verify.ts). */
export type Verify = (token: string) => Promise<{ id: string } | null | "unreachable">;
/** The user and their own token: every database call the routes make carries it, so row-level security applies. The
 *  request's id (src/request.ts), the centre a body names and the body's hash (routes/common.ts `parse`) ride along. */
export type Vars = { Variables: { userId: string; token: string; requestId: string; centreId?: string; bodyHash?: string } };

/** 401 in words for a token that is not a live user's; 503 in connection words when Supabase could not be asked (a
 *  thrown verifier included), so a lost connection never tells a signed-in tutor to sign in again (D68). Never 500. */
export function makeRequireUser(verify: Verify): MiddlewareHandler<Vars> {
  return async (c, next) => {
    const token = c.req.header("authorization")?.match(/^Bearer\s+(\S+)$/i)?.[1];
    if (!token) return c.json({ error: "sign in again" }, 401);
    const user = await verify(token).catch(() => "unreachable" as const);
    if (user === "unreachable") return c.json({ error: "Couldn't reach the service. Try again.", reason: "unreachable" }, 503);
    if (!user) return c.json({ error: "sign in again" }, 401);
    c.set("userId", user.id);
    c.set("token", token);
    await next();
  };
}
