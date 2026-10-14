/** The English number words a model writes for small counts ("five jumps", "eight of twelve"). */
const WORDS = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"];
const WORD = new RegExp(`\\b(${WORDS.join("|")})\\b`, "gi");

/** A number token in words or digits ("5", "five"), as a number; undefined for anything else. */
export function numberOf(token: string): number | undefined {
  const word = WORDS.indexOf(token.toLowerCase());
  if (word >= 0) return word;
  const digits = Number(token.replace(/[−–]/g, "-"));
  return Number.isFinite(digits) && /^[−–-]?\d+$/.test(token) ? digits : undefined;
}

/** Every number a text says, in digits or in the words zero to twelve, in order. A dash before digits is a sign only
 *  where no number or bracket comes before it ("land on −2", not "27 − 273"). */
export function numbersIn(text: string): number[] {
  const found: { at: number; value: number }[] = [];
  for (const m of text.matchAll(/([−–-]?)(\d+)/g)) {
    const at = m.index ?? 0;
    const before = text.slice(0, at).trimEnd().slice(-1);
    const signed = m[1] !== "" && !/[\d)\]]/.test(before);
    found.push({ at, value: Number(m[2]) * (signed ? -1 : 1) });
  }
  for (const m of text.matchAll(WORD)) found.push({ at: m.index ?? 0, value: WORDS.indexOf((m[1] ?? "").toLowerCase()) });
  return found.sort((a, b) => a.at - b.at).map((f) => f.value);
}

/** The pattern of one number token, digits or a word, for a rule that reads a count ("5 jumps", "five jumps"). */
export const NUMBER_TOKEN = `(\\d+|${WORDS.join("|")})`;
