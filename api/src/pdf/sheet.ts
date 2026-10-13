import { heading, numbered, preamble, subtitle, title } from "./typst.js";

/** A sheet as kept (`artefacts.content` of a sheet): its questions with their answers. */
export type SheetContent = { title: string; instructions?: string | null; questions: { number: number; text: string; answer: string }[] };

/** A sheet as the phone's PDFMaker draws it (SheetStore.pdfSheet): the title, the instructions, the numbered questions
 *  each worth a mark with room to write; with the key, the answers on a page of their own. */
export function sheetPdf(content: SheetContent, meta: { title: string; foot?: string }, withKey: boolean): string {
  const parts = [preamble(meta.foot), title(meta.title)];
  if (content.instructions) parts.push(subtitle(content.instructions));
  parts.push("#v(14pt)", numbered(content.questions.map((q) => ({ number: q.number, text: q.text, marks: "1" })), true));
  if (withKey) parts.push("#pagebreak()", heading("Answer key"), "#v(8pt)", numbered(content.questions.map((q) => ({ number: q.number, text: q.answer }))));
  return parts.join("\n\n");
}
