import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database, Json } from "./generated/database.js";
import { log } from "./log.js";

export type AIKind = V1Kind | V2Kind;
export type V1Kind = "paper" | "homework" | "worksheet" | "progress_note" | "scan_register" | "check_paper";
/** The V2 kinds (migration 0012): one monthly allowance per centre; note, can_do, test_tomorrow, gap_report,
 *  not_on_track and read_marks need the student's consent (start_ai_generation, 0013 and 0024), as does check_paper
 *  naming a student (0021). */
export type V2Kind =
  | "plan"
  | "sheet"
  | "worked_example"
  | "figure"
  | "brief"
  | "check"
  | "placement"
  | "mock"
  | "note"
  | "can_do"
  | "test_tomorrow"
  | "gap_report"
  | "parse_school"
  | "parse_textbook"
  | "not_on_track"
  | "read_marks";
export type Finish = {
  status: "ok" | "failed";
  output: string | null;
  model: string;
  tokensIn: number | null;
  tokensOut: number | null;
  /** Priced by api/models.json at finish (src/price.ts); null when no tokens came back. */
  costPaise: number | null;
  latencyMs: number;
  /** The SHA-256 of the prompt's system words. */
  promptHash: string;
  stopReason: string | null;
  /** timeout, api <status>, unfit, refused, truncated or error; null for an answer kept. */
  errorReason: string | null;
  finishedAt: string;
};

/** One paid call asked of the gate (start_ai_call, 0029): the key and the body's hash replay a call made within a day;
 *  the request id and the job tie the row to what asked for it. */
export type StartCall = {
  centre: string;
  kind: AIKind;
  input: unknown;
  model: string;
  student?: string;
  key?: string;
  inputHash?: string;
  requestId?: string;
  job?: string;
};
/** The gate's answer: a new pending row, or a replay of the key's row (pending, or finished with its output). */
export type Started = { id: string; replay: boolean; status: "pending" | "ok"; output: string | null };

/** The database as the tutor: every call carries their own JWT, so row-level security decides what is read and written.
 *  The platform's (makePlatformDb) is the same over the service role (D83) and ignores the token. */
export type Db = {
  /** start_ai_call: the consent, the allowance, the key and the pending record. Throws DbFailure. */
  startCall(token: string, args: StartCall): Promise<Started>;
  /** The row finished as the API saw it. A failure is logged and swallowed: the tutor has their answer, and a row left
   *  pending still counts against the limit, which is the safe side (the sweep closes it after ten minutes). */
  finish(token: string, id: string, result: Finish): Promise<void>;
  /** A generation the tutor's centre made, for a scheme from a paper; null when there is none they can see. */
  generation(token: string, id: string): Promise<{ id: string; kind: AIKind; output: string | null } | null>;
};

export class DbFailure extends Error {
  constructor(
    public readonly reason: "not_a_member" | "consent" | "student_consent" | "limit" | "key_reused" | "other",
    public readonly limit?: number,
  ) {
    super(reason);
    this.name = "DbFailure";
  }
}

const options = { auth: { persistSession: false, autoRefreshToken: false } };

/** The tutor's database: a client per call with their own token. */
export function makeDb(url: string, anonKey: string): Db {
  return dbOver((token) => createClient<Database>(url, anonKey, { ...options, global: { headers: { Authorization: `Bearer ${token}` } } }));
}

/** The platform's database (D83): the service role, for the worker's calls; the token argument is not used. */
export function makePlatformDb(url: string, serviceKey: string): Db {
  const client = createClient<Database>(url, serviceKey, options);
  return dbOver(() => client);
}

function dbOver(client: (token: string) => SupabaseClient<Database>): Db {
  return {
    async startCall(token, { centre, kind, input, model, student, key, inputHash, requestId, job }) {
      const { data, error } = await client(token).rpc("start_ai_call", {
        p_centre: centre,
        p_kind: kind,
        p_input: input as Json,
        p_model: model,
        p_student: student,
        p_key: key,
        p_input_hash: inputHash,
        p_request_id: requestId,
        p_job: job,
      });
      if (error) {
        if (error.message.includes("ai_not_a_member")) throw new DbFailure("not_a_member");
        if (error.message.includes("ai_consent_missing")) throw new DbFailure(student ? "student_consent" : "consent");
        if (error.message.includes("ai_limit_reached")) throw new DbFailure("limit", Number(error.details));
        if (error.message.includes("ai_key_reused")) throw new DbFailure("key_reused");
        log.error({ at: "db start", requestId, message: error.message });
        throw new DbFailure("other");
      }
      return data as unknown as Started;
    },
    async finish(token, id, r) {
      const { error } = await client(token)
        .from("ai_generations")
        .update({
          status: r.status,
          output: r.output,
          model: r.model,
          tokens_in: r.tokensIn,
          tokens_out: r.tokensOut,
          cost_paise: r.costPaise,
          latency_ms: r.latencyMs,
          prompt_hash: r.promptHash,
          stop_reason: r.stopReason,
          error_reason: r.errorReason,
          finished_at: r.finishedAt,
        })
        .eq("id", id);
      if (error) log.error({ at: "db finish", generation: id, message: error.message });
    },
    async generation(token, id) {
      const { data, error } = await client(token).from("ai_generations").select("id, kind, output").eq("id", id).maybeSingle();
      if (error) {
        log.error({ at: "db generation", generation: id, message: error.message });
        return null;
      }
      return data ? { id: data.id, kind: data.kind as AIKind, output: data.output ?? null } : null;
    },
  };
}
