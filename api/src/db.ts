import { createClient } from "@supabase/supabase-js";
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
};

/** The database as the tutor: every call carries their own JWT, so row-level security decides what is read and written
 *  (no service-role key, D11). */
export type Db = {
  /** start_ai_generation: the consent, the day's limit and the pending record; the row's id. Throws DbFailure. */
  start(token: string, args: { centre: string; kind: AIKind; input: unknown; model: string; student?: string }): Promise<string>;
  /** The row finished as the API saw it. A failure is logged and swallowed: the tutor has their answer, and a row left
   *  pending still counts against the limit, which is the safe side. */
  finish(token: string, id: string, result: Finish): Promise<void>;
  /** A generation the tutor's centre made, for a scheme from a paper; null when there is none they can see. */
  generation(token: string, id: string): Promise<{ id: string; kind: AIKind; output: string | null } | null>;
};

export class DbFailure extends Error {
  constructor(
    public readonly reason: "not_a_member" | "consent" | "student_consent" | "limit" | "other",
    public readonly limit?: number,
  ) {
    super(reason);
    this.name = "DbFailure";
  }
}

export function makeDb(url: string, anonKey: string): Db {
  const client = (token: string) =>
    createClient<Database>(url, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
  return {
    async start(token, { centre, kind, input, model, student }) {
      const { data, error } = await client(token).rpc("start_ai_generation", {
        p_centre: centre,
        p_kind: kind,
        p_input: input as Json,
        p_model: model,
        p_student: student,
      });
      if (error) {
        if (error.message.includes("ai_not_a_member")) throw new DbFailure("not_a_member");
        if (error.message.includes("ai_consent_missing")) throw new DbFailure(student ? "student_consent" : "consent");
        if (error.message.includes("ai_limit_reached")) throw new DbFailure("limit", Number(error.details));
        log.error({ at: "db start", message: error.message });
        throw new DbFailure("other");
      }
      return data as string;
    },
    async finish(token, id, { status, output, model, tokensIn, tokensOut }) {
      const { error } = await client(token)
        .from("ai_generations")
        .update({ status, output, model, tokens_in: tokensIn, tokens_out: tokensOut })
        .eq("id", id);
      if (error) log.error({ at: "db finish", generation: id, message: error.message });
    },
    async generation(token, id) {
      const { data, error } = await client(token).from("ai_generations").select("id, kind, output").eq("id", id).maybeSingle();
      if (error) {
        log.error({ at: "db generation", generation: id, message: error.message });
        return null;
      }
      return data ? { id: data.id as string, kind: data.kind as AIKind, output: (data.output as string | null) ?? null } : null;
    },
  };
}
