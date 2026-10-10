import { expect, test } from "bun:test";
import { MARKING_MODEL, modelFor } from "../src/models.js";

const HAIKU = "claude-haiku-5-5";
const SONNET = "claude-sonnet-5-5";
const OPUS = "claude-opus-5-5";

test("each V2 kind has one model, as docs/spec-v2.md section 9 routes them (D63)", () => {
  expect(modelFor("sheet", "lkg")).toBe(HAIKU);
  expect(modelFor("sheet", "5")).toBe(HAIKU);
  expect(modelFor("sheet", "6")).toBe(SONNET);
  expect(modelFor("sheet", "10")).toBe(SONNET);
  for (const kind of ["check", "placement", "note", "can_do", "test_tomorrow"] as const) expect({ kind, model: modelFor(kind, "8") }).toEqual({ kind, model: HAIKU });
  for (const kind of ["worked_example", "figure", "brief", "mock", "parse_school", "parse_textbook", "plan", "gap_report"] as const) expect({ kind, model: modelFor(kind, "3") }).toEqual({ kind, model: SONNET });
  // Marking a mock is check-paper's (Opus from Phase 13); V1's routes keep their models.
  expect(MARKING_MODEL).toBe(OPUS);
});
