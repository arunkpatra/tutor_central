import type { AIKind, V1Kind } from "./db.js";
import { first } from "./prompts/message.js";

/** The one answer shape for a failure: a status the app maps to its board's words, and the words themselves. */
export type ApiError = { status: 400 | 401 | 403 | 409 | 413 | 422 | 429 | 502 | 503; body: Record<string, unknown> };

const REFUSED: Partial<Record<AIKind, string>> = {
  scan_register: "Couldn't read this photo. Try another.",
  check_paper: "Couldn't check these pages. Try clearer photos.",
  parse_textbook: "Couldn't read the chapters from this photo. Try a flatter, brighter one.",
  figure: "Couldn't draw a figure for this skill. The plan goes on without it.",
  parse_school: "Couldn't find a test, homework, notice or holiday in this. Add it by hand.",
  mock: "Couldn't set a mock for these portions. The plan goes on without it.",
  read_marks: "Couldn't read any marks from this photo. Try a flatter, brighter one.",
  note: "Couldn't write this message. Try again.",
  can_do: "Couldn't write this message. Try again.",
  not_on_track: "Couldn't write this message. Try again.",
  test_tomorrow: "Couldn't write this message. Try again.",
};
const V1_KINDS: readonly AIKind[] = ["paper", "homework", "worksheet", "progress_note", "scan_register", "check_paper"] satisfies V1Kind[];

export const errors = {
  /** The centre's notice (V1's photos), or a named student's parent (D62): each in its own words. */
  consent: (): ApiError => ({ status: 403, body: { error: "Agree to the notice before the first photo.", reason: "consent" } }),
  studentConsent: (studentName?: string): ApiError => ({
    status: 403,
    body: { error: studentName ? `${first(studentName)}'s parent hasn't agreed yet.` : "The parent hasn't agreed yet.", reason: "student_consent" },
  }),
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
  /** A kind switched off in ai_models (D100): before any call or row. Task 7 gives it the board's words. */
  paused: (kind: AIKind): ApiError => ({ status: 503, body: { error: REFUSED[kind] ?? "Couldn't make this one. Try again later.", reason: "paused" } }),
  service: (): ApiError => ({ status: 502, body: { error: "The AI service didn't answer. Try again." } }),
  badImage: (why: string): ApiError => ({ status: 400, body: { error: why } }),
  /** The same key's call is still running (D84): the app's timed-out words; it may finish and replay. */
  inProgress: (): ApiError => ({ status: 409, body: { error: "That took too long to come back. Try again in a minute.", reason: "in_progress" } }),
  /** The same key with another body (D84): nothing paid; the app's service words. */
  keyReused: (): ApiError => ({ status: 409, body: { error: "The AI service didn't answer. Try again.", reason: "key_reused" } }),
  /** 20 calls a minute per user, or 60 per address (src/request.ts). */
  rate: (): ApiError => ({ status: 429, body: { error: "Too many requests in a minute. Try again shortly.", reason: "rate" } }),
  /** A body past 4.4 MB, before Vercel's own 4.5 MB would answer in its words: the app's words for too many pages. */
  tooLarge: (): ApiError => ({ status: 413, body: { error: "That's too many pages. Up to six, and try sharper, smaller photos." } }),
};
