import { createClient } from "@supabase/supabase-js";
import type { Database } from "../generated/database.js";
import type { PdfSource } from "../jobs/kinds/pdf.js";

/** The artefact read and the private buckets written through the service role (D83); every read names the job's centre.
 *  An upload replaces a file of the same path (a job retaken). */
export function makePdfSource(url: string, serviceKey: string): PdfSource {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  return {
    async artefact(centre, id) {
      const r = await client.from("artefacts").select("kind, title, content").eq("centre_id", centre).eq("id", id).maybeSingle();
      if (r.error) throw new Error(`artefacts: ${r.error.message}`);
      return r.data ? { kind: r.data.kind, title: r.data.title, content: r.data.content as Record<string, unknown> } : null;
    },
    async upload(bucket, path, bytes) {
      const { error } = await client.storage.from(bucket).upload(path, bytes, { contentType: "application/pdf", upsert: true });
      if (error) throw new Error(`${bucket}: ${error.message}`);
    },
  };
}
