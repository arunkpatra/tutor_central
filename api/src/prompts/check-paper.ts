import type { ClaudeRequest } from "../claude.js";
import type { AIKind } from "../db.js";
import type { DecodedImage } from "../images.js";
import { CheckOutput, PaperOutput, QuestionSetOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** A photographed answer sheet marked against the scheme: a suggested mark and a note for every question. */
export function request(pages: DecodedImage[], scheme: string, studentName: string): ClaudeRequest<CheckOutput> {
  return {
    model: "claude-opus-5-5",
    effort: "high",
    system: [
      VOICE,
      "You mark students' handwritten answer sheets against the tutor's marking scheme, as a careful tutor would.",
      "Give a mark for every question of the scheme, never more than the question's marks; 'of' is the question's marks.",
      "The text is the question in a few words. The note is one line saying what was right or wrong.",
      "A question with no answer on the pages gets 0 and the note 'Not attempted'.",
      "The summary is one line on what to work on. The marks are suggestions the tutor will check.",
    ].join(" "),
    text: [`Student: ${studentName}.`, "Marking scheme:", scheme, "Mark the answer sheet on these pages."].join("\n"),
    images: pages.map((p) => ({ mediaType: p.mediaType, base64: p.base64 })),
    schema: CheckOutput,
  };
}

/** The scheme text from a stored paper, homework or worksheet; null for any other kind or an output that no longer
 *  parses. */
export function schemeText(output: unknown, kind: AIKind): string | null {
  if (kind === "paper") {
    const paper = PaperOutput.safeParse(output);
    if (!paper.success) return null;
    const lines = paper.data.sections.flatMap((s) =>
      s.questions.map((q) => `Q${q.number} (${q.marks} ${q.marks === 1 ? "mark" : "marks"}) ${q.text} → ${q.answer}`),
    );
    return [paper.data.title, ...lines].join("\n");
  }
  if (kind === "homework" || kind === "worksheet") {
    const set = QuestionSetOutput.safeParse(output);
    if (!set.success) return null;
    return [set.data.title, ...set.data.questions.map((q) => `Q${q.number} ${q.text} → ${q.answer}`)].join("\n");
  }
  return null;
}
