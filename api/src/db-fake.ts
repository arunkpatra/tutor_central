import { type AIKind, type Db, DbFailure, type Finish } from "./db.js";

const CONSENT_KINDS: AIKind[] = ["scan_register", "check_paper", "progress_note"];

/** An in-memory Db for tests: refuses as start_ai_generation would (consent, the limit) and records every call. */
export function fakeDb(
  options: { consent?: boolean; limit?: number; generations?: Record<string, { kind: AIKind; output: string | null }> } = {},
): Db & { started: unknown[]; finished: unknown[] } {
  const consent = options.consent ?? true;
  const limit = options.limit ?? 40;
  const started: unknown[] = [];
  const finished: unknown[] = [];
  return {
    started,
    finished,
    async start(token, args) {
      if (!consent && CONSENT_KINDS.includes(args.kind)) throw new DbFailure("consent");
      if (started.length >= limit) throw new DbFailure("limit", limit);
      started.push({ token, ...args });
      return `gen-${started.length}`;
    },
    async finish(token, id, result: Finish) {
      finished.push({ token, id, ...result });
    },
    async generation(_token, id) {
      const row = options.generations?.[id];
      return row ? { id, ...row } : null;
    },
  };
}
