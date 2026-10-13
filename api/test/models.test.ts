import { afterEach, expect, test } from "bun:test";
import table from "../models.json" with { type: "json" };
import type { AIKind } from "../src/db.js";
import { applyModelOverrides, installModelTable, KNOWN_MODELS, modelFor, resetModelOverrides, workTypeOf } from "../src/models.js";
import { fakeModelSource, type ModelSource } from "../src/models-db.js";

afterEach(() => resetModelOverrides());

const KINDS: AIKind[] = ["paper", "homework", "worksheet", "progress_note", "scan_register", "check_paper", "plan", "sheet", "worked_example", "figure", "brief", "check", "placement", "mock", "note", "can_do", "test_tomorrow", "gap_report", "parse_school", "parse_textbook", "not_on_track", "read_marks"];

test("the table names a model for each kind of work, the sheet in two bands (D67)", () => {
  for (const kind of KINDS) {
    const levels = kind === "sheet" ? (["5", "6"] as const) : ([undefined] as const);
    for (const level of levels) expect({ kind, level, model: KNOWN_MODELS.includes(modelFor(kind, "draft", level).model) }).toEqual({ kind, level, model: true });
  }
  expect(workTypeOf("sheet", "lkg")).toBe("sheet_to_5");
  expect(workTypeOf("sheet", "6")).toBe("sheet_from_6");
  expect(workTypeOf("check_paper")).toBe("check_paper");
  expect(Object.keys(table.work).sort()).toEqual([...KINDS.filter((k) => k !== "sheet"), "sheet_from_6", "sheet_to_5"].sort());
});

test("the defaults are the spec's (D63) with marking apart from reading a report card (D67)", () => {
  expect(modelFor("check_paper", "draft").model).toBe("claude-opus-5-5");
  expect(modelFor("scan_register", "draft").model).toBe("claude-opus-5-5");
  expect(modelFor("paper", "draft").model).toBe("claude-sonnet-5-5");
  expect(modelFor("read_marks", "draft").model).toBe("claude-sonnet-5-5");
  expect(modelFor("note", "draft").model).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "draft", "5").model).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "draft", "6").model).toBe("claude-sonnet-5-5");
  for (const kind of ["check", "note", "can_do", "test_tomorrow", "not_on_track"] as const) expect({ kind, model: modelFor(kind, "draft").model }).toEqual({ kind, model: "claude-haiku-5-5" });
  for (const kind of ["worked_example", "figure", "brief", "mock", "parse_school", "parse_textbook", "plan", "gap_report"] as const) expect({ kind, model: modelFor(kind, "draft").model }).toEqual({ kind, model: "claude-sonnet-5-5" });
});

test("AI_MODEL_<WORK_TYPE> overrides one work type and leaves the rest", () => {
  applyModelOverrides({ AI_MODEL_CHECK_PAPER: "claude-sonnet-5-5", AI_MODEL_SHEET_FROM_6: "claude-haiku-5-5" });
  expect(modelFor("check_paper", "draft").model).toBe("claude-sonnet-5-5");
  expect(modelFor("sheet", "draft", "8").model).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "draft", "3").model).toBe("claude-haiku-5-5");
  expect(modelFor("mock", "draft").model).toBe("claude-sonnet-5-5");
});

test("an unknown model name is refused at start, naming the variable and the known names", () => {
  expect(() => applyModelOverrides({ AI_MODEL_NOTE: "claude-5" })).toThrow(/AI_MODEL_NOTE names an unknown model: claude-5\. Known: claude-haiku-5-5, claude-sonnet-5-5, claude-opus-5-5/);
  expect(() => applyModelOverrides({ AI_MODEL_SOMETHING: "claude-opus-5-5" })).toThrow(/AI_MODEL_SOMETHING names no kind of work/);
  expect(modelFor("note", "draft").model).toBe("claude-haiku-5-5");
});

test("the prices are the three models' and the rupee is 85", () => {
  expect(table.rupeesPerDollar).toBe(85);
  expect(Object.keys(table.models)).toEqual(["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"]);
});

test("applying the overrides starts from the table, so a second call does not keep the first one's", () => {
  applyModelOverrides({ AI_MODEL_NOTE: "claude-sonnet-5-5" });
  applyModelOverrides({ AI_MODEL_READ_MARKS: "claude-opus-5-5" });
  expect(modelFor("note", "draft").model).toBe("claude-haiku-5-5");
  expect(modelFor("read_marks", "draft").model).toBe("claude-opus-5-5");
});

