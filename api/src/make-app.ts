import { Hono } from "hono";
import { bodyLimit } from "hono/body-limit";
import type { AppleClient } from "./apple.js";
import { makeRequireUser, type Vars, type Verify } from "./auth.js";
import type { ClaudeClient } from "./claude.js";
import type { Db } from "./db.js";
import { errors } from "./errors.js";
import { log } from "./log.js";
import type { Observe } from "./observe.js";
import { makeAddressRate, makeRequest, makeUserRate } from "./request.js";
import { accountRoutes } from "./routes/account.js";
import { aiRoutes } from "./routes/ai.js";

export type Deps = { verify: Verify; commit?: string; claude: ClaudeClient; db: Db; apple: AppleClient; observe: Observe };

/** Past this a body is refused in words before it is read: Vercel's own 4.5 MB would answer first otherwise. */
export const BODY_LIMIT_BYTES = 4_400_000;

/** The API, built from its dependencies so tests run with a fake verifier, a fake Claude, a fake database and a fake Apple. `commit`
 *  is what /health reports: the deploy workflow sets it, so its smoke can tell the new deployment from the old one. */
export function makeApp(deps: Deps) {
  const app = new Hono<Vars>();
  const byAddress = makeAddressRate();
  const byUser = makeUserRate(deps.observe);
  const tooLarge = errors.tooLarge();
  app.use("*", makeRequest(deps.observe));
  app.get("/health", (c) => c.json({ ok: true, commit: deps.commit ?? "local" }));
  app.use("/ai/*", byAddress, bodyLimit({ maxSize: BODY_LIMIT_BYTES, onError: (c) => c.json(tooLarge.body, tooLarge.status) }));
  app.use("/ai/*", makeRequireUser(deps.verify), byUser);
  app.route("/ai", aiRoutes(deps));
  app.use("/account/*", byAddress, makeRequireUser(deps.verify), byUser);
  app.route("/account", accountRoutes(deps.apple));
  app.notFound((c) => c.json({ error: "no such route" }, 404));
  app.onError((e, c) => {
    log.error({ requestId: c.get("requestId"), route: c.req.path, error: e });
    return c.json({ error: "something went wrong on our side" }, 500);
  });
  return app;
}
