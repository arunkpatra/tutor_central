import type { ClaudeRequest } from "../claude.js";
import type { DecodedImage } from "../images.js";
import { modelFor } from "../models.js";
import { type ClassLevel, ParseSchoolOutput } from "../schemas.js";
import { VOICE, blocks, LIMITS } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "2";

export type ParseSchoolSource = { text: string | null; image: DecodedImage | null; today: string; schools: string[]; classLevels: ClassLevel[] };

/** What the school sent read into items the tutor checks (plan decision 27): the kinds, the words as written, the dates
 *  resolved from today, a class and a school when named, a student only when the message is about one. */
export function request(source: ParseSchoolSource): ClaudeRequest<ParseSchoolOutput> {
  return {
    model: modelFor("parse_school", "draft", source.classLevels[0] ?? "8").model,
    effort: "medium",
    version: VERSION,
    system: blocks([
      VOICE,
      "You read a message or a photo a school sent to parents and list what it announces: exams (kind exam), homework the school set (homework), notices such as a PTM or a fee circular (notice), and holidays (holiday).",
      "One item per announcement. The title is short, in the school's own words (\"Science unit test 3\"). The subject only when one is named. The portions as written, shortened to 500 characters.",
      "Dates are ISO (YYYY-MM-DD), resolved from today's date and the school year; a date the message does not give is null, never guessed. A holiday's endDate is its last day; otherwise endDate is null.",
      "classLevel is the class named (VIII, 8th, Class 8 all mean \"8\"; LKG and UKG as such), else null. school is the school's name when the message names one of the schools given, else null. studentName is a student's name only when the message is about one student, else null.",
      "No item for a greeting or a signature. An empty list when nothing is announced.",
      LIMITS.parse_school,
    ]),
    text: [
      `Today is ${source.today}.`,
      source.schools.length ? `Schools: ${source.schools.join("; ")}.` : "",
      source.classLevels.length ? `Classes at the centre: ${source.classLevels.join(", ")}.` : "",
      source.image ? "Read what the school sent in the photo." : `What the school sent:\n${source.text}`,
    ].filter(Boolean).join("\n"),
    images: source.image ? [{ mediaType: source.image.mediaType, base64: source.image.base64 }] : undefined,
    schema: ParseSchoolOutput,
  };
}
