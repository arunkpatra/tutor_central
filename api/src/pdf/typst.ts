import { typstOf } from "./maths.js";

/** Typst source the PDFs share (D89). Every piece of text from a record or a model goes in as a string literal, never as
 *  markup: `#"…"` shows its characters as they are, so `#`, `*`, `//`, `--` or a leading `=` cannot become code, a
 *  comment, a dash or a heading. A formula in `$…$` (D102) goes to mitex as a string too (`#mi("…")`), which draws it. */

/** A Typst string literal of the text. */
export function str(text: string): string {
  return `"${text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r?\n/g, "\\n")}"`;
}

/** The text as content in markup: its words as `#"…";`, its formulae through mitex (src/pdf/maths.ts). */
export const t = (text: string) => typstOf(text);

/** The page and the type every PDF starts with: A4, 40 pt margins as the phone's PDFMaker, Noto Sans with Devanagari and
 *  Kannada beside it for a parent's language. `foot` is a line for the page's foot, `Page n of m` after it. */
export function preamble(foot?: string): string {
  const footer = foot === undefined ? "" : `, footer: context [#set text(8pt, fill: luma(110)); ${t(foot)} #h(1fr) Page #counter(page).display() of #counter(page).final().first()]`;
  return [
    // mitex is vendored in the function's workspace (api/typst/mitex, D102): no package is fetched at render time.
    `#import "/typst/mitex/lib.typ": mi, mitex`,
    `#set page(paper: "a4", margin: 40pt${footer})`,
    `#set text(font: ("Noto Sans", "Noto Sans Devanagari", "Noto Sans Kannada"), size: 11pt, fill: luma(20))`,
    // STIX Two Math for formulae (the family of the phone's XITS Math); words inside a formula fall back to Noto.
    `#show math.equation: set text(font: ("STIX Two Math", "Noto Sans", "Noto Sans Devanagari", "Noto Sans Kannada"))`,
    // A formula in a line is drawn at the text's size, a fraction stacked full height, as the board draws it.
    `#show math.equation.where(block: false): it => math.display(it)`,
    `#set par(leading: 0.6em)`,
  ].join("\n");
}

export const title = (text: string) => `#text(20pt, weight: "bold")[${t(text)}]`;
export const subtitle = (text: string) => `#text(fill: luma(90))[${t(text)}]`;
export const heading = (text: string) => `#text(weight: "bold")[${t(text)}]`;

/** Numbered lines as the phone draws them: the number, the text, the marks on the right; room to write under each when
 *  asked. */
export function numbered(lines: { number: number; text: string; marks?: string }[], room = false): string {
  const cells = lines.flatMap((l) => [`text(fill: luma(90))[${t(`${l.number}.`)}]`, `[${t(l.text)}${room ? " #v(28pt)" : ""}]`, `text(9pt, fill: luma(110))[${t(l.marks ?? "")}]`]);
  return `#grid(columns: (auto, 1fr, auto), column-gutter: 8pt, row-gutter: 12pt, ${cells.join(", ")})`;
}
