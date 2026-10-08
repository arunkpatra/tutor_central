import { createClient } from "@supabase/supabase-js";

export type AIKind = "paper" | "homework" | "worksheet" | "progress_note" | "scan_register" | "check_paper";
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
  start(token: string, args: { centre: string; kind: AIKind; input: unknown; model: string }): Promise<string>;
  /** The row finished as the API saw it. A failure is logged and swallowed: the tutor has their answer, and a row left
   *  pending still counts against the limit, which is the safe side. */
  finish(token: string, id: string, result: Finish): Promise<void>;
  /** A generation the tutor's centre made, for a scheme from a paper; null when there is none they can see. */
  generation(token: string, id: string): Promise<{ id: string; kind: AIKind; output: string | null } | null>;
};

export class DbFailure extends Error {
  constructor(
    public readonly reason: "not_a_member" | "consent" | "limit" | "other",
    public readonly limit?: number,
  ) {
    super(reason);
    this.name = "DbFailure";
  }
}

export function makeDb(url: string, anonKey: string): Db {
  const client = (token: string) =>
    createClient(url, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
  return {
    async start(token, { centre, kind, input, model }) {
      const { data, error } = await client(token).rpc("start_ai_generation", {
        p_centre: centre,
        p_kind: kind,
        p_input: input,
        p_model: model,
      });
      if (error) {
        if (error.message.includes("ai_not_a_member")) throw new DbFailure("not_a_member");
        if (error.message.includes("ai_consent_missing")) throw new DbFailure("consent");
        if (error.message.includes("ai_limit_reached")) throw new DbFailure("limit", Number(error.details));
        console.error("db start", error.message);
        throw new DbFailure("other");
      }
      return data as string;
    },
    async finish(token, id, { status, output, model, tokensIn, tokensOut }) {
      const { error } = await client(token)
        .from("ai_generations")
        .update({ status, output, model, tokens_in: tokensIn, tokens_out: tokensOut })
        .eq("id", id);
      if (error) console.error("db finish", id, error.message);
    },
    async generation(token, id) {
      const { data, error } = await client(token).from("ai_generations").select("id, kind, output").eq("id", id).maybeSingle();
      if (error) {
        console.error("db generation", id, error.message);
        return null;
      }
      return data ? { id: data.id as string, kind: data.kind as AIKind, output: (data.output as string | null) ?? null } : null;
    },
  };
}
