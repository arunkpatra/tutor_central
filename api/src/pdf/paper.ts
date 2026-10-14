import type { PaperOutput, QuestionSetOutput } from "../schemas.js";
import { heading, numbered, preamble, subtitle, t, title } from "./typst.js";

/** A V1 result to print: a paper, or homework or a worksheet. */
export type V1Result = { kind: "paper"; output: PaperOutput } | { kind: "homework" | "worksheet"; output: QuestionSetOutput };

const marksEach = (marks: number) => (marks === 1 ? "1 mark each" : `${marks} marks each`);

/** A section's head (P21-PDF-Paper): its title in bold on the left, its marks each on the right, a rule under both. */
const sectionHead = (name: string, right: string) =>
  `#block(width: 100%, stroke: (bottom: 0.5pt + luma(200)), inset: (bottom: 6pt))[${heading(name)} #h(1fr) #text(9pt, fill: luma(110))[${t(right)}]]`;

/** A V1 result as the server prints it (P21-PDF-Paper; the phone's GenerationResult.pdfSheet): the title and its line, a
 *  paper's sections with their marks each and each question's marks, homework or a worksheet numbered with its
 *  instructions; with the key, the answers on a page of their own. */
export function paperPdf(result: V1Result, meta: { title: string; subtitle: string; foot?: string }, withKey: boolean): string {
  const parts = [preamble(meta.foot), title(meta.title), subtitle(meta.subtitle)];
  if (result.kind === "paper") {
    for (const section of result.output.sections) {
      parts.push("#v(14pt)", sectionHead(section.title, marksEach(section.marksEach)), "#v(6pt)", numbered(section.questions.map((q) => ({ number: q.number, text: q.text, marks: String(q.marks) })), true));
    }
  } else {
    if (result.output.instructions) parts.push("#v(6pt)", subtitle(result.output.instructions));
    parts.push("#v(14pt)", numbered(result.output.questions.map((q) => ({ number: q.number, text: q.text })), true));
  }
  if (withKey) {
    const questions = result.kind === "paper" ? result.output.sections.flatMap((s) => s.questions) : result.output.questions;
    parts.push("#pagebreak()", heading("Answer key"), "#v(8pt)", numbered(questions.map((q) => ({ number: q.number, text: q.answer }))));
  }
  return parts.join("\n\n");
}

/** The title and line of a V1 result's PDF from its request (P21-PDF-Paper): "Quadratic equations · question paper",
 *  "Class 10 · Mathematics · 20 marks"; the key printed unless a worksheet left it out (the phone's printsKey). */
export function paperMeta(kind: V1Result["kind"], input: Record<string, unknown>, output: { title: string }): { title: string; subtitle: string; withKey: boolean } {
  const name = { paper: "question paper", homework: "homework", worksheet: "worksheet" }[kind];
  const line = [input.classLevel, input.subject, kind === "paper" && typeof input.marks === "number" ? `${input.marks} marks` : null].filter((x): x is string => typeof x === "string" && x !== "");
  return { title: `${output.title} · ${name}`, subtitle: line.join(" · "), withKey: !(kind === "worksheet" && input.withAnswers === false) };
}
