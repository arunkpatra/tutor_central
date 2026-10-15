import { expect, test } from "bun:test";
import { type Figures, reportText } from "../src/report/text.js";

// Phase 22 (D115, P22-Weekly-Email): the weekly report's words, plain text, no name.
const week = (monday: string, f: Partial<Figures>): Figures => ({
  week_monday: monday,
  so_far: false,
  tutors_active: 0,
  closes: 0,
  plans_made: 0,
  plans_followed: 0,
  notes_sent: 0,
  made: 0,
  again: 0,
  make: 0,
  consent_given: 0,
  cost_paise: 0,
  per_active_tutor_paise: 0,
  ...f,
});
const board = {
  week: week("2026-10-06", {
    tutors_active: 3,
    closes: 12,
    plans_made: 14,
    plans_followed: 12,
    notes_sent: 9,
    made: 38,
    again: 6,
    make: 7,
    consent_given: 2,
    cost_paise: 21_400,
    per_active_tutor_paise: 7_100,
  }),
  before: week("2026-09-29", {
    tutors_active: 2,
    closes: 9,
    plans_made: 11,
    plans_followed: 9,
    notes_sent: 6,
    made: 31,
    again: 4,
    make: 5,
    consent_given: 1,
    cost_paise: 16_800,
    per_active_tutor_paise: 8_400,
  }),
  reasons: {
    again: [
      { reason: "harder", count: 2 },
      { reason: "shorter", count: 2 },
      { reason: "less about marks", count: 1 },
      { reason: "typed", count: 1 },
    ],
    edits: 3,
    made: 38,
    notes: 9,
  },
  centres: { total: 5, inUse: 3 },
  openAlerts: 0,
  soFar: false,
};

test("the text is the board's: a line per figure with the week before in brackets, no name", () => {
  const { subject, text } = reportText(board);
  expect(subject).toBe("Tutor Central, the week of 6 to 12 October");
  expect(text).toBe(
    [
      "The week of 6 to 12 October, with the week before in brackets.",
      "",
      "Tutors active: 3 (2)",
      "Closes: 12 (9)",
      "Plans made: 14 · followed: 12 (11 · 9)",
      "Notes sent: 9 (6)",
      "Made: 38 · made again: 6 (31 · 4)",
      "made again by reason: harder 2 · shorter 2 · less about marks 1 · typed 1",
      "Make something: 7 (5)",
      "Consent given: 2 (1)",
      "AI cost: ₹214 · per active tutor ₹71 (₹168 · ₹84)",
      "Centres: 5 · in use: 3 · open alerts: 0",
      "",
      "The figures, by week: https://admin.tutorcentral.in/figures",
      "",
      "Sent every Monday at 08:00 IST by Tutor Central’s own job. No AI service wrote this; nothing in it names a tutor or a student.",
    ].join("\n"),
  );
});

test("a week across two months names both; a week so far says so in the subject and the closing line", () => {
  const across = reportText({
    ...board,
    week: week("2026-09-29", {}),
    before: week("2026-09-22", {}),
  });
  expect(across.subject).toBe("Tutor Central, the week of 29 September to 5 October");
  const soFar = reportText({
    ...board,
    week: week("2026-10-13", { so_far: true }),
    soFar: true,
  });
  expect(soFar.subject).toBe("Tutor Central, the week of 13 October so far");
  expect(soFar.text).toStartWith("The week of 13 October so far, with the week before in brackets.");
  expect(soFar.text).toEndWith(
    "Sent from the figures page by Tutor Central’s own job. No AI service wrote this; nothing in it names a tutor or a student.",
  );
});

test("a week with no reason has no reasons line; small costs keep their paise", () => {
  const { text } = reportText({
    ...board,
    reasons: { again: [], edits: 0, made: 0, notes: 0 },
    week: week("2026-10-06", {
      cost_paise: 326,
      per_active_tutor_paise: 326,
      tutors_active: 1,
    }),
  });
  expect(text).not.toContain("made again by reason");
  expect(text).toContain("AI cost: ₹3.26 · per active tutor ₹3.26 (₹168 · ₹84)");
});
