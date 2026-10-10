import type { AIKind, V1Kind } from "./db.js";

/** The one answer shape for a failure: a status the app maps to its board's words, and the words themselves. */
export type ApiError = { status: 400 | 401 | 403 | 422 | 429 | 502; body: Record<string, unknown> };

const REFUSED: Partial<Record<AIKind, string>> = {
  scan_register: "Couldn't read this photo. Try another.",
  check_paper: "Couldn't check these pages. Try clearer photos.",
  parse_textbook: "Couldn't read the chapters from this photo. Try a flatter, brighter one.",
};
const V1_KINDS: readonly AIKind[] = ["paper", "homework", "worksheet", "progress_note", "scan_register", "check_paper"] satisfies V1Kind[];

export const errors = {
  consent: (): ApiError => ({ status: 403, body: { error: "Agree to the notice before the first photo.", reason: "consent" } }),
  member: (): ApiError => ({ status: 403, body: { error: "sign in again", reason: "member" } }),
  /** V1's kinds have a daily limit; the V2 kinds share the centre's monthly allowance (migration 0013). */
  limit: (kind: AIKind, limit: number): ApiError => ({
    status: 429,
    body: {
      error: V1_KINDS.includes(kind) ? `You've made today's ${limit}. Try again tomorrow.` : `You've made this month's ${limit}. More next month.`,
      limit,
      kind,
    },
  }),
  refused: (kind: AIKind): ApiError => ({
    status: 422,
    body: { error: REFUSED[kind] ?? "Couldn't make this one. Change the topic and try again." },
  }),
  service: (): ApiError => ({ status: 502, body: { error: "The AI service didn't answer. Try again." } }),
  badImage: (why: string): ApiError => ({ status: 400, body: { error: why } }),
};
