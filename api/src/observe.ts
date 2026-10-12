import { createClient } from "@supabase/supabase-js";
import type { Database } from "./generated/database.js";

/** One API request as `api_requests` keeps it (D77): never a body, never a name. */
export type RequestRow = {
  requestId: string;
  route: string;
  method: string;
  status: number;
  latencyMs: number;
  userId?: string;
  centreId?: string;
  reason?: string;
};

/** The observability client: the platform's (D83), so it writes `api_requests` and counts a user's recent calls. */
export type Observe = {
  recordRequest(row: RequestRow): Promise<void>;
  /** The user's requests in the last `seconds`, for the per-user rate limit. */
  recentCount(userId: string, seconds: number): Promise<number>;
};

export function makeObserve(url: string, serviceKey: string): Observe {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  return {
    async recordRequest(row) {
      const { error } = await client.from("api_requests").insert({
        request_id: row.requestId,
        route: row.route,
        method: row.method,
        status: row.status,
        latency_ms: row.latencyMs,
        user_id: row.userId ?? null,
        centre_id: row.centreId ?? null,
        reason: row.reason ?? null,
      });
      if (error) throw new Error(`api_requests: ${error.message}`);
    },
    async recentCount(userId, seconds) {
      const since = new Date(Date.now() - seconds * 1000).toISOString();
      const { count, error } = await client
        .from("api_requests")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .gt("created_at", since);
      if (error) throw new Error(`api_requests: ${error.message}`);
      return count ?? 0;
    },
  };
}
