import { type AIKind, type Db, DbFailure, type Finish, type Started } from "./db.js";

/** A row as the fake gate made it, with its finish once the API finished it. */
export type FakeRow = { id: string; kind: AIKind; agentStep: string; key?: string; model: string; job?: string; finish?: Finish; batched?: boolean };

const CONSENT_KINDS: AIKind[] = ["scan_register", "check_paper", "progress_note"];

/** An in-memory Db for tests: refuses as start_ai_call would (the centre's consent, a named student's consent, the limit,
 *  a key reused with another body), replays a key it is given, and records every call. */
export function fakeDb(
  options: {
    consent?: boolean;
    /** False refuses every named student; by student, only those false. */
    studentConsent?: boolean | Record<string, boolean>;
    limit?: number;
    generations?: Record<string, { kind: AIKind; output: string | null }>;
    /** Keys whose row the gate already holds: replayed, pending or finished. */
    replays?: Record<string, { id: string; status: "pending" | "ok"; output: string | null }>;
    /** Keys the gate refuses as reused with another body. */
    keyReused?: string[];
  } = {},
): Db & { started: unknown[]; finished: unknown[]; rows: FakeRow[] } {
  const consent = options.consent ?? true;
  const limit = options.limit ?? 40;
  const started: unknown[] = [];
  const finished: unknown[] = [];
  const rows: FakeRow[] = [];
  return {
    started,
    finished,
    rows,
    async startCall(token, args): Promise<Started> {
      if (!consent && CONSENT_KINDS.includes(args.kind)) throw new DbFailure("consent");
      const refused = typeof options.studentConsent === "object" ? args.student !== undefined && options.studentConsent[args.student] === false : options.studentConsent === false;
      if (args.student && refused) throw new DbFailure("student_consent");
      if (args.key && options.keyReused?.includes(args.key)) throw new DbFailure("key_reused");
      const replay = args.key ? options.replays?.[args.key] : undefined;
      if (replay) return { ...replay, replay: true };
      // As 0052: only a draft counts against the allowance.
      const step = args.agentStep ?? "draft";
      if (step === "draft" && rows.filter((r) => r.agentStep === "draft").length >= limit) throw new DbFailure("limit", limit);
      started.push({ token, ...args });
      const id = `gen-${started.length}`;
      rows.push({ id, kind: args.kind, agentStep: step, key: args.key, model: args.model, job: args.job });
      return { id, replay: false, status: "pending", output: null };
    },
    async finish(token, id, result: Finish) {
      finished.push({ token, id, ...result });
      const row = rows.find((r) => r.id === id);
      if (row) row.finish = result;
    },
    async markBatched(ids) {
      for (const row of rows) if (ids.includes(row.id)) row.batched = true;
    },
    async generation(_token, id) {
      const row = options.generations?.[id];
      return row ? { id, ...row } : null;
    },
  };
}
