import { EVAL_KINDS } from "@/lib/generated/contract";

/** The kinds chosen in the address (or a form), kept to those with a golden set, in the sets' order. */
export function chosenKinds(raw: string | null | undefined): string[] {
  const asked = new Set((raw ?? "").split(",").map((k) => k.trim()));
  return EVAL_KINDS.filter((k) => asked.has(k));
}
