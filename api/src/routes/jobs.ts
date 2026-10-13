import { timingSafeEqual } from "node:crypto";
import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { makeHandlers } from "../jobs/kinds/index.js";
import { drain } from "../jobs/runner.js";
import { type Clock, type JobHandler, type JobKind, type JobsDb, realClock } from "../jobs/types.js";
import { log } from "../log.js";
import { renderPdf } from "../pdf/render.js";
import { preamble, t } from "../pdf/typst.js";
import { alertPayload } from "../push/payload.js";
import type { Pusher } from "../push/apns.js";
import type { OutboxDb } from "../push/db.js";
import { sendDue } from "../push/send-due.js";

/** The worker's run budget: under Hobby's 300 s with a step's room (D85; the two rise together on Pro). */
export const JOB_RUN_BUDGET_MS = 200_000;

/** The worker's reach: its jobs, the platform's Db for paid calls, its bearer, the kinds it runs (the sweep alone unless
 *  the entry gives the record's source), and the outbox with a pusher made for each run (D88: providers opened per run). */
export type Worker = {
  jobs: JobsDb;
  db: Db;
  secret: string;
  clock?: Clock;
  handlers?: Partial<Record<JobKind, JobHandler>>;
  push?: { outbox: OutboxDb; pusher: () => Pusher };
};

function sameSecret(given: string | undefined, secret: string): boolean {
  if (!given) return false;
  const a = Buffer.from(given);
  const b = Buffer.from(secret);
  return a.length === b.length && timingSafeEqual(a, b);
}

/** The sweep's key, by the UTC ten minutes: one sweep each ten minutes whatever the number of ticks, so a call left
 *  pending (its key answering "in progress") is closed within twenty (plan decision 28). */
export function sweepKey(now: number): string {
  const bucket = new Date(Math.floor(now / 600_000) * 600_000);
  return `sweep:${bucket.toISOString().slice(0, 16).replace("T", "-")}`;
}

/** The alerts job's key, by the UTC ten minutes as the sweep's (D95). */
export function alertsKey(now: number): string {
  return `alerts:${sweepKey(now).slice("sweep:".length)}`;
}

/** GET /jobs/tick (pg_cron, each minute) and POST /jobs/wake (the enqueue trigger): the worker's bearer, then one run.
 *  The tick first queues the ten minutes' sweep and alerts when none is live. Without the bearer, the AI routes' 401, so nothing new leaks. */
export function jobRoutes(worker: Worker, claude: ClaudeClient) {
  const r = new Hono<Vars>();
  const clock = worker.clock ?? realClock;
  const handlers = worker.handlers ?? makeHandlers();
  r.use("*", async (c, next) => {
    const given = c.req.header("authorization")?.match(/^Bearer\s+(\S+)$/i)?.[1];
    if (!sameSecret(given, worker.secret)) return c.json({ error: "sign in again" }, 401);
    await next();
  });
  const run = async (requestId: string) => {
    const name = `${process.env.VERCEL_REGION ?? "local"}-${crypto.randomUUID().slice(0, 8)}`;
    const result = await drain({ jobs: worker.jobs, handlers, ctx: { db: worker.db, claude, clock, requestId }, worker: name, budgetMs: JOB_RUN_BUDGET_MS });
    log.info({ requestId, worker: name, ...result });
    return result;
  };
  /** The minute's pushes (plan decision 7), before the jobs: a reminder due now is not held behind a plan's material. A
   *  failure to reach the outbox is logged and the jobs still run. */
  const push = async (requestId: string) => {
    if (!worker.push) return undefined;
    const pusher = worker.push.pusher();
    try {
      const counts = await sendDue({ outbox: worker.push.outbox, pusher, clock });
      log.info({ requestId, push: counts });
      return counts;
    } catch (e) {
      log.error({ requestId, message: "the outbox was not sent", error: e });
      return undefined;
    } finally {
      await pusher.close();
    }
  };
  r.get("/tick", async (c) => {
    const pushed = await push(c.get("requestId"));
    if ((await worker.jobs.live("sweep")) === 0) await worker.jobs.enqueue(null, "sweep", sweepKey(clock.now()));
    // The alerts job runs only where its source is given (the entry's; a test's).
    if (handlers.alerts && (await worker.jobs.live("alerts")) === 0) await worker.jobs.enqueue(null, "alerts", alertsKey(clock.now()));
    return c.json({ ...(await run(c.get("requestId"))), ...(pushed ? { push: pushed } : {}) });
  });
  r.post("/wake", async (c) => c.json(await run(c.get("requestId"))));
  /** The deploy's proof of the new parts (plan decision 26): one page rendered with a Devanagari line (the module and the
   *  fonts are with the function), and APNs asked once in production with a token no device has: "BadDeviceToken" means
   *  Apple took the key, the team and the topic. */
  r.get("/health", async (c) => {
    let pdf = 0;
    try {
      pdf = (await renderPdf(`${preamble()}\n${t("Tutor Central · नमस्ते")}`)).pages;
    } catch (e) {
      log.error({ requestId: c.get("requestId"), message: "the health page did not render", error: e });
    }
    let apns = false;
    if (worker.push) {
      const pusher = worker.push.pusher();
      try {
        const answer = await pusher.send({ token: "0".repeat(64), environment: "production", payload: alertPayload({ id: "health", kind: "health", title: "-", body: "-", link: null }) });
        apns = answer.ok || answer.reason === "BadDeviceToken";
      } finally {
        await pusher.close();
      }
    }
    return c.json({ pdf, apns });
  });
  return r;
}
