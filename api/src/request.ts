import type { MiddlewareHandler } from "hono";
import type { Vars } from "./auth.js";
import { errors } from "./errors.js";
import { log } from "./log.js";
import type { Observe } from "./observe.js";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The reason an error body carries, for the request's row; nothing for a success. */
async function reasonOf(res: Response): Promise<string | undefined> {
  if (res.status < 400) return undefined;
  const body = (await res.clone().json().catch(() => null)) as { reason?: unknown } | null;
  return typeof body?.reason === "string" ? body.reason : undefined;
}

/** Every request but /health: its id (the app's X-Request-Id, or a new one), its time, its row in `api_requests` written
 *  before the answer leaves, and one log line (D77). A row that cannot be written is logged; the answer still goes. */
export function makeRequest(observe: Observe): MiddlewareHandler<Vars> {
  return async (c, next) => {
    const asked = c.req.header("x-request-id");
    const requestId = asked && UUID.test(asked) ? asked.toLowerCase() : crypto.randomUUID();
    c.set("requestId", requestId);
    const started = performance.now();
    await next();
    c.header("X-Request-Id", requestId);
    if (c.req.path === "/health") return;
    const row = {
      requestId,
      route: c.req.path,
      method: c.req.method,
      status: c.res.status,
      latencyMs: Math.round(performance.now() - started),
      userId: c.get("userId"),
      centreId: c.get("centreId"),
      reason: await reasonOf(c.res),
    };
    try {
      await observe.recordRequest(row);
    } catch (e) {
      log.error({ requestId, route: row.route, message: "the request's row was not written", error: e });
    }
    log.info({ requestId, route: row.route, status: row.status, ms: row.latencyMs, userId: row.userId, centre: row.centreId, reason: row.reason });
  };
}

/** 20 calls a minute per user (a count of their rows in `api_requests` under 429, read before the gate): 429 `rate`. The
 *  refusals are not counted, so a client retrying past the limit is let through a minute after its last answered call. A
 *  count that cannot be read lets the call through; the database's allowance still holds. */
export function makeUserRate(observe: Observe, perMinute = 20): MiddlewareHandler<Vars> {
  return async (c, next) => {
    const userId = c.get("userId");
    const recent = await observe.recentCount(userId, 60).catch((e) => {
      log.warn({ requestId: c.get("requestId"), message: "the rate count was not read", error: e });
      return 0;
    });
    if (recent >= perMinute) {
      const e = errors.rate();
      return c.json(e.body, e.status);
    }
    await next();
  };
}

/** 60 requests a minute per address, in this instance's memory: best effort across Vercel's instances (said in
 *  api/CLAUDE.md). An address is Vercel's x-forwarded-for; a request without one (local runs, tests) is not counted. */
export function makeAddressRate(perMinute = 60): MiddlewareHandler<Vars> {
  const seen = new Map<string, number[]>();
  return async (c, next) => {
    const address = c.req.header("x-forwarded-for")?.split(",")[0]?.trim();
    if (address) {
      const now = Date.now();
      const recent = (seen.get(address) ?? []).filter((t) => now - t < 60_000);
      if (recent.length >= perMinute) {
        seen.set(address, recent);
        const e = errors.rate();
        return c.json(e.body, e.status);
      }
      recent.push(now);
      seen.set(address, recent);
      if (seen.size > 10_000) for (const [key, times] of seen) if (times.every((t) => now - t >= 60_000)) seen.delete(key);
    }
    await next();
  };
}
