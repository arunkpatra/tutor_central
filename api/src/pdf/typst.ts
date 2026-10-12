/** Typst source the PDFs share (D89). Every piece of text from a record or a model goes in as a string literal, never as
 *  markup: `#"…"` shows its characters as they are, so `#`, `$`, `*`, `//`, `--` or a leading `=` cannot become code,
 *  maths, a comment, a dash or a heading. */

/** A Typst string literal of the text. */
export function str(text: string): string {
  return `"${text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r?\n/g, "\\n")}"`;
}

/** The text as content in markup: `#"…"`. */
export const t = (text: string) => `#${str(text)}`;

/** The page and the type every PDF starts with: A4, 40 pt margins as the phone's PDFMaker, Noto Sans with Devanagari and
 *  Kannada beside it for a parent's language. `foot` is a line for the page's foot, `Page n of m` after it. */
export function preamble(foot?: string): string {
  const footer = foot === undefined ? "" : `, footer: context [#set text(8pt, fill: luma(110)); ${t(foot)} #h(1fr) Page #counter(page).display() of #counter(page).final().first()]`;
  return [
    `#set page(paper: "a4", margin: 40pt${footer})`,
    `#set text(font: ("Noto Sans", "Noto Sans Devanagari", "Noto Sans Kannada"), size: 11pt, fill: luma(20))`,
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
