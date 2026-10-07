import { Hono } from "hono";
import { makeRequireUser, type Vars, type Verify } from "./auth.js";
import { aiRoutes } from "./routes/ai.js";

/** The API, built from its dependencies so tests run with a fake verifier. `commit` is what /health reports: the
 *  deploy workflow sets it, so its smoke can tell the new deployment from the old one. */
export function makeApp(deps: { verify: Verify; commit?: string }) {
  const app = new Hono<Vars>();
  app.get("/health", (c) => c.json({ ok: true, commit: deps.commit ?? "local" }));
  app.use("/ai/*", makeRequireUser(deps.verify));
  app.route("/ai", aiRoutes);
  app.notFound((c) => c.json({ error: "no such route" }, 404));
  app.onError((e, c) => {
    console.error(e);
    return c.json({ error: "something went wrong on our side" }, 500);
  });
  return app;
}
