import type { Language } from "../schemas.js";

/** What the parents' messages share (Test tomorrow, the note, can-now-do, not on track): the language named for the
 *  model, the student's and parent's first names, a day in words, and the system words that hold the model to the facts,
 *  the length and no signature (the app appends the tutor's signature once, Domain's MessageSignature). */
export const LANGUAGES: Record<Language, string> = { en: "English", hinglish: "Hinglish", hi: "Hindi", kn: "Kannada" };

export const MESSAGE = [
  "You write a short WhatsApp message from a tutor to a parent, in the language asked (Hindi in Devanagari, Kannada in Kannada script, Hinglish in Latin letters, English in English).",
  "Use only the facts given; leave out any fact that is missing or empty, never invent one.",
  "Polite, warm, at most 500 characters, the English at most 700 characters, sentence case, no exclamation marks.",
  "Also give the same message in English for the tutor to read (for English, repeat it).",
  "End with the last sentence: no signature, no name, no sign-off (the app adds the signature).",
].join(" ");

export const first = (name: string) => name.trim().split(/\s+/)[0] ?? name;

/** "Thursday 8 October" from an ISO day, read as a calendar day (no time zone moves it). */
export function spokenDay(iso: string): string {
  const [y, m, d] = iso.split("-").map(Number);
  const day = new Date(Date.UTC(y ?? 2000, (m ?? 1) - 1, d ?? 1));
  const weekday = day.toLocaleDateString("en-GB", { weekday: "long", timeZone: "UTC" });
  const month = day.toLocaleDateString("en-GB", { month: "long", timeZone: "UTC" });
  return `${weekday} ${day.getUTCDate()} ${month}`;
}

/** "5 October" from an ISO day. */
export function spokenDate(iso: string): string {
  return spokenDay(iso).split(" ").slice(1).join(" ");
}

/** The lines every message names: the language, the student, the parent when given, the class. */
export function whoLines(input: { language: Language; studentName: string; parentName?: string; classLevel?: string }): string[] {
  return [
    `Language: ${LANGUAGES[input.language]}.`,
    `Student: ${first(input.studentName)}.`,
    input.parentName ? `Parent: ${first(input.parentName)}.` : "",
    input.classLevel ? `Class: ${input.classLevel === "lkg" || input.classLevel === "ukg" ? input.classLevel.toUpperCase() : input.classLevel}.` : "",
  ].filter(Boolean);
}
