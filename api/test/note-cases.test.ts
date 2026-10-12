import { expect, test } from "bun:test";
import cases from "../../tools/contract/note-cases.json" with { type: "json" };
import { canDoFacts, isLadderNote, type NoteRecord, noteFacts, noteTopic } from "../src/notes/week.js";

// The shared note-week cases (D80): written from Domain's NoteWeek and CanDoWeek; the note day's job writes from the
// same facts the phone did.
const all = (cases as unknown as { cases: { name: string; input: NoteRecord & { from: string; to: string }; expected: { facts: unknown; topic?: string; isLadder: boolean; canDo?: unknown } }[] }).cases;

test("the case file holds the cases", () => {
  expect(all.length).toBeGreaterThanOrEqual(14);
});

for (const c of all) {
  test(`note week: ${c.name}`, () => {
    const week = { from: c.input.from, to: c.input.to };
    const facts = noteFacts(c.input, week);
    expect(facts).toEqual(c.expected.facts as never);
    expect(noteTopic(facts, c.input.chapters, c.input.skills)).toEqual(c.expected.topic as never);
    const ladder = isLadderNote(c.input.student, c.input.chapters);
    expect(ladder).toBe(c.expected.isLadder);
    expect(ladder ? canDoFacts(c.input.chapters, c.input.skills, week) : undefined).toEqual(c.expected.canDo as never);
  });
}
