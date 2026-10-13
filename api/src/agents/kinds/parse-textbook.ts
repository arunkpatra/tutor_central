import type { DecodedImage } from "../../images.js";
import { request } from "../../prompts/parse-textbook.js";
import type { ClassLevel, TextbookOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { words } from "./rubric.js";

export type ParseTextbookInput = { image: DecodedImage; classLevel: ClassLevel; subject: string };

/** A contents page read (D58): a page with no chapters is refused before any check; a skill is a short phrase (asked at
 *  ten words; a little room). */
export const parseTextbook: Kind<ParseTextbookInput, TextbookOutput> = {
  kind: "parse_textbook",
  classLevel: (input) => input.classLevel,
  draft: (input) => request(input.image, input.classLevel, input.subject),
  empty: (draft) => draft.chapters.length === 0,
  verify: (_input, draft) =>
    draft.chapters.flatMap((c) => c.skills.filter((s) => words(s) > 14).map((s): Finding => ({ item: c.name, problem: `"${s.slice(0, 60)}" is a sentence, not a short skill`  }))),
  rubric: [
    "- The chapters are those printed on the page, with their names as printed, in the book's order; none is invented and none printed is left out.",
    "- Each skill is a short phrase of what a student can do, drawn from the page's section headings under its chapter (a heading turned into what a student does, such as 'Use the past perfect tense' from 'Past perfect tense', is right); nothing is added that the headings do not say, and nothing is copied from inside the book.",
    "- Prefaces, acknowledgements, answer keys and appendices are not chapters.",
  ].join("\n"),
};
