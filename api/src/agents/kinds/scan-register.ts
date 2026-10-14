import type { DecodedImage } from "../../images.js";
import { normalisePhone, request } from "../../prompts/scan-register.js";
import type { ScanOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric } from "./rubric.js";

export type ScanRegisterAgentInput = { image: DecodedImage };

/** Each word of a name starting with a capital, as written ("D'Souza" and "Mary-Ann" keep their own). */
const capitalised = (name: string) => name.trim().split(/\s+/).every((word) => !/^\p{Ll}/u.test(word));

/** A register page read into rows (Make's V1, Scan register): every row a name, each word capitalised; a phone a number
 *  `normalisePhone` reads (+91 and ten digits), or none; what is kept has the phones normalised. A page with no names
 *  answers no rows. */
export const scanRegister: Kind<ScanRegisterAgentInput, ScanOutput> = {
  kind: "scan_register",
  draft: (input) => request(input.image),
  verify: (_input, draft) => {
    const findings: Finding[] = [];
    draft.rows.forEach((row, i) => {
      const at = `row ${i + 1}`;
      if (!row.name.trim()) {
        findings.push({ item: at, problem: `${at} has no name` });
        return;
      }
      if (!capitalised(row.name)) findings.push({ item: at, problem: `${at}'s name is not capitalised word by word` });
      if (row.phone?.trim() && normalisePhone(row.phone) === null) findings.push({ item: at, problem: `${at}'s phone is not a ten-digit number: null when it cannot be read` });
    });
    return findings;
  },
  keep: (parsed) => ({ rows: parsed.rows.map((row) => ({ ...row, phone: normalisePhone(row.phone) })) }),
  rubric: rubric([
    "Every row of the register that is a person, in the order on the page, none twice; no heading, total, date or blank row.",
    "Each name as written, capitalised word by word; a phone's digits as read from the page, spaces as written (the app keeps it as +91 and the ten digits), or none when there is none or it cannot be read; a fee in whole rupees, or none.",
  ]),
};
