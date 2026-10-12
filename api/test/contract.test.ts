import { expect, test } from "bun:test";
import { SAMPLE } from "../src/claude-fake.js";
import { contract, samples } from "../src/contract.js";

test("the contract reads the limits from the schemas", () => {
  const { limits } = contract();
  expect(limits).toMatchObject({
    tutorSaysMax: 300,
    sheetSkillsMax: 6,
    checkSkillsMax: 3,
    pagesMax: 6,
    imageBase64Max: 4_000_000,
    bodyBase64Max: 4_200_000,
    planGroupsMax: 3,
    gapDaysMax: 3,
    gapSkillsMax: 12,
    gapNoteLength: 300,
    noteTaughtMax: 6,
    noteItemLength: 200,
    canDoMax: 4,
    canDoLength: 80,
    canDoAtHomeLength: 160,
    readMarksPagesMax: 2,
    readMarksSubjectsMax: 12,
    subjectLength: 80,
  });
  for (const [name, value] of Object.entries(limits) as [string, number][]) expect({ name, integer: Number.isInteger(value) && value > 0 }).toEqual({ name, integer: true });
});

test("the contract lists the event kinds and the error reasons", () => {
  const { lists } = contract();
  expect(lists.eventKinds).toEqual(["app_opened", "signed_in", "signed_out", "tab_opened", "link_opened"]);
  expect(lists.errorReasons).toContain("key_reused");
  expect(lists.errorReasons).toContain("rate");
});

test("there is a sample answer for every kind the fake answers", () => {
  expect(Object.keys(samples()).sort()).toEqual(Object.keys(SAMPLE).sort());
});
