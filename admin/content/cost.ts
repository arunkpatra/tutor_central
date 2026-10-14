import { modelName } from "./models";

/** The cost page's words (P19-Cost; P21-Cost: by step, batched, by month). */
export const COST = {
  title: "Cost",
  lead: "What the AI service cost, priced from models.json at each call’s finish (D67), by kind, model and step and by month, against each centre’s allowance and the ₹499 a month of D64. Batched work is priced at half and marked.",
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
  split: "By centre, and by kind, model and step",
  splitLead:
    "The standing cost report (D74): a check, repair or grade is a row of its kind; the morning’s plans and the nightly evals are batched at half price. A centre over its allowance is refused at the gate, not here.",
  centreHead: { centre: "Centre", calls: "Calls", cost: "Cost", perStudent: "Per student", share: "Of ₹499" },
  kindHead: { kind: "Kind", step: "Step", model: "Model", calls: "Calls", cost: "Cost", share: "Share" },
  batched: "batch · ½",
  byMonth: "By month",
  byMonthLead:
    "Each month’s calls and cost, how much of it was batched at half price, and the average active centre against ₹499.",
  monthHead: {
    month: "Month",
    calls: "Calls",
    cost: "Cost",
    batched: "Batched",
    perCentre: "Per active centre",
    share: "Of ₹499",
  },
  rest: "the rest",
  restModels: "by models.json",
} as const;

/** A centre's day over this is over the alert line (D95's cost_day), in paise. */
export const DAY_LINE_PAISE = 6_000;

export type KindRow = { kind: string; step: string; batched: boolean; models: string; calls: number; paise: number };

const STEPS = ["draft", "check", "repair", "grade"];

/** The kinds by step, a batched row apart, with their models merged ("Sonnet 5.5 · Haiku 5.5"): the costliest kind
 *  first, its steps together in the agent's order (P21-Cost); past `keep`, "the rest". */
export function stepRows(
  rows: { kind: string; step: string; model: string; batched: boolean; calls: number; paise: number }[],
  keep: number,
): KindRow[] {
  const byStep = new Map<string, KindRow & { list: string[] }>();
  for (const r of [...rows].sort((a, b) => b.paise - a.paise)) {
    const key = `${r.kind}|${r.step}|${r.batched}`;
    const k = byStep.get(key) ?? {
      kind: r.kind,
      step: r.step,
      batched: r.batched,
      models: "",
      list: [],
      calls: 0,
      paise: 0,
    };
    if (!k.list.includes(modelName(r.model))) k.list.push(modelName(r.model));
    k.calls += r.calls;
    k.paise += r.paise;
    byStep.set(key, k);
  }
  const kindPaise = new Map<string, number>();
  for (const k of byStep.values()) kindPaise.set(k.kind, (kindPaise.get(k.kind) ?? 0) + k.paise);
  const place = (step: string) => (STEPS.includes(step) ? STEPS.indexOf(step) : STEPS.length);
  const all = [...byStep.values()]
    .map(({ list, ...k }) => ({ ...k, models: list.join(" · ") }))
    .sort(
      (a, b) =>
        (kindPaise.get(b.kind) ?? 0) - (kindPaise.get(a.kind) ?? 0) ||
        a.kind.localeCompare(b.kind) ||
        place(a.step) - place(b.step) ||
        Number(a.batched) - Number(b.batched),
    );
  if (all.length <= keep + 1) return all;
  const tail = all.slice(keep);
  return [
    ...all.slice(0, keep),
    {
      kind: COST.rest,
      step: "",
      batched: false,
      models: COST.restModels,
      calls: tail.reduce((s, r) => s + r.calls, 0),
      paise: tail.reduce((s, r) => s + r.paise, 0),
    },
  ];
}

const ordinal = (n: number) => {
  const tens = n % 100;
  if (tens >= 11 && tens <= 13) return `${n}th`;
  return `${n}${({ 1: "st", 2: "nd", 3: "rd" } as Record<number, string>)[n % 10] ?? "th"}`;
};

/** "October, to the 13th" for the month that holds today; "September" for one before it. */
export function monthLabel(first: string, today: string): string {
  const name = new Date(`${first}T12:00:00+05:30`).toLocaleDateString("en-GB", {
    timeZone: "Asia/Kolkata",
    month: "long",
  });
  return today.slice(0, 7) === first.slice(0, 7) ? `${name}, to the ${ordinal(Number(today.slice(8)))}` : name;
}
