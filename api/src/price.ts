import { createHash } from "node:crypto";
import table from "../models.json" with { type: "json" };

type Prices = Record<string, { inputUsdPerMillion: number; outputUsdPerMillion: number }>;

/** What a call cost in paise, priced by api/models.json at finish (D76): the same arithmetic as `bun cost`. null when the
 *  model is not in the table or no tokens came back. */
export function costPaise(model: string, tokensIn: number | null, tokensOut: number | null): number | null {
  const price = (table.models as Prices)[model];
  if (!price || tokensIn === null || tokensOut === null) return null;
  const dollars = (tokensIn * price.inputUsdPerMillion + tokensOut * price.outputUsdPerMillion) / 1_000_000;
  return Math.round(dollars * table.rupeesPerDollar * 100);
}

/** The prompt's identity on its row: the SHA-256 of its system words (a version arrives with Phase 20's prompts). */
export function promptHash(system: string): string {
  return sha256(system);
}

export function sha256(text: string): string {
  return createHash("sha256").update(text).digest("hex");
}
