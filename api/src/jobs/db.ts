import { createClient } from "@supabase/supabase-js";
import type { Database, Json } from "../generated/database.js";
import { type Job, type JobKind, type JobsDb, LeaseLost, type StepOutcome } from "./types.js";

type JobRow = Database["public"]["Tables"]["jobs"]["Row"];

function job(row: JobRow): Job {
  return {
    id: row.id,
    centreId: row.centre_id,
    kind: row.kind,
    attempts: row.attempts,
    step: (row.step ?? {}) as Record<string, unknown>,
    input: (row.input ?? {}) as Record<string, unknown>,
    leaseUntil: row.lease_until ?? "",
  };
}

/** A database error that means the job is no longer this worker's; anything else is thrown as it is. */
function lost(message: string): LeaseLost | null {
  for (const why of ["job_lease_lost", "job_cancelled", "job_not_running"] as const) if (message.includes(why)) return new LeaseLost(why);
  return null;
}

/** The step row's state for an outcome. */
const STATE = { continue: "done", done: "done", wait: "waiting", fail: "failed" } as const;

/** The real JobsDb over the service role (D83). The worker reaches the database through these named functions alone. */
export function makeJobsDb(url: string, serviceKey: string): JobsDb {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  /** The function's answer, or what its error means; a write with no answer passes nothing back. */
  const must = <T>(r: { data: T | null; error: { message: string } | null }): T => {
    if (r.error) throw lost(r.error.message) ?? new Error(r.error.message);
    if (r.data === null) throw new Error("the database answered nothing");
    return r.data;
  };
  const done = (r: { error: { message: string } | null }): void => {
    if (r.error) throw lost(r.error.message) ?? new Error(r.error.message);
  };
  return {
    async claim(worker, limit) {
      return must(await client.rpc("claim_jobs", { p_worker: worker, p_limit: limit })).map(job);
    },
    async extend(id, worker) {
      return must(await client.rpc("extend_lease", { p_job: id, p_worker: worker }));
    },
    async record(id, worker, outcome: StepOutcome) {
      done(
        await client.rpc("record_step", {
          p_job: id,
          p_worker: worker,
          p_step: outcome.name,
          p_state: STATE[outcome.kind],
          p_generation: outcome.generationId,
          p_error: outcome.kind === "fail" ? (outcome.error as Json) : undefined,
          p_cost_paise: "costPaise" in outcome ? (outcome.costPaise ?? 0) : 0,
          p_step_data: outcome.kind === "continue" || outcome.kind === "wait" ? (outcome.step as Json) : undefined,
        }),
      );
      if (outcome.kind === "done") done(await client.rpc("finish_job", { p_job: id, p_worker: worker, p_result: outcome.result as Json }));
      if (outcome.kind === "wait") {
        done(await client.rpc("wait_job", { p_job: id, p_worker: worker, p_step: outcome.step as Json, p_run_at: outcome.runAt.toISOString() }));
      }
      if (outcome.kind === "fail") {
        done(await client.rpc("fail_job", { p_job: id, p_worker: worker, p_error: outcome.error as Json, p_retry: outcome.retry }));
      }
    },
    async enqueue(centre, kind: JobKind, key, input = {}, runAt) {
      return must(
        await client.rpc("enqueue_job", {
          // A platform job has no centre; the function's parameter is a uuid that takes null.
          p_centre: centre as string,
          p_kind: kind,
          p_key: key,
          p_input: input as Json,
          p_run_at: runAt?.toISOString(),
        }),
      );
    },
    async live(kind) {
      const r = await client.from("jobs").select("id", { count: "exact", head: true }).eq("kind", kind).in("state", ["queued", "waiting", "running"]);
      if (r.error) throw new Error(r.error.message);
      return r.count ?? 0;
    },
    async closePending() {
      return must(await client.rpc("close_pending_generations", {}));
    },
  };
}
