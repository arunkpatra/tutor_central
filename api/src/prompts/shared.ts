import type { SystemBlocks } from "../claude.js";
import { SYLLABI } from "../generated/syllabi.js";

/** The voice every prompt shares: the tutor's own, for an Indian tuition centre. */
export const VOICE = [
  "You write for a tutor who runs a small tuition centre in India.",
  "Use Indian English and the idiom of CBSE and state-board classrooms; money is in rupees (₹).",
  "Sentence case, no exclamation marks, no emoji.",
  "Never invent facts about a student: use only what the tutor gives you.",
].join(" ");

export const LEVEL_WORDS = {
  easy: "easy: recall and one-step questions",
  medium: "medium: a mix of recall, application and a few multi-step questions",
  hard: "hard: mostly application and multi-step questions",
} as const;

/** A prompt's system words in two blocks (plan decision 5): `shared`, the kind's voice, rules and limits, the same for
 *  every request of the kind and class (so Claude caches it), and `own`, the words that change with the input. Empty
 *  parts are dropped. */
export function blocks(shared: (string | false | null | undefined)[], own: (string | false | null | undefined)[] = []): SystemBlocks {
  const words = (parts: (string | false | null | undefined)[]) => parts.filter((part): part is string => Boolean(part)).join(" ");
  return { shared: words(shared), own: words(own) };
}

/** Asked of the kinds whose answers can be numbers (D99): the server evaluates the proof (src/agents/arith.ts). */
export const PROOF = [
  "Where an answer is a number, give a proof: an arithmetic expression over numbers only (digits, + - * / ^, parentheses and sqrt) and the value it equals, so the answer can be checked by computation.",
  "For \"solve 3x + 5 = 20\" the answer is x = 5 and the proof is 3*5+5 equal to 20. The answer and its proof must agree.",
  "Where the answer is not a number, the proof is null.",
].join(" ");

/** Asked of the material's kinds (D102): the app and the PDFs draw a formula written this way; anything else is words. */
export const MATHS = [
  "Write mathematics in LaTeX inside the text: $…$ around a formula in a sentence (Solve $\\frac{x}{4} - 2 = 1$.), $$…$$ around a formula on a line of its own.",
  "Inside the dollars put only symbols, digits and letters that stand for numbers; keep every word outside the dollars, in the text's language, never inside \\text{}.",
  "Plain numbers and units in a sentence need no dollars (48 mangoes, 360 km); money is written as ₹40, never with a dollar sign.",
  "A subject without mathematics has no dollars.",
].join(" ");

/** Each kind's length limits in words (Phase 13: a model overruns a schema's limits unless the prompt states them),
 *  asked a little under what the schema in src/schemas.ts allows. */
export const LIMITS = {
  sheet: "The title is at most 100 characters; a question at most 600 characters; an answer at most 300 characters.",
  worked_example: "The problem is at most 280 characters; a step's title at most 70 and its working at most 360; the slip at most 280.",
  figure: "A label is at most 36 characters; the caption at most 180.",
  brief: "The paragraph about the chapter is at most 1,000 characters; a mistake's title at most 70 and how to catch it at most 280; each line to say at most 140; the worked example's problem at most 280, a step's title at most 70 and its working at most 360, its slip at most 280.",
  check: "A question is at most 250 characters.",
  placement: "A question is at most 250 characters.",
  mock: "The title is at most 100 characters; a question and an answer each at most 500 characters.",
  plan: "A chapter and a skill are each at most 120 characters.",
  parse_textbook: "The title and a chapter's name are each at most 180 characters; at most 40 chapters.",
  parse_school: "A title is at most 100 characters; at most 12 items.",
} as const;

const BOARDS: Record<string, string> = { cbse: "CBSE (NCERT)", karnataka: "the Karnataka state board" };
const SUBJECTS: Record<string, string> = { maths: "Mathematics", math: "Mathematics", "social studies": "Social Science", sst: "Social Science" };

/** The chapters a class reads in a subject, by board, from the syllabus data (supabase/syllabi, through bun contract), so
 *  a chapter or a level is named as the class's book names it; "" where the data has none (it covers classes 8 to 10). */
export function syllabusFacts(classLevel: string, subject: string): string {
  const key = subject.trim().toLowerCase();
  const name = SUBJECTS[key] ?? Object.keys(SYLLABI[classLevel] ?? {}).find((s) => s.toLowerCase() === key);
  const boards = name ? SYLLABI[classLevel]?.[name] : undefined;
  if (!boards) return "";
  const lines = Object.entries(boards).map(([board, chapters]) => `${BOARDS[board] ?? board}: ${chapters.join("; ")}.`);
  return [
    `For reference, the chapters of class ${classLevel} ${name} in the current books, by board (the centre follows one; a tutor may name a chapter by an older book's title):`,
    ...lines,
    "Take the chapter or skill as the tutor names it; never comment on this list or on how a book names its chapters.",
  ].join(" ");
}
