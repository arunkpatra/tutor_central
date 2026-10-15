import type { JobHandler } from "../types.js";

/** What the sweep removes and trims (plan decisions 20, 27): Storage's deleted files queued by 0040, the exports past
 *  seven days, the outbox's and the platform's old rows (0041), the inputs about a student past 90 days (0068). */
export type SweepSource = {
  /** taken_storage_deletions: each row handed out once and kept until done; one taken and not done comes back after ten
   *  minutes (0044). */
  takeDeletions(limit: number): Promise<{ id: string; bucket: string; path: string; prefix: boolean }[]>;
  /** done_storage_deletion: the row removed once Storage removed its files. */
  doneDeletion(id: string): Promise<void>;
  /** Every object's name under a prefix, page by page. */
  list(bucket: string, prefix: string): Promise<string[]>;
  /** The objects removed through the Storage API; one already gone is no error. */
  remove(bucket: string, paths: string[]): Promise<void>;
  /** old_exports: the exports made before a time. */
  oldExports(before: string, limit: number): Promise<string[]>;
  /** trim_platform: the counts deleted. */
  trim(now: string): Promise<{ notifications: number; jobs: number }>;
  /** reduce_old_inputs (0068, D117): what was sent about a student before a time reduced to a reference; the count. */
  reduceInputs(before: string, limit: number): Promise<number>;
};

const TAKE = 100;
const BATCH = 100;
const EXPORT_DAYS = 7;
/** What was sent about a student is kept beside what came back for 90 days (D79, D117), then only what came back. */
const INPUT_DAYS = 90;
const REDUCE = 500;

/** The platform's sweep, each ten minutes: rows pending past ten minutes closed as failed (Phase 17); then Storage's
 *  deleted files removed (a row's delete cannot reach Storage, which refuses a direct delete of its objects); then the
 *  retention. Without a source (a test of the tick), the first step alone. */
export function makeSweep(source?: SweepSource): JobHandler {
  return {
    async step(job, ctx) {
      const step = job.step as { at?: "storage" | "retention"; closed?: number; removed?: number; left?: number };
      if (step.at === undefined) {
        const closed = await ctx.jobs.closePending();
        if (!source) return { kind: "done", name: "pending", result: { closed } };
        return { kind: "continue", name: "pending", step: { at: "storage", closed } };
      }
      if (!source) return { kind: "done", name: "pending", result: { closed: step.closed ?? 0 } };
      if (step.at === "storage") {
        let removed = 0;
        let left = 0;
        for (const row of await source.takeDeletions(TAKE)) {
          // A row goes only once its files are gone: one Storage refuses stays for a later sweep, and the rest go on
          // (the review's R-db-2: the take deleted them first, and a failure orphaned the files).
          try {
            const paths = row.prefix ? await source.list(row.bucket, row.path) : [row.path];
            for (let i = 0; i < paths.length; i += BATCH) await source.remove(row.bucket, paths.slice(i, i + BATCH));
            await source.doneDeletion(row.id);
            removed += row.prefix ? paths.length : 1;
          } catch {
            left += 1;
          }
        }
        return { kind: "continue", name: "storage", step: { at: "retention", closed: step.closed ?? 0, removed, left } };
      }
      const now = new Date(ctx.clock.now());
      const old = await source.oldExports(new Date(now.getTime() - EXPORT_DAYS * 86_400_000).toISOString(), TAKE);
      for (let i = 0; i < old.length; i += BATCH) await source.remove("exports", old.slice(i, i + BATCH));
      const trimmed = await source.trim(now.toISOString());
      const reduced = await source.reduceInputs(new Date(now.getTime() - INPUT_DAYS * 86_400_000).toISOString(), REDUCE);
      return { kind: "done", name: "retention", result: { closed: step.closed ?? 0, removed: step.removed ?? 0, left: step.left ?? 0, trimmed: { ...trimmed, exports: old.length }, reduced } };
    },
  };
}
