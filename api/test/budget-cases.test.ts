import { expect, test } from "bun:test";
import cases from "../../tools/contract/budget-cases.json" with { type: "json" };
import { budget } from "../src/plan/budget.js";
import { examDay, type PrepItem, type PrepStudent } from "../src/plan/exam-prep.js";
import { planRules } from "../src/plan/rules.js";
import type { Chapter, PlanInput, Skill } from "../src/plan/types.js";

// The shared budget cases (D80; plan/phase-18-plan.md Task 9): written from Domain's ArtefactBudget, SpacedQueue and
// ExamPreparation; the port must ask for the same material and split each exam alike.
type BudgetCase = { name: string; input: { plan: PlanInput; now: string; briefsMade: string[]; mocksMade: string[] }; expected: unknown[] };
type SplitCase = {
  name: string;
  input: { items: PrepItem[]; student: PrepStudent; chapters: Chapter[]; skills: Skill[]; meetingDays: number[]; today: string };
  expected: unknown;
};
const file = cases as unknown as { cases: BudgetCase[]; splits: SplitCase[] };

test("the case file holds the cases", () => {
  expect(file.cases.length).toBeGreaterThanOrEqual(20);
  expect(file.splits.length).toBeGreaterThanOrEqual(15);
});

for (const c of file.cases) {
  test(`budget: ${c.name}`, () => {
    const draft = planRules(c.input.plan);
    const { students, chapters, skills, revisions } = c.input.plan;
    expect(budget(draft, { students, chapters, skills, revisions, now: c.input.now, briefsMade: c.input.briefsMade, mocksMade: c.input.mocksMade })).toEqual(
      c.expected as never,
    );
  });
}

for (const c of file.splits) {
  test(`exam split: ${c.name}`, () => {
    const { items, student, chapters, skills, meetingDays, today } = c.input;
    expect(examDay({ items, student, chapters, skills, meetingDays, today })).toEqual(c.expected as never);
  });
}
