import { expect, test } from "bun:test";
import { SAMPLE } from "../src/claude-fake.js";
import table from "../models.json" with { type: "json" };
import { contract, portal, samples } from "../src/contract.js";

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

test("there is a sample answer for every kind the fake answers, and the note day's kept note", () => {
  expect(Object.keys(samples()).sort()).toEqual([...Object.keys(SAMPLE), "kept_note"].sort());
});

test("the kept note's week is an ISO day, as the app reads it", () => {
  expect(samples().kept_note).toMatchObject({ week_monday: "2026-10-05" });
});

test("the portal's contract: each work type's switched-off words as the tutor reads them, the golden sets' kinds, the prompts' versions", () => {
  const p = portal();
  expect(p.paused.brief).toBe("Briefs can't be made right now. Making briefs is switched off for a short while so we can fix something. Everything else works as usual. Try again later.");
  expect(p.paused.sheet_to_5).toBe(p.paused.sheet_from_6);
  expect(p.paused.sheet_to_5).toStartWith("Sheets can't be made right now.");
  expect(Object.keys(p.paused).sort()).toEqual(Object.keys(table.work).sort());
  expect(p.evalKinds).toContain("plan");
  expect(p.evalKinds).toContain("scan_register");
  expect(p.versions.brief).toMatch(/^\d+$/);
  expect(p.versions.sheet_to_5).toBe(p.versions.sheet_from_6);
});
