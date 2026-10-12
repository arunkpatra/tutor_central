import { expect, test } from "bun:test";
import cases from "../../tools/contract/reminder-cases.json" with { type: "json" };
import { planReminders, type ReminderInput } from "../src/reminders/planner.js";

// The shared reminder cases (D80): written from Domain's ReminderPlanner; the server's plan says and times each
// reminder as the phone did.
const all = (cases as unknown as { cases: { name: string; input: ReminderInput & { now: string }; expected: unknown[] }[] }).cases;

test("the case file holds the cases", () => {
  expect(all.length).toBeGreaterThanOrEqual(16);
});

for (const c of all) {
  test(`reminders: ${c.name}`, () => {
    expect(planReminders(c.input, c.input.now)).toEqual(c.expected as never);
  });
}
