import { expect, test } from "bun:test";
import cases from "../../tools/contract/plan-cases.json" with { type: "json" };
import { addingBriefs, naming, planRules } from "../src/plan/rules.js";
import type { PlanDraft, PlanInput } from "../src/plan/types.js";

// The shared plan cases (D80): written from Domain's PlanRules; the port must make the same draft of each.
type Case = { name: string; input: PlanInput; expected: PlanDraft; named?: { topics: Record<string, { chapter: string; skill: string }>; briefChapters: string[]; expected: PlanDraft } };
const all = (cases as unknown as { cases: Case[] }).cases;

test("the case file holds the cases", () => {
  expect(all.length).toBeGreaterThanOrEqual(25);
});

for (const c of all) {
  test(`case: ${c.name}`, () => {
    const draft = planRules(c.input);
    expect(draft).toEqual(c.expected);
    if (c.named) {
      const topics = new Map(Object.entries(c.named.topics).map(([k, v]) => [Number(k), v] as const));
      expect(addingBriefs(naming(draft, topics), new Set(c.named.briefChapters))).toEqual(c.named.expected);
    }
  });
}
