import { createClient } from "@supabase/supabase-js";
import type { Database } from "../generated/database.js";
import type { SweepSource } from "./kinds/sweep.js";

/** The sweep's reach as the platform (D83): 0040's, 0041's and 0044's named functions, and the Storage API for the files. */
export function makeSweepSource(url: string, serviceKey: string): SweepSource {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const fail = (what: string, error: { message: string } | null) => {
    if (error) throw new Error(`${what}: ${error.message}`);
  };
  const list = async (bucket: string, prefix: string): Promise<string[]> => {
    // Storage lists one folder at a time: a name without an id is a folder, walked into.
    const folder = prefix.replace(/\/$/, "");
    const names: string[] = [];
    for (let offset = 0; ; offset += 1000) {
      const { data, error } = await client.storage.from(bucket).list(folder, { limit: 1000, offset });
      fail(`${bucket} list`, error);
      const page = data ?? [];
      for (const entry of page) {
        const path = `${folder}/${entry.name}`;
        if (entry.id === null) names.push(...(await list(bucket, `${path}/`)));
        else names.push(path);
      }
      if (page.length < 1000) break;
    }
    return names;
  };
  return {
    async takeDeletions(limit) {
      const { data, error } = await client.rpc("taken_storage_deletions", { p_limit: limit });
      fail("taken_storage_deletions", error);
      return (data ?? []).map((r) => ({ id: r.id, bucket: r.bucket, path: r.path, prefix: r.prefix }));
    },
    async doneDeletion(id) {
      const { error } = await client.rpc("done_storage_deletion", { p_id: id });
      fail("done_storage_deletion", error);
    },
    list,
    async remove(bucket, paths) {
      if (paths.length === 0) return;
      const { error } = await client.storage.from(bucket).remove(paths);
      fail(`${bucket} remove`, error);
    },
    async oldExports(before, limit) {
      const { data, error } = await client.rpc("old_exports", { p_before: before, p_limit: limit });
      fail("old_exports", error);
      return (data ?? []).map((r: { name: string }) => r.name);
    },
    async trim(now) {
      const { data, error } = await client.rpc("trim_platform", { p_now: now });
      fail("trim_platform", error);
      return data as { notifications: number; jobs: number };
    },
  };
}
