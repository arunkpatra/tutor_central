import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import CostPage from "../../app/cost/page";
import { kindRows } from "../../content/cost";
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

test("cost: the tiles, the day chart with its line, by centre and by kind", async () => {
  const html = await page();
  for (const words of [
    "this month, all centres",
    "per active centre",
    "of ₹499, the average centre",
    "By day, all centres",
    "the alert line is ₹60 a day for one centre",
    "By centre, and by kind and model",
    "Bright Minds, Jayanagar",
    "Of ₹499",
    "check_paper",
    "Opus 5.5",
    "Sonnet 5.5 · Haiku 5.5",
  ])
    expect(html).toContain(words);
  // The highest day carries its figure over its bar.
  expect(html).toContain('<span class="barTop">₹100</span>');
});

test("a month with no calls: flat bars and ₹0 tiles", async () => {
  const fake = { ...previewData, cost: async () => empty as Cost };
  const html = await withData(fake, () => page());
  expect(html).toContain(">₹0<");
  expect(html).not.toContain('class="barTop"');
  expect(html).toContain('style="height:0%"');
});

test("the kinds merge their models and the tail is the rest", () => {
  const rows = kindRows(
    [
      { kind: "sheet", model: "claude-sonnet-5-5", calls: 2, paise: 300 },
      { kind: "sheet", model: "claude-haiku-5-5", calls: 1, paise: 100 },
      ...Array.from({ length: 9 }, (_, i) => ({ kind: `k${i}`, model: "claude-haiku-5-5", calls: 1, paise: 10 - i })),
    ],
    8,
  );
  expect(rows[0]).toEqual({ kind: "sheet", models: "Sonnet 5.5 · Haiku 5.5", calls: 3, paise: 400 });
  expect(rows.length).toBe(9);
  expect(rows[8]?.kind).toBe("the rest");
});
