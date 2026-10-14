import { createHash } from "node:crypto";
import table from "../models.json" with { type: "json" };
import type { SystemBlocks } from "./claude.js";

type Prices = Record<string, { inputUsdPerMillion: number; outputUsdPerMillion: number; cachedUsdPerMillion: number }>;

/** What a call cost in paise, priced by api/models.json at finish (D76): the same arithmetic as `bun cost`. `tokensIn` is
 *  the input billed at the full price or above, of which `tokensWritten` went into the cache at a quarter more (twice for the
 *  hour's, D108); a token read from the cache costs the model's own cached price (D109); `scale` 0.5 for a Message Batch (D101). null when the model is not in
 *  the table or no tokens came back. */
export function costPaise(model: string, tokensIn: number | null, tokensOut: number | null, tokensCached = 0, tokensWritten = 0, scale = 1, tokensWrittenHour = 0): number | null {
  const price = (table.models as Prices)[model];
  if (!price || tokensIn === null || tokensOut === null) return null;
  // A write to the five minutes' cache is a quarter over the input; to the hour's (a job's, D108), twice it.
  const fiveMinutes = tokensWritten - tokensWrittenHour;
  const input = (tokensIn - tokensWritten + fiveMinutes * 1.25 + tokensWrittenHour * 2) * price.inputUsdPerMillion;
  const dollars = (input + tokensCached * price.cachedUsdPerMillion + tokensOut * price.outputUsdPerMillion) / 1_000_000;
  return Math.round(dollars * scale * table.rupeesPerDollar * 100);
}

/** The prompt's identity on its row (D74): the SHA-256 of its shared and own system words. */
export function promptHash(system: SystemBlocks): string {
  return sha256(`${system.shared}\n${system.own}`);
}

export function sha256(text: string): string {
  return createHash("sha256").update(text).digest("hex");
}
