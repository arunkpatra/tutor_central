import { modelName } from "./models";

/** The cost page's words (P19-Cost). */
export const COST = {
  title: "Cost",
  lead: "What the AI service cost, priced from models.json at each call’s finish (D67), against each centre’s allowance and the ₹499 a month of D64.",
  month: "Month",
  centre: "Centre",
  all: "All",
  tiles: {
    month: "this month, all centres",
    perCentre: "per active centre",
    today: "today",
    share: "of ₹499, the average centre",
  },
  byDay: (centre: string | null) => (centre ? `By day, ${centre}` : "By day, all centres"),
  line: (month: string) => `${month} · the alert line is ₹60 a day for one centre`,
  split: "By centre, and by kind and model",
  splitLead:
    "The cost runs of Phases 12 to 15, standing. A centre over its allowance is refused at the gate, not here.",
  centreHead: { centre: "Centre", calls: "Calls", cost: "Cost", perStudent: "Per student", share: "Of ₹499" },
  kindHead: { kind: "Kind", model: "Model", calls: "Calls", cost: "Cost", share: "Share" },
  rest: "the rest",
  restModels: "by models.json",
} as const;

/** A centre's day over this is over the alert line (D95's cost_day), in paise. */
export const DAY_LINE_PAISE = 6_000;

export type KindRow = { kind: string; models: string; calls: number; paise: number };

/** The kinds with their models merged ("Sonnet 5.5 · Haiku 5.5"), the costliest first; past `keep`, "the rest". */
export function kindRows(
  rows: { kind: string; model: string; calls: number; paise: number }[],
  keep: number,
): KindRow[] {
  const byKind = new Map<string, { models: string[]; calls: number; paise: number }>();
  for (const r of [...rows].sort((a, b) => b.paise - a.paise)) {
    const k = byKind.get(r.kind) ?? { models: [], calls: 0, paise: 0 };
    if (!k.models.includes(modelName(r.model))) k.models.push(modelName(r.model));
    k.calls += r.calls;
    k.paise += r.paise;
    byKind.set(r.kind, k);
  }
  const all = [...byKind]
    .map(([kind, k]) => ({ kind, models: k.models.join(" · "), calls: k.calls, paise: k.paise }))
    .sort((a, b) => b.paise - a.paise);
  if (all.length <= keep + 1) return all;
  const tail = all.slice(keep);
  return [
    ...all.slice(0, keep),
    {
      kind: COST.rest,
      models: COST.restModels,
      calls: tail.reduce((s, r) => s + r.calls, 0),
      paise: tail.reduce((s, r) => s + r.paise, 0),
    },
  ];
}
