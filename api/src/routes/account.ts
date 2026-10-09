import { Hono } from "hono";
import { type AppleClient, AppleFailure } from "../apple.js";
import type { Vars } from "../auth.js";
import { RevokeAppleInput } from "../schemas.js";

/** Account routes (D38): the app sends a fresh Apple authorization code before it deletes the account; Apple is told
 *  to forget the app. The deletion itself is the database's (delete_account, D37), never the API's. */
export function accountRoutes(apple: AppleClient) {
  const r = new Hono<Vars>();
  r.post("/revoke-apple", async (c) => {
    const parsed = RevokeAppleInput.safeParse(await c.req.json().catch(() => ({})));
    if (!parsed.success) {
      const words = parsed.error.issues.map((i) => (i.path.length ? `${i.path.join(".")}: ${i.message}` : i.message));
      return c.json({ error: words.join("; ") }, 400);
    }
    try {
      await apple.revokeAuthorization(parsed.data.code);
    } catch (e) {
      if (e instanceof AppleFailure && e.reason === "refused") {
        return c.json({ error: "Apple didn't accept the confirmation. Try again." }, 400);
      }
      return c.json({ error: "Apple didn't answer. Try again in a minute." }, 502);
    }
    return c.body(null, 204);
  });
  return r;
}
