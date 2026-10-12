import { createClient } from "@supabase/supabase-js";
import type { Hono } from "hono";
import { appleHttp } from "./apple.js";
import { fakeApple } from "./apple-fake.js";
import type { Vars } from "./auth.js";
import { anthropicClaude } from "./claude.js";
import { fakeClaude, localScript } from "./claude-fake.js";
import { makeDb, makePlatformDb } from "./db.js";
import { env } from "./env.js";
import { makeJobsDb } from "./jobs/db.js";
import { makeHandlers } from "./jobs/kinds/index.js";
import { makeRecordSource } from "./jobs/record.js";
import { makeApp } from "./make-app.js";
import { applyModelOverrides } from "./models.js";
import { makeObserve } from "./observe.js";
import { makeApnsPusher } from "./push/apns.js";
import { fakePusher } from "./push/apns-fake.js";
import { makeOutboxDb } from "./push/db.js";
import { makeNoteSource } from "./notes/record.js";
import { makePdfSource } from "./pdf/source.js";
import { makeReminderSource } from "./reminders/source.js";
import { makeVerify } from "./verify.js";

/** Read at start: a deployment without them fails to boot, so /health and the deploy's smoke fail, instead of every
 *  tutor being told to sign in again. AI_FAKE=1 (local runs only, never in Vercel) answers from the fake, so a hand
 *  run costs nothing while the consent, the limit and the record still run against the database. */
/** A fake in production would answer a tutor's call from samples, or skip Apple: refused at start, so the deploy's smoke
 *  fails instead (plan decision 27). */
for (const fake of ["AI_FAKE", "APPLE_FAKE"] as const) {
  if (process.env.VERCEL_ENV === "production" && process.env[fake] === "1") throw new Error(`${fake} is refused in production`);
}
const supabaseUrl = env("SUPABASE_URL");
/** AI_MODEL_<WORK_TYPE> overrides api/models.json at deploy (D67); an unknown name stops the start, as a missing setting does. */
applyModelOverrides(process.env);
const supabaseAnonKey = env("SUPABASE_ANON_KEY");
/** The platform's identity (D83): read here alone and handed to the observability client and the worker, never to the
 *  tutor routes' database client, which carries the tutor's own token. */
const serviceKey = env("SUPABASE_SERVICE_ROLE_KEY");
/** The bearer pg_cron and the enqueue trigger send to /jobs/* (D85). */
const workerSecret = env("WORKER_SECRET");
const claude = process.env.AI_FAKE === "1" ? fakeClaude(localScript) : anthropicClaude(env("ANTHROPIC_API_KEY"));
/** The Sign in with Apple key signs the client secret for revocation (D38). Vercel keeps the .p8's newlines; a one-line
 *  value with "\n" (api/.env.local) is turned back. APPLE_FAKE=1 (local runs only) answers without Apple. */
const apple =
  process.env.APPLE_FAKE === "1"
    ? fakeApple({})
    : appleHttp({
        teamId: env("APPLE_TEAM_ID"),
        keyId: env("APPLE_KEY_ID"),
        privateKeyPem: env("APPLE_SIGNIN_KEY").replace(/\\n/g, "\n"),
        clientId: "in.tutorcentral.app",
      });

/** APNs (D88): the token key, its id, the team and the topic. Production must have them (a deploy without them fails its
 *  smoke); a local run without them sends to a pusher in memory, which logs nothing out of the Mac. Vercel keeps the
 *  .p8's newlines; a one-line value with "\n" (api/.env.local) is turned back. */
const pushConfigured = ["APNS_KEY", "APNS_KEY_ID", "APNS_TEAM_ID", "APNS_TOPIC"].every((name) => process.env[name]);
const pusher =
  pushConfigured || process.env.VERCEL_ENV === "production"
    ? () =>
        makeApnsPusher({
          key: env("APNS_KEY").replace(/\\n/g, "\n"),
          keyId: env("APNS_KEY_ID"),
          teamId: env("APNS_TEAM_ID"),
          topic: env("APNS_TOPIC"),
        })
    : () => fakePusher({});

const outbox = makeOutboxDb(supabaseUrl, serviceKey);
/** The record the plan and note jobs read and write as the platform (D83), with the outbox for their pushes. */
const record = makeRecordSource(supabaseUrl, serviceKey, outbox);

/** A 4xx from Supabase is the token's (sign in again); a lost connection is "unreachable" (D68). */
const verify = makeVerify(() => createClient(supabaseUrl, supabaseAnonKey, { auth: { persistSession: false, autoRefreshToken: false } }));

/** Vercel's Hono preset and `bun --hot` both serve this default export. The preset takes as its entry the first of
 *  app, index, server, src/app, src/index, src/server that imports "hono": this file (test/entry.test.ts). */
const app: Hono<Vars> = makeApp({
  verify,
  commit: process.env.TC_COMMIT,
  claude,
  db: makeDb(supabaseUrl, supabaseAnonKey, serviceKey),
  apple,
  observe: makeObserve(supabaseUrl, serviceKey),
  worker: {
    jobs: makeJobsDb(supabaseUrl, serviceKey),
    db: makePlatformDb(supabaseUrl, serviceKey),
    secret: workerSecret,
    handlers: makeHandlers({ record, reminders: makeReminderSource(supabaseUrl, serviceKey, outbox), notes: makeNoteSource(supabaseUrl, serviceKey, record), files: makePdfSource(supabaseUrl, serviceKey) }),
    push: { outbox, pusher },
  },
});
export default app;