test("the table's row beats the file; the environment beats the table; a check step has its own row", async () => {
  const t = installModelTable(fakeModelSource([
    { kind: "sheet_from_6", step: "draft", model: "claude-haiku-5-5", effort: "low", fallbackModel: "claude-sonnet-5-5", enabled: true },
    { kind: "sheet_from_6", step: "check", model: "claude-sonnet-5-5", effort: "medium", fallbackModel: null, enabled: true },
  ]));
  expect(await t.refresh()).toBe(true);
  expect(modelFor("sheet", "draft", "8")).toEqual({ model: "claude-haiku-5-5", effort: "low", fallback: "claude-sonnet-5-5", enabled: true });
  expect(modelFor("sheet", "check", "8").model).toBe("claude-sonnet-5-5");
  applyModelOverrides({ AI_MODEL_SHEET_FROM_6: "claude-opus-5-5" });
  expect(modelFor("sheet", "draft", "8").model).toBe("claude-opus-5-5");
  expect(modelFor("sheet", "check", "8").model).toBe("claude-sonnet-5-5");
  t.stop();
});

test("a start with no table uses the file and the next refresh takes the table", async () => {
  let fail = true;
  const source: ModelSource = {
    current: async () => {
      if (fail) throw new Error("down");
      return [{ kind: "brief", step: "draft", model: "claude-haiku-5-5", effort: "medium", fallbackModel: null, enabled: true }];
    },
  };
  const t = installModelTable(source);
  expect(await t.refresh()).toBe(false);
  expect(modelFor("brief", "draft").model).toBe("claude-sonnet-5-5");
  fail = false;
  expect(await t.refresh()).toBe(true);
  expect(modelFor("brief", "draft").model).toBe("claude-haiku-5-5");
  fail = true;
  expect(await t.refresh()).toBe(false);
  expect(modelFor("brief", "draft").model).toBe("claude-haiku-5-5");
  t.stop();
});

test("a row naming an unknown model is dropped; a switched-off row answers enabled false", async () => {
  const t = installModelTable(fakeModelSource([
    { kind: "figure", step: "draft", model: "claude-nothing-9", effort: "medium", fallbackModel: null, enabled: true },
    { kind: "placement", step: "draft", model: "claude-haiku-5-5", effort: "medium", fallbackModel: "claude-nothing-9", enabled: false },
  ]));
  await t.refresh();
  expect(modelFor("figure", "draft").model).toBe("claude-sonnet-5-5");
  expect(modelFor("placement", "draft")).toEqual({ model: "claude-haiku-5-5", effort: "medium", fallback: null, enabled: false });
  t.stop();
});

test("with no table row a kind takes the file's model, the seed's effort and no fallback; check and repair rows follow 0052's rule", () => {
  expect(modelFor("check_paper", "draft")).toEqual({ model: "claude-opus-5-5", effort: "high", fallback: null, enabled: true });
  expect(modelFor("note", "draft")).toEqual({ model: "claude-haiku-5-5", effort: "medium", fallback: null, enabled: true });
  expect(modelFor("note", "check").model).toBe("claude-sonnet-5-5");
  expect(modelFor("sheet", "check", "3").model).toBe("claude-sonnet-5-5");
  expect(modelFor("sheet", "check", "9").model).toBe("claude-haiku-5-5");
  expect(modelFor("check_paper", "check").model).toBe("claude-sonnet-5-5");
  expect(modelFor("brief", "repair").model).toBe("claude-sonnet-5-5");
});

test("fresh() reads the table at most once a minute and gives up on a slow database within its wait", async () => {
  let now = 0;
  let reads = 0;
  const t = installModelTable({ current: async () => { reads += 1; return []; } }, { now: () => now, sleep: async () => {} });
  await t.fresh();
  await t.fresh();
  expect(reads).toBe(1);
  now = 61_000;
  await t.fresh();
  expect(reads).toBe(2);
  t.stop();
  const slow = installModelTable({ current: () => new Promise(() => {}) }, { now: () => now, sleep: async () => {} }, 20);
  const started = Date.now();
  await slow.fresh();
  expect(Date.now() - started).toBeLessThan(500);
  expect(modelFor("brief", "draft").model).toBe("claude-sonnet-5-5");
  slow.stop();
});

test("a placement drafts on Sonnet: Haiku told primary chapters wrongly and the repair could not fix it (#312's evals)", () => {
  expect(modelFor("placement", "draft").model).toBe("claude-sonnet-5-5");
  expect(modelFor("placement", "check").model).toBe("claude-haiku-5-5");
});
