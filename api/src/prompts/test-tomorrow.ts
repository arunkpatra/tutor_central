import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type TestTomorrowInput, TestTomorrowOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

const LANGUAGES = { en: "English", hinglish: "Hinglish", hi: "Hindi", kn: "Kannada" } as const;

/** "Thursday 8 October" from an ISO day, read as a calendar day (no time zone moves it). */
export function spokenDay(iso: string): string {
  const [y, m, d] = iso.split("-").map(Number);
  const day = new Date(Date.UTC(y ?? 2000, (m ?? 1) - 1, d ?? 1));
  const weekday = day.toLocaleDateString("en-GB", { weekday: "long", timeZone: "UTC" });
  const month = day.toLocaleDateString("en-GB", { month: "long", timeZone: "UTC" });
  return `${weekday} ${day.getUTCDate()} ${month}`;
}

const first = (name: string) => name.trim().split(/\s+/)[0] ?? name;

/** Test tomorrow in the parent's language (P10-TestTomorrow), with the English beside it for the tutor. The student
 *  is named, so the call needs their consent (start_ai_generation). */
export function request(input: TestTomorrowInput): ClaudeRequest<TestTomorrowOutput> {
  return {
    model: modelFor("test_tomorrow"),
    effort: "medium",
    system: [
      VOICE,
      "You write a short WhatsApp message from a tutor to a parent, in the language asked (Hindi in Devanagari, Kannada in Kannada script, Hinglish in Latin letters), saying the student's test is tomorrow, the portions, and one thing to go over this evening.",
      "Polite, four sentences at most, signed with the tutor's name and the centre on two lines.",
      "Also give the same message in English for the tutor to read.",
    ].join(" "),
    text: [
      `Language: ${LANGUAGES[input.language]}.`,
      `Student: ${first(input.studentName)}.`,
      input.parentName ? `Parent: ${first(input.parentName)}.` : "",
      `Test: ${input.title} (${input.subject}), ${spokenDay(input.date)}.`,
      input.portions ? `Portions: ${input.portions}.` : "",
      input.revise ? `To go over this evening: ${input.revise}.` : "",
      `Signed: ${input.tutorName}, ${input.centreName}.`,
    ].filter(Boolean).join("\n"),
    schema: TestTomorrowOutput,
  };
}
