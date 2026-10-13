import type { ClaudeRequest } from "../claude.js";
import type { DecodedImage } from "../images.js";
import { modelFor } from "../models.js";
import { type ClassLevel, TextbookOutput } from "../schemas.js";
import { VOICE, blocks, LIMITS } from "./shared.js";

/** The prompt's version (D74): raised with any change to its words; `bun prompts --check` holds it. */
export const VERSION = "2";

/** One photographed contents page read into chapters, each with the skills a tutor teaches and checks (D58: names
 *  only, nothing from inside the book). */
export function request(image: DecodedImage, classLevel: ClassLevel, subject: string): ClaudeRequest<TextbookOutput> {
  return {
    model: modelFor("parse_textbook", "draft", classLevel).model,
    effort: "medium",
    version: VERSION,
    system: blocks([
      VOICE,
      "You read photographs of a school textbook's contents page.",
      "Return the chapter names as printed, in the book's order, and the book's title if the page shows it.",
      "Under each chapter give two to eight skills: what a student can do after that chapter, each a short phrase of at most ten words, taken from the section headings on the page.",
      "Give only chapter names and skill phrases; never copy sentences, exercises or page text.",
      "Skip prefaces, acknowledgements, answer keys and appendices. If nothing on the page is a chapter, return no chapters.",
      LIMITS.parse_textbook,
    ]),
    text: `Read this contents page of a class ${classLevel} ${subject} textbook.`,
    images: [{ mediaType: image.mediaType, base64: image.base64 }],
    schema: TextbookOutput,
  };
}
