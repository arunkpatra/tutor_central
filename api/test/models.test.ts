import { afterEach, expect, test } from "bun:test";
import table from "../models.json" with { type: "json" };
import type { AIKind } from "../src/db.js";
import { applyModelOverrides, KNOWN_MODELS, modelFor, resetModelOverrides, workTypeOf } from "../src/models.js";

afterEach(() => resetModelOverrides());

const KINDS: AIKind[] = ["paper", "homework", "worksheet", "progress_note", "scan_register", "check_paper", "plan", "sheet", "worked_example", "figure", "brief", "check", "placement", "mock", "note", "can_do", "test_tomorrow", "gap_report", "parse_school", "parse_textbook", "not_on_track", "read_marks"];

test("the table names a model for each kind of work, the sheet in two bands (D67)", () => {
  for (const kind of KINDS) {
    const levels = kind === "sheet" ? (["5", "6"] as const) : ([undefined] as const);
    for (const level of levels) expect({ kind, level, model: KNOWN_MODELS.includes(modelFor(kind, level)) }).toEqual({ kind, level, model: true });
  }
  expect(workTypeOf("sheet", "lkg")).toBe("sheet_to_5");
  expect(workTypeOf("sheet", "6")).toBe("sheet_from_6");
  expect(workTypeOf("check_paper")).toBe("check_paper");
  expect(Object.keys(table.work).sort()).toEqual([...KINDS.filter((k) => k !== "sheet"), "sheet_from_6", "sheet_to_5"].sort());
});

test("the defaults are the spec's (D63) with marking apart from reading a report card (D67)", () => {
  expect(modelFor("check_paper")).toBe("claude-opus-5-5");
  expect(modelFor("scan_register")).toBe("claude-opus-5-5");
  expect(modelFor("paper")).toBe("claude-sonnet-5-5");
  expect(modelFor("read_marks")).toBe("claude-sonnet-5-5");
  expect(modelFor("note")).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "5")).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "6")).toBe("claude-sonnet-5-5");
  for (const kind of ["check", "placement", "note", "can_do", "test_tomorrow", "not_on_track"] as const) expect({ kind, model: modelFor(kind) }).toEqual({ kind, model: "claude-haiku-5-5" });
  for (const kind of ["worked_example", "figure", "brief", "mock", "parse_school", "parse_textbook", "plan", "gap_report"] as const) expect({ kind, model: modelFor(kind) }).toEqual({ kind, model: "claude-sonnet-5-5" });
});

test("AI_MODEL_<WORK_TYPE> overrides one work type and leaves the rest", () => {
  applyModelOverrides({ AI_MODEL_CHECK_PAPER: "claude-sonnet-5-5", AI_MODEL_SHEET_FROM_6: "claude-haiku-5-5" });
  expect(modelFor("check_paper")).toBe("claude-sonnet-5-5");
  expect(modelFor("sheet", "8")).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "3")).toBe("claude-haiku-5-5");
  expect(modelFor("mock")).toBe("claude-sonnet-5-5");
});

test("an unknown model name is refused at start, naming the variable and the known names", () => {
  expect(() => applyModelOverrides({ AI_MODEL_NOTE: "claude-5" })).toThrow(/AI_MODEL_NOTE names an unknown model: claude-5\. Known: claude-haiku-5-5, claude-sonnet-5-5, claude-opus-5-5/);
  expect(() => applyModelOverrides({ AI_MODEL_SOMETHING: "claude-opus-5-5" })).toThrow(/AI_MODEL_SOMETHING names no kind of work/);
  expect(modelFor("note")).toBe("claude-haiku-5-5");
});

test("the prices are the three models' and the rupee is 85", () => {
  expect(table.rupeesPerDollar).toBe(85);
  expect(Object.keys(table.models)).toEqual(["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"]);
});
