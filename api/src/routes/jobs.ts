import { timingSafeEqual } from "node:crypto";
import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { makeHandlers } from "../jobs/kinds/index.js";
import { drain } from "../jobs/runner.js";
import { type Clock, type JobHandler, type JobKind, type JobsDb, realClock } from "../jobs/types.js";
import { log } from "../log.js";

/** The worker's run budget: under Hobby's 300 s with a step's room (D85; the two rise together on Pro). */
export const JOB_RUN_BUDGET_MS = 200_000;

/** The worker's reach: its jobs, the platform's Db for paid calls, its bearer, and the kinds it runs (the sweep alone
 *  unless the entry gives the record's source). */
export type Worker = { jobs: JobsDb; db: Db; secret: string; clock?: Clock; handlers?: Partial<Record<JobKind, JobHandler>> };

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

/** GET /jobs/tick (pg_cron, each minute) and POST /jobs/wake (the enqueue trigger): the worker's bearer, then one run.
 *  The tick first queues the ten minutes' sweep when none is live. Without the bearer, the AI routes' 401, so nothing new leaks. */
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
  r.get("/tick", async (c) => {
    if ((await worker.jobs.live("sweep")) === 0) await worker.jobs.enqueue(null, "sweep", sweepKey(clock.now()));
    return c.json(await run(c.get("requestId")));
  });
  r.post("/wake", async (c) => c.json(await run(c.get("requestId"))));
  return r;
}
