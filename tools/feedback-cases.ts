#!/usr/bin/env bun
/** bun feedback-cases [--since 30d] [--kinds note,sheet]: the tutors' feedback (D107) as candidate golden cases. Reads
 *  `generation_feedback` with its call's input from production through `supabase db query --linked` (the session's, D87),
 *  puts the seed's names in place of every name the input carries (by position), drops phone numbers and ids, and prints
 *  one candidate a row as JSON with the reason and the revised text's length, never the revised text (a parent's
 *  message, a tutor's note). A candidate joins a golden set by hand (D55: no tutor's name or number in the repository). */
import { sh } from "./lib/sh";

/** The seed's names, given in turn to the names a call's input carries. */
export const SEED_NAMES = ["Dev Kumar", "Meher Shah", "Nikhil Das", "Hemanth Reddy", "Riya Sharma", "Akshita Rao", "Ramesh Kumar", "Lakshmi Reddy"];

export type FeedbackRow = {
  feedback_kind: string;
  reason: string | null;
  revised_length: number | null;
  kind: string;
  created_at: string;
  input: Record<string, unknown>;
};
export type Candidate = { kind: string; input: Record<string, unknown>; feedback: { kind: string; reason: string | null; revisedLength?: number }; expect: Record<string, never> };

const KIND = /^[a-z_]{1,40}$/;
const UUID = /\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi;
/** A phone number as a person writes one: ten digits or more with spaces, dashes or a + among them. */
const PHONE = /\+?\d[\d\s-]{8,}\d/g;
const NAME_KEY = /name$/i;
const DROPPED_KEY = /(^id$|Id$|_id$|phone)/i;

/** Every name the input carries in a `…Name` key, in order, each once. */
function namesOf(value: unknown, found: string[] = []): string[] {
  if (Array.isArray(value)) for (const v of value) namesOf(v, found);
  else if (value && typeof value === "object") {
    for (const [key, v] of Object.entries(value)) {
      if (NAME_KEY.test(key) && typeof v === "string" && v.trim() && !found.includes(v.trim())) found.push(v.trim());
      else namesOf(v, found);
    }
  }
  return found;
}

/** The input with the seed's names in place (whole names, then each one's words), ids and numbers dropped. */
function scrubbed(value: unknown, swap: (text: string) => string): unknown {
  if (typeof value === "string") return swap(value).replace(UUID, "").replace(PHONE, "").replace(/\s{2,}/g, " ").trim();
  if (Array.isArray(value)) return value.map((v) => scrubbed(v, swap));
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).filter(([key]) => !DROPPED_KEY.test(key)).map(([key, v]) => [key, scrubbed(v, swap)]));
  }
  return value;
}

export function candidate(row: FeedbackRow): Candidate {
  const names = namesOf(row.input);
  const map = new Map<string, string>();
  names.forEach((name, i) => map.set(name, SEED_NAMES[i % SEED_NAMES.length] as string));
  // A first or last name alone in the text ("Aarav got 14 of 20") takes the seed's first name; a whole name wins.
  names.forEach((name, i) => {
    for (const word of name.split(/\s+/)) if (word.length > 1 && !map.has(word)) map.set(word, (SEED_NAMES[i % SEED_NAMES.length] as string).split(" ")[0] as string);
  });
  const escape = (t: string) => t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = map.size ? new RegExp(`\\b(${[...map.keys()].sort((a, b) => b.length - a.length).map(escape).join("|")})\\b`, "g") : null;
  // One pass, so a seed name put in place is never replaced again.
  const swap = (text: string) => (pattern ? text.replace(pattern, (found) => map.get(found) ?? found) : text);
  const input = scrubbed(row.input, swap) as Record<string, unknown>;
  const feedback = { kind: row.feedback_kind, reason: row.reason, ...(row.revised_length !== null ? { revisedLength: row.revised_length } : {}) };
  return { kind: row.kind, input, feedback, expect: {} };
}

/** The feedback of the last `days` days with its call's kind and input; the revised text's length alone. */
export function feedbackSql(days: number, kinds: string[]): string {
  if (!Number.isInteger(days) || days < 1 || days > 365) throw new Error("--since is 1d to 365d");
  for (const kind of kinds) if (!KIND.test(kind)) throw new Error(`"${kind}" is not a kind`);
  const only = kinds.length ? ` and g.kind::text in (${kinds.map((k) => `'${k}'`).join(", ")})` : "";
  return `select f.kind as feedback_kind, f.reason, length(f.revised::text) as revised_length, g.kind::text as kind, g.input, f.created_at
  from public.generation_feedback f join public.ai_generations g on g.centre_id = f.centre_id and g.id = f.generation_id
 where f.created_at > now() - interval '${days} days'${only}
 order by f.created_at`;
}

function arg(name: string): string | undefined {
  const at = process.argv.indexOf(name);
  return at === -1 ? undefined : process.argv[at + 1];
}

if (import.meta.main) {
  const days = Number((arg("--since") ?? "30d").replace(/d$/, ""));
  const kinds = (arg("--kinds") ?? "").split(",").filter(Boolean);
  const r = await sh(["supabase", "db", "query", "--linked", "--output-format", "json", feedbackSql(days, kinds)], { cwd: `${import.meta.dir}/../supabase` });
  if (r.code !== 0) throw new Error(`the query failed: ${r.stderr.slice(0, 300)}`);
  const answer = JSON.parse(r.stdout) as FeedbackRow[] | { rows: FeedbackRow[] };
  const rows = Array.isArray(answer) ? answer : answer.rows;
  for (const row of rows) console.log(JSON.stringify(candidate(row)));
  console.error(`${rows.length} candidates`);
}
