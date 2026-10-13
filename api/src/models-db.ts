import { createClient } from "@supabase/supabase-js";

/** A row of `ai_models_current()` (0052): the model, effort, fallback and switch of a kind of work and step. */
export type ModelRow = {
  kind: string;
  step: "draft" | "check" | "repair";
  model: string;
  effort: "low" | "medium" | "high";
  fallbackModel: string | null;
  enabled: boolean;
};
export type ModelSource = { current(): Promise<ModelRow[]> };

type RawRow = { kind: string; step: ModelRow["step"]; model: string; effort: ModelRow["effort"]; fallback_model: string | null; enabled: boolean };
type Rpc = { rpc(name: string): PromiseLike<{ data: unknown; error: { message: string } | null }> };

/** The table read through a client that can call `ai_models_current`; an error answer throws. */
export function modelSourceFrom(client: Rpc): ModelSource {
  return {
    async current() {
      const { data, error } = await client.rpc("ai_models_current");
      if (error) throw new Error(`ai_models could not be read: ${error.message}`);
      return (data as RawRow[]).map((r) => ({ kind: r.kind, step: r.step, model: r.model, effort: r.effort, fallbackModel: r.fallback_model, enabled: r.enabled }));
    },
  };
}

/** The platform reads the table (D83): a member reads nothing of it. */
export function makeModelSource(url: string, serviceKey: string): ModelSource {
  return modelSourceFrom(createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } }));
}

/** Tests: fixed rows. */
export function fakeModelSource(rows: ModelRow[]): ModelSource & { rows: ModelRow[] } {
  return { rows, current: async () => rows };
}
