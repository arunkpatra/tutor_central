import { Hono } from "hono";
import { makeRequireUser, type Vars, type Verify } from "./auth.js";
import { aiRoutes } from "./routes/ai.js";

/** The API, built from its dependencies so tests run with a fake verifier. */
export function makeApp(deps: { verify: Verify }) {
  const app = new Hono<Vars>();
  app.get("/health", (c) => c.json({ ok: true, version: process.env.VERCEL_GIT_COMMIT_SHA?.slice(0, 7) ?? "local" }));
  app.use("/ai/*", makeRequireUser(deps.verify));
  app.route("/ai", aiRoutes);
  app.notFound((c) => c.json({ error: "no such route" }, 404));
  app.onError((e, c) => {
    console.error(e);
    return c.json({ error: "something went wrong on our side" }, 500);
  });
  return app;
}
