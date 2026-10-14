import { LANGUAGES } from "../../prompts/message.js";
import type { Language, MessageOutput } from "../../schemas.js";
import type { Finding } from "../agent.js";
import { numbersIn } from "./numbers.js";

/** The share of a parent's message in their script that passes (D110): a word or two of English a parent expects ("unit
 *  test") stays within it. */
export const SCRIPT_SHARE = 0.85;

const SCRIPTS: Record<Language, RegExp> = {
  hi: /\p{Script=Devanagari}/u,
  kn: /\p{Script=Kannada}/u,
  hinglish: /\p{Script=Latin}/u,
  en: /\p{Script=Latin}/u,
};

/** The share of a text's letters (marks included: a Devanagari vowel sign is one) in the language's script; 1 for a text
 *  with no letters. */
export function scriptShare(text: string, language: Language): number {
  const letters = [...text].filter((c) => /[\p{L}\p{M}]/u.test(c));
  if (letters.length === 0) return 1;
  return letters.filter((c) => SCRIPTS[language].test(c)).length / letters.length;
}

/** Devanagari and Kannada digits as ASCII digits, so "८" is the facts' 8. */
function asciiDigits(text: string): string {
  return text.replace(/[०-९]/g, (d) => String(d.charCodeAt(0) - 0x0966)).replace(/[೦-೯]/g, (d) => String(d.charCodeAt(0) - 0x0CE6));
}

/** The numbers a message writes in digits (any script's); a number in words is never a finding ("one thing to go over"
 *  is no fact), and is matched against the facts only as they write it. */
function digitNumbers(text: string): number[] {
  const words = /\b(zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\b/gi;
  return numbersIn(asciiDigits(text).replace(words, " "));
}

/** A sign-off as the last sentence: a closing word with or without a name, in English, Hindi or Kannada, or a lone name
 *  after a dash. "Thank you." is a courtesy, not a sign-off. */
const SIGN_OFF = /^(?:(?:with\s+)?(?:warm|kind|best|warmest)?\s*(?:regards|wishes|sincerely|yours|cheers|love)\b|सादर|आपका|आपकी|भवदीय|ಇಂತಿ|ವಂದನೆಗಳೊಂದಿಗೆ|[-–—]\s*\p{L}+)/iu;

const plain = (text: string) => text.toLowerCase().replace(/\s+/g, " ").replace(/[.!?।]+$/u, "").trim();

/** The rules every parent's message shares (D110), free: the message in the parent's script and the English beside it in
 *  English; every number written in digits one the facts hold (the facts' words read as numbers too); no sign-off; the
 *  tutor's own words carried whole in the message or the English. */
export function messageFindings(
  input: { language: Language; studentName: string; parentName?: string; facts: string[]; tutorSays?: string },
  draft: MessageOutput,
): Finding[] {
  const findings: Finding[] = [];
  if (scriptShare(draft.message, input.language) < SCRIPT_SHARE) findings.push({ item: "script", problem: `the message is not written in ${LANGUAGES[input.language]}'s script` });
  if (scriptShare(draft.english, "en") < SCRIPT_SHARE) findings.push({ item: "english", problem: "the English beside the message is not in English" });
  const held = new Set(numbersIn(asciiDigits([...input.facts, input.tutorSays ?? ""].join("\n"))));
  const unheld = [...new Set([...digitNumbers(draft.message), ...digitNumbers(draft.english)])].filter((n) => !held.has(n));
  for (const n of unheld) findings.push({ item: "numbers", problem: `${n} is not in the facts` });
  const last = draft.message.split(/[.!?।\n]/u).map((s) => s.trim()).filter(Boolean).at(-1) ?? "";
  if (SIGN_OFF.test(last)) findings.push({ item: "sign-off", problem: "the message ends with a sign-off; the app adds the signature" });
  if (input.tutorSays) {
    const says = plain(input.tutorSays);
    if (!plain(draft.message).includes(says) && !plain(draft.english).includes(says)) findings.push({ item: "the tutor's words", problem: "the tutor's own words are not carried whole" });
  }
  return findings;
}

/** What every parent's message is held to by the check (D110), and a kind's own lines. */
export function messageRubric(own: string[]): string {
  return [
    "- Every fact comes from the request: no test, mark, date, chapter or event the request does not give. Every number in the message is one the request gives. Warm words that state no fact are not facts.",
    "- The message is in the language asked, in its script (Hindi in Devanagari, Kannada in Kannada script, Hinglish in Latin letters, English); the English beside it says the same thing.",
    "- Warm and polite to a parent, in plain words a parent reads easily; it never blames the student.",
    "- At most 500 characters, sentence case, no exclamation marks; no signature, name or sign-off at the end (the app adds the tutor's).",
    "- The tutor's own words, when the request gives them, are carried whole.",
    ...own.map((line) => `- ${line}`),
  ].join("\n");
}
