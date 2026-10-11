import type { ClaudeRequest } from "../claude.js";
import type { DecodedImage } from "../images.js";
import { modelFor } from "../models.js";
import { ReadMarksOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** Marks read from a photo of a printed report card or a marked test (P14-Marks-Reading): one row per subject's test,
 *  which the tutor checks before anything is kept. A work type of its own, apart from marking a paper (D67). */
export function request(pages: DecodedImage[], studentName: string, subjects: string[]): ClaudeRequest<ReadMarksOutput> {
  return {
    model: modelFor("read_marks"),
    effort: "medium",
    system: [
      VOICE,
      "You read a printed school report card or a marked test paper photographed by a tutor.",
      "Give one row per subject's test you can read: the subject as printed (matched to the tutor's subject names when one fits), the test's name, the date when printed (ISO, YYYY-MM-DD; null when none is printed), the score and the maximum.",
      "Leave out a row you cannot read; give none when the photo holds no marks. At most twelve rows; a test's name at most 120 characters.",
    ].join(" "),
    text: [
      `Student: ${studentName}.`,
      subjects.length > 0 ? `Subjects the student takes here: ${subjects.join(", ")}.` : "",
      "Read the marks on these pages.",
    ]
      .filter(Boolean)
      .join("\n"),
    images: pages.map((p) => ({ mediaType: p.mediaType, base64: p.base64 })),
    schema: ReadMarksOutput,
  };
}
