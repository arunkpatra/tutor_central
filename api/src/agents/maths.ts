import type { Finding } from "./agent.js";

/** What is wrong with a text's mathematics (D102), or null: a `$` that opens a formula and never closes (`\$` is a
 *  dollar), or a formula whose braces do not close. The phone and the PDF show such a text as written, so the agent
 *  sends the draft back for repair rather than keep a stray dollar or a half-drawn formula. */
export function mathsProblem(text: string): string | null {
  const bare = text.replace(/\\\$/g, "");
  let i = 0;
  while (i < bare.length) {
    if (bare[i] !== "$") {
      i += 1;
      continue;
    }
    const display = bare.startsWith("$$", i);
    const open = display ? 2 : 1;
    const close = bare.indexOf(display ? "$$" : "$", i + open);
    if (close === -1) return "a formula opens with $ and never closes";
    if (!bracesClose(bare.slice(i + open, close))) return "a formula's braces do not close";
    i = close + open;
  }
  return null;
}

function bracesClose(latex: string): boolean {
  let depth = 0;
  for (let j = 0; j < latex.length; j++) {
    if (latex[j] === "\\") j += 1;
    else if (latex[j] === "{") depth += 1;
    else if (latex[j] === "}" && --depth < 0) return false;
  }
  return depth === 0;
}

/** Every string of a draft held to the rule, each finding named by where it is ("questions 1 answer"). */
export function mathsFindings(draft: unknown, at: string[] = []): Finding[] {
  if (typeof draft === "string") {
    const problem = mathsProblem(draft);
    return problem ? [{ item: at.join(" ") || "answer", problem }] : [];
  }
  if (Array.isArray(draft)) return draft.flatMap((value, index) => mathsFindings(value, [...at, String(index + 1)]));
  if (draft && typeof draft === "object") return Object.entries(draft).flatMap(([key, value]) => mathsFindings(value, [...at, key]));
  return [];
}
