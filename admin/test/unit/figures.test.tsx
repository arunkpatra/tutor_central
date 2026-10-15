import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import { sendReport } from "../../app/figures/actions";
import FiguresPage from "../../app/figures/page";
import { weekLabel } from "../../content/figures";
import { withData } from "../../lib/data";
import { previewData } from "../../lib/data/preview";

// Phase 22 (D114, D115; P22-Figures): the product figures by week, the week's reasons, the weekly report's card.
beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const page = async (q: Record<string, string> = {}) =>
  renderToStaticMarkup(await FiguresPage({ searchParams: Promise.resolve(q) }));

test("Product figures: the week's tiles, the weeks, the reasons, the report's card", async () => {
  const html = await page();
  for (const words of [
    "Product figures",
    "tutors active this week",
    "AI cost per active tutor, this week",
    "By week",
    "12 to 18 Oct",
    "so far, to Tuesday",
    "5 to 11 Oct",
    "28 Sep to 4 Oct",
    "14 · 12",
    "38 · 6",
    "Made again this week, by reason",
    "Less about marks",
    "Typed by the tutor",
    "Edited at Send",
    "33% of notes",
    "The weekly report",
    "Send this week so far, now",
    "Last sent",
  ])
    expect(html).toContain(words);
  expect(html).not.toContain("Sent to the alert address");
  expect(html.match(/<div class="grid" style="--cols:[^"]*">/g)?.length).toBeGreaterThanOrEqual(8);
});

test("the Weeks pill and the sent line", async () => {
  expect(await page({ weeks: "12" })).toContain("Weeks");
  expect(await page({ sent: "1" })).toContain("Sent to the alert address");
});

test("a week's label: within a month, across two, the cost per tutor with no tutor is a dash", () => {
  expect(weekLabel("2026-10-12")).toBe("12 to 18 Oct");
  expect(weekLabel("2026-09-28")).toBe("28 Sep to 4 Oct");
});

test("Send now queues the report and comes back sent", async () => {
  let asked = 0;
  const fake = { ...previewData, sendReport: async () => (asked++, "job") };
  const to =
    ((await withData(fake, () => sendReport()).catch((e: { digest?: string }) => e)) as { digest?: string }).digest ??
    "";
  expect(to).toContain("/figures?sent=1");
  expect(asked).toBe(1);
});

test("a week with no active tutor shows a dash for the cost per tutor (review R-portal-6)", async () => {
  const weeks = await previewData.figures(8);
  const none = {
    ...previewData,
    figures: async () => weeks.map((w, i) => (i === 0 ? { ...w, tutors_active: 0, per_active_tutor_paise: 0 } : w)),
  };
  const html = await withData(none, () => page());
  expect(html).toMatch(/<span class="k">Cost per active tutor<\/span>—/);
});
