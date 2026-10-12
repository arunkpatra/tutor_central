import { type AIKind, type Db, DbFailure, type Finish, type Started } from "./db.js";

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
): Db & { started: unknown[]; finished: unknown[] } {
  const consent = options.consent ?? true;
  const limit = options.limit ?? 40;
  const started: unknown[] = [];
  const finished: unknown[] = [];
  return {
    started,
    finished,
    async startCall(token, args): Promise<Started> {
      if (!consent && CONSENT_KINDS.includes(args.kind)) throw new DbFailure("consent");
      const refused = typeof options.studentConsent === "object" ? args.student !== undefined && options.studentConsent[args.student] === false : options.studentConsent === false;
      if (args.student && refused) throw new DbFailure("student_consent");
      if (args.key && options.keyReused?.includes(args.key)) throw new DbFailure("key_reused");
      const replay = args.key ? options.replays?.[args.key] : undefined;
      if (replay) return { ...replay, replay: true };
      if (started.length >= limit) throw new DbFailure("limit", limit);
      started.push({ token, ...args });
      return { id: `gen-${started.length}`, replay: false, status: "pending", output: null };
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
