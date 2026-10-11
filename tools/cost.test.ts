import { expect, test } from "bun:test";
import table from "../api/models.json" with { type: "json" };
import { costTable } from "./cost";

test("rows are priced by kind and model from api/models.json, in rupees to the paisa", () => {
  const rows = [
    { kind: "check_paper", model: "claude-opus-5-5", tokens_in: 10_623, tokens_out: 2_690 },
    { kind: "mock", model: "claude-sonnet-5-5", tokens_in: 1_166, tokens_out: 4_399 },
    { kind: "note", model: "claude-haiku-5-5", tokens_in: 900, tokens_out: 300 },
    { kind: "note", model: "claude-haiku-5-5", tokens_in: 800, tokens_out: 250 },
  ];
  expect(costTable(rows, table)).toEqual([
    { kind: "check_paper", model: "claude-opus-5-5", calls: 1, tokensIn: 10_623, tokensOut: 2_690, rupees: 8.18 },
    { kind: "mock", model: "claude-sonnet-5-5", calls: 1, tokensIn: 1_166, tokensOut: 4_399, rupees: 3.94 },
    { kind: "note", model: "claude-haiku-5-5", calls: 2, tokensIn: 1_700, tokensOut: 550, rupees: 0.04 },
  ]);
});

test("a row whose model the table does not price is listed with no rupees, never priced wrong", () => {
  const [row] = costTable([{ kind: "note", model: "claude-5", tokens_in: 1, tokens_out: 1 }], table);
  expect(row).toMatchObject({ kind: "note", model: "claude-5", rupees: null });
});
