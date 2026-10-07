import type { MiddlewareHandler } from "hono";

/** Who a Supabase access token belongs to, or null when it is expired, malformed or for a deleted user. */
export type Verify = (token: string) => Promise<{ id: string } | null>;
export type Vars = { Variables: { userId: string } };

/** 401 in words for anything but a live user. Never 500: a failed verifier is a sign-in problem to the caller. */
export function makeRequireUser(verify: Verify): MiddlewareHandler<Vars> {
  return async (c, next) => {
    const token = c.req.header("authorization")?.match(/^Bearer\s+(\S+)$/i)?.[1];
    if (!token) return c.json({ error: "sign in again" }, 401);
    const user = await verify(token).catch(() => null);
    if (!user) return c.json({ error: "sign in again" }, 401);
    c.set("userId", user.id);
    await next();
  };
}
