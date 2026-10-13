import { str } from "./typst.js";

/** A text split into words and formulae (D102): `$$…$$` a display formula, `$…$` an inline one, `\$` a dollar; a `$`
 *  with no partner is a word, so a slip never hides a question; a `\text{…}` holding letters outside ASCII is lifted out
 *  as words (no maths font draws Devanagari or Kannada). The iPhone's MathSplit keeps the same rules
 *  (tools/contract/maths-cases.json). */
export type Run = { kind: "text"; text: string } | { kind: "inline"; text: string } | { kind: "display"; text: string };

export function splitMaths(source: string): Run[] {
  const runs: Run[] = [];
  const word = (text: string) => {
    if (!text) return;
    const last = runs.at(-1);
    if (last?.kind === "text") last.text += text;
    else runs.push({ kind: "text", text });
  };
  const formula = (kind: "inline" | "display", latex: string) => {
    for (const part of liftWords(latex)) {
      if (part.kind === "text") word(part.text);
      else if (part.text.trim()) runs.push({ kind, text: part.text });
    }
  };
  let i = 0;
  let pending = "";
  while (i < source.length) {
    if (source.startsWith("\\$", i)) {
      pending += "$";
      i += 2;
      continue;
    }
    if (source[i] !== "$") {
      pending += source[i];
      i += 1;
      continue;
    }
    const display = source.startsWith("$$", i);
    const open = display ? 2 : 1;
    const close = display ? source.indexOf("$$", i + 2) : nextDollar(source, i + 1);
    const latex = close === -1 ? "" : source.slice(i + open, close);
    if (close === -1 || !latex.trim()) {
      // No partner, or nothing between: the rest is words as written.
      pending += source.slice(i);
      break;
    }
    word(pending);
    pending = "";
    formula(display ? "display" : "inline", latex);
    i = close + open;
  }
  word(pending);
  return runs;
}

/** The next `$` that is not escaped. */
function nextDollar(source: string, from: number): number {
  for (let j = from; j < source.length; j++) {
    if (source[j] === "\\") j += 1;
    else if (source[j] === "$") return j;
  }
  return -1;
}

/** A formula's `\text{…}` runs whose letters are outside ASCII, lifted out as words; the rest stays maths. */
function liftWords(latex: string): Run[] {
  const parts: Run[] = [];
  const pattern = /\\text\{([^{}]*)\}/g;
  let at = 0;
  for (const match of latex.matchAll(pattern)) {
    const inner = match[1] ?? "";
    if (/^[\x00-\x7F]*$/.test(inner)) continue;
    parts.push({ kind: "inline", text: latex.slice(at, match.index) });
    parts.push({ kind: "text", text: inner });
    at = (match.index ?? 0) + match[0].length;
  }
  parts.push({ kind: "inline", text: latex.slice(at) });
  return parts;
}

/** A formula's edge spaces as word spaces (a renderer drops spaces at a formula's edges, so "3 सेब + 2" lost its gaps):
 *  a space is added where the words beside it have none. The phone's MathText does the same. */
export function spaced(runs: Run[]): Run[] {
  const out: Run[] = [];
  runs.forEach((run, i) => {
    if (run.kind !== "inline") {
      out.push(run);
      return;
    }
    const before = out.at(-1);
    const after = runs[i + 1];
    if (/^\s/.test(run.text) && before && !(before.kind === "text" && /\s$/.test(before.text))) out.push({ kind: "text", text: " " });
    out.push({ kind: "inline", text: binary(run.text.trim()) });
    if (/\s$/.test(run.text) && after && !(after.kind === "text" && /^\s/.test(after.text))) out.push({ kind: "text", text: " " });
  });
  return out;
}

/** A formula that opens or closes on an operator, beside words, kept an operator with its spaces: Typst reads a
 *  leading `+` as a sign (and TeX's empty group does not change that), so it goes in `\mathbin` (`\mathrel` for a
 *  relation). The phone's MathText uses the empty group, which SwiftMath honours. */
const OPERATOR = "(\\+|-|−|=|<|>|\\\\times|\\\\pm|\\\\div|\\\\cdot)";
const wrap = (op: string) => (/^[=<>]$/.test(op) ? `\\mathrel{${op}}` : `\\mathbin{${op}}`);
function binary(latex: string): string {
  return latex.replace(new RegExp(`^${OPERATOR}`), (op) => wrap(op)).replace(new RegExp(`${OPERATOR}$`), (op) => wrap(op));
}

/** The text as Typst markup: words as string literals, inline maths through mitex's `#mi`, a display formula through
 *  `#mitex`, each ended by `;`. With maths off, the formulae are written as their words (the fallback when Typst cannot
 *  draw one). */
export function typstOf(text: string, options: { maths?: boolean } = {}): string {
  const runs = spaced(splitMaths(text));
  if (options.maths === false) return `#${str(splitMaths(text).map((r) => r.text).join(""))};`;
  return runs.map((r) => (r.kind === "text" ? `#${str(r.text)};` : r.kind === "inline" ? `#mi(${str(r.text)});` : `#mitex(${str(r.text)});`)).join("");
}
