import { heading, preamble, t, title } from "./typst.js";

/** A brief as kept. */
export type BriefContent = {
  about: string;
  mistakes: { title: string; how_to_catch: string }[];
  worked_example: { problem: string; steps: { title: string; working: string }[]; slip: string };
  words: string[];
};

/** A brief as the phone draws it (BriefStore.pdfSheet): the title, then what the chapter is about, three common mistakes,
 *  the worked example to use and the words to say. */
export function briefPdf(content: BriefContent, meta: { title: string }): string {
  const block = (head: string, lines: string[]) => ["#v(12pt)", heading(head), ...lines.map((l) => `#par[${t(l)}]`)].join("\n\n");
  return [
    preamble(),
    title(meta.title),
    block("What the chapter is about", [content.about]),
    block("Three common mistakes", content.mistakes.flatMap((m, i) => [`${i + 1}. ${m.title}`, m.how_to_catch])),
    block("The worked example to use", [
      content.worked_example.problem,
      ...content.worked_example.steps.flatMap((s, i) => [`${i + 1}. ${s.title}`, s.working]),
      content.worked_example.slip,
    ]),
    block("Words to say", content.words.map((w) => `"${w}"`)),
  ].join("\n\n");
}
