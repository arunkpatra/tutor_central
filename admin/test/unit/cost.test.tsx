import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import CostPage from "../../app/cost/page";
import { monthLabel, stepRows } from "../../content/cost";
import { withData } from "../../lib/data";
import { previewData } from "../../lib/data/preview";
import type { Cost } from "../../lib/data/types";
import empty from "./cost-empty.json";

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const page = async (q: Record<string, string> = {}) =>
  renderToStaticMarkup(await CostPage({ searchParams: Promise.resolve(q) }));

test("cost: the tiles, the day chart with its line, by centre, and by kind, model and step (P21-Cost)", async () => {
  const html = await page();
  for (const words of [
    "this month, all centres",
    "per active centre",
    "of ₹499, the average centre",
    "By day, all centres",
    "the alert line is ₹60 a day for one centre",
    "By centre, and by kind, model and step",
    "a check, repair or grade is a row of its kind",
    "Batched work is priced at half and marked.",
    "Bright Minds, Jayanagar",
    "Of ₹499",
    "check_paper",
    "Opus 5.5",
    ">Step<",
    "batch · ½",
  ])
    expect(html).toContain(words);
  // A kind's steps sit together, its check a row apart from its draft (P21-Cost).
  expect(html).toMatch(
    /Kind<\/span>sheet<\/div><div class="cell dim"><span class="k">Step<\/span>draft.*?Kind<\/span>sheet<\/div><div class="cell dim"><span class="k">Step<\/span>check/s,
  );
  // The highest day carries its figure over its bar.
  expect(html).toContain('<span class="barTop">₹100</span>');
});

test("by month: the months with calls, this one to today, the batched share and the average centre against ₹499", async () => {
  const html = await page();
  for (const words of [
    "By month",
    "October, to the 13th",
    "September",
    "August",
    "July",
    "₹212 · 21%",
    "Per active centre",
  ])
    expect(html).toContain(words);
  expect(html).not.toContain('<span class="k">Month</span>June');
  // A month with no batched call shows ₹0, never a division.
  expect(html).toContain(">₹0<");
});

test("a month with no calls: flat bars and ₹0 tiles", async () => {
  const fake = { ...previewData, cost: async () => empty as Cost };
  const html = await withData(fake, () => page());
  expect(html).toContain(">₹0<");
  expect(html).not.toContain('class="barTop"');
  expect(html).toContain('style="height:0%"');
});

test("a step's rows merge their models; a batched row stays apart; the tail is the rest", () => {
  const rows = stepRows(
    [
      { kind: "sheet", step: "draft", model: "claude-sonnet-5-5", batched: false, calls: 2, paise: 300 },
      { kind: "sheet", step: "draft", model: "claude-haiku-5-5", batched: false, calls: 1, paise: 100 },
      { kind: "sheet", step: "draft", model: "claude-sonnet-5-5", batched: true, calls: 4, paise: 200 },
      { kind: "sheet", step: "check", model: "claude-haiku-5-5", batched: false, calls: 3, paise: 30 },
      ...Array.from({ length: 9 }, (_, i) => ({
        kind: `k${i}`,
        step: "draft",
        model: "claude-haiku-5-5",
        batched: false,
        calls: 1,
        paise: 10 - i,
      })),
    ],
    8,
  );
  expect(rows[0]).toEqual({
    kind: "sheet",
    step: "draft",
    batched: false,
    models: "Sonnet 5.5 · Haiku 5.5",
    calls: 3,
    paise: 400,
  });
  expect(rows[1]).toEqual({ kind: "sheet", step: "draft", batched: true, models: "Sonnet 5.5", calls: 4, paise: 200 });
  expect(rows[2]).toMatchObject({ kind: "sheet", step: "check" });
  expect(rows.length).toBe(9);
  expect(rows[8]).toMatchObject({ kind: "the rest", step: "" });
});

test("a month's label: this month runs to today", () => {
  expect(monthLabel("2026-10-01", "2026-10-13")).toBe("October, to the 13th");
  expect(monthLabel("2026-10-01", "2026-10-01")).toBe("October, to the 1st");
  expect(monthLabel("2026-10-01", "2026-10-22")).toBe("October, to the 22nd");
  expect(monthLabel("2026-09-01", "2026-10-13")).toBe("September");
});
