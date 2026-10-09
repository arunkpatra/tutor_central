import { Hono } from "hono";
import type { AppleClient } from "./apple.js";
import { makeRequireUser, type Vars, type Verify } from "./auth.js";
import type { ClaudeClient } from "./claude.js";
import type { Db } from "./db.js";
import { accountRoutes } from "./routes/account.js";
import { aiRoutes } from "./routes/ai.js";

export type Deps = { verify: Verify; commit?: string; claude: ClaudeClient; db: Db; apple: AppleClient };

/** The API, built from its dependencies so tests run with a fake verifier, a fake Claude, a fake database and a fake Apple. `commit`
 *  is what /health reports: the deploy workflow sets it, so its smoke can tell the new deployment from the old one. */
export function makeApp(deps: Deps) {
  const app = new Hono<Vars>();
  app.get("/health", (c) => c.json({ ok: true, commit: deps.commit ?? "local" }));
  app.use("/ai/*", makeRequireUser(deps.verify));
  app.route("/ai", aiRoutes(deps));
  app.use("/account/*", makeRequireUser(deps.verify));
  app.route("/account", accountRoutes(deps.apple));
  app.notFound((c) => c.json({ error: "no such route" }, 404));
  app.onError((e, c) => {
    console.error(e);
    return c.json({ error: "something went wrong on our side" }, 500);
  });
  return app;
}
