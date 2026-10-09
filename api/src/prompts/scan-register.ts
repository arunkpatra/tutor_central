import type { ClaudeRequest } from "../claude.js";
import type { DecodedImage } from "../images.js";
import { ScanOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** One photographed page of a paper register read into rows. Phones and fees as written; the API normalises. */
export function request(image: DecodedImage): ClaudeRequest<ScanOutput> {
  return {
    model: "claude-opus-5-5",
    effort: "high",
    system: [
      VOICE,
      "You read photographs of handwritten or printed student registers from tuition centres.",
      "Return every row of the table that is a person, in the order on the page, and no row twice.",
      "Name: as written, with each word capitalised. Phone: the digits as written, or null when there is none or it cannot be read.",
      "Fee: a whole number of rupees, or null when there is none. Skip headings, totals, dates and blank rows.",
      "If nothing on the page reads as a name, return no rows.",
    ].join(" "),
    text: "Read this register page.",
    images: [{ mediaType: image.mediaType, base64: image.base64 }],
    schema: ScanOutput,
  };
}

/** Digits only; ten digits starting 6 to 9 are an Indian mobile (+91), as are eleven with a trunk 0, twelve starting 91 and
 *  fourteen starting 0091 (what a register writes; the app's PhoneNumber reads the same); anything else is no number, never a
 *  wrong one. */
export function normalisePhone(raw: string | null): string | null {
  let digits = (raw ?? "").replace(/\D/g, "");
  if (digits.length === 14 && digits.startsWith("0091")) digits = digits.slice(4);
  else if (digits.length === 12 && digits.startsWith("91")) digits = digits.slice(2);
  else if (digits.length === 11 && digits.startsWith("0")) digits = digits.slice(1);
  return digits.length === 10 && /^[6-9]/.test(digits) ? `+91${digits}` : null;
}
