import { heading, numbered, preamble, subtitle, title } from "./typst.js";

/** A mock as kept: its sections and the pattern's marks and minutes, with the portions. */
export type MockContent = {
  title: string;
  duration_minutes: number;
  sections: { name: string; marks_each: number; questions: { number: number; text: string; marks: number; answer: string }[] }[];
  pattern: { marks: number; duration_minutes: number };
  portions: string[];
};

/** "Chemical reactions, acids and metals": the portions in a list's words (ListWords.and). */
export function listAnd(items: string[]): string {
  if (items.length <= 1) return items.join("");
  return `${items.slice(0, -1).join(", ")} and ${items.at(-1)}`;
}

const marksEach = (marks: number) => (marks === 1 ? "1 mark each" : `${marks} marks each`);

/** A mock as the phone draws it (MockStore.pdfSheet): the title, "40 marks · 60 minutes · <portions>", each section with
 *  its marks and questions; with the key, the answers on a page of their own. */
export function mockPdf(content: MockContent, meta: { title: string }, withKey: boolean): string {
  const head = `${content.pattern.marks} marks · ${content.pattern.duration_minutes} minutes`;
  const parts = [preamble(), title(meta.title), subtitle(content.portions.length ? `${head} · ${listAnd(content.portions)}` : head)];
  for (const section of content.sections) {
    parts.push("#v(14pt)", heading(`${section.name} · ${marksEach(section.marks_each)}`), "#v(6pt)", numbered(section.questions.map((q) => ({ number: q.number, text: q.text, marks: String(q.marks) })), true));
  }
  if (withKey) {
    const answers = content.sections.flatMap((s) => s.questions).map((q) => ({ number: q.number, text: q.answer }));
    parts.push("#pagebreak()", heading("Answer key"), "#v(8pt)", numbered(answers));
  }
  return parts.join("\n\n");
}
