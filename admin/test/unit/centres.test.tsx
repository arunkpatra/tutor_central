import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import CentrePage from "../../app/centres/[id]/page";
import CentresPage from "../../app/centres/page";

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const query = (q: Record<string, string> = {}) => Promise.resolve(q);

test("the centres list: the tiles, every centre, idle once, the allowance of ₹499", async () => {
  const html = renderToStaticMarkup(await CentresPage({ searchParams: query() }));
  for (const words of [
    "All centres",
    "active this week",
    "AI cost this month",
    "job failed today",
    "Cost this month, of ₹499",
  ])
    expect(html).toContain(words);
  for (const name of [
    "Sunrise Tuition Centre",
    "Bright Minds, Jayanagar",
    "Vidya Mandir Tuition",
    "Lakshmi Classes",
    "Anand Coaching",
    "Riya’s Study Room",
    "Smoke",
  ])
    expect(html).toContain(name);
  expect(html.match(/>idle</g)?.length).toBe(1);
  expect(html).toContain("none: not in use");
  expect(html).toContain('href="/centres/preview"');
});

test("the list's filters: idle centres alone, sorted by name", async () => {
  const html = renderToStaticMarkup(await CentresPage({ searchParams: query({ show: "idle", sort: "name" }) }));
  expect(html).toContain("Riya’s Study Room");
  expect(html).not.toContain("Sunrise Tuition Centre");
});

test("a centre: tutors and cost, the jobs, the activity in words, the record's card; never a parent's number", async () => {
  const html = renderToStaticMarkup(
    await CentrePage({ params: Promise.resolve({ id: "preview" }), searchParams: query() }),
  );
  for (const words of [
    "Sunrise Tuition Centre",
    "in use",
    "Tutors and cost",
    "meera@example.com",
    "iPhone · build 29",
    "no device",
    "of ₹499 · 36%",
    "All jobs of this centre",
    'href="/jobs?centre=preview"',
    "Closed a class · Evening batch · 11 present",
    "Opened the app",
    "Open the record",
    'href="/centres/preview?ask=1"',
  ])
    expect(html).toContain(words);
  expect(html).not.toContain("+91");
});

test("a centre that is gone is not found", async () => {
  const thrown = await CentrePage({ params: Promise.resolve({ id: "gone" }), searchParams: query() }).catch(
    (e: Error & { digest?: string }) => e,
  );
  expect((thrown as { digest?: string }).digest).toContain("404");
});

const centre = async (q: Record<string, string> = {}) =>
  renderToStaticMarkup(await CentrePage({ params: Promise.resolve({ id: "preview" }), searchParams: query(q) }));

test("the allowance line has Change; ?allowance=1 opens its dialog (P22-Centre-Allowance)", async () => {
  const html = await centre();
  expect(html).toContain("allowance 600 calls · ₹0 cap (none)");
  expect(html).toContain('href="/centres/preview?allowance=1"');
  expect(html).not.toContain("Save the allowance");
  const dialog = await centre({ allowance: "1" });
  for (const words of [
    "Change the allowance of Sunrise Tuition Centre?",
    "Calls a month",
    "Cap, ₹ a month",
    "0 is no cap",
    "Reason",
    "Save the allowance",
    'value="600"',
  ])
    expect(dialog).toContain(words);
  expect(await centre({ allowance: "1", empty: "1" })).toContain("Say why: the reason goes into the audit.");
  expect(await centre({ allowance: "1", bad: "1" })).toContain("Whole numbers, 0 or more");
});

test("Save the allowance: whole numbers of calls and rupees, a reason; the cap goes in paise", async () => {
  const { setAllowance } = await import("../../app/centres/[id]/actions");
  const { withData } = await import("../../lib/data");
  const { previewData } = await import("../../lib/data/preview");
  const seen: unknown[][] = [];
  const fake = { ...previewData, setAllowance: async (...args: unknown[]) => (seen.push(args), true) };
  const form = (calls: string, cap: string, reason: string) => {
    const f = new FormData();
    for (const [k, v] of Object.entries({ centre: "preview", calls, cap, reason })) f.set(k, v);
    return f;
  };
  const go = async (f: FormData) =>
    ((await withData(fake, () => setAllowance(f)).catch((e: { digest?: string }) => e)) as { digest?: string })
      .digest ?? "";
  expect(await go(form("900", "0", "  "))).toContain("/centres/preview?allowance=1&empty=1");
  expect(await go(form("9.5", "0", "exam month"))).toContain("/centres/preview?allowance=1&bad=1");
  expect(await go(form("-1", "0", "exam month"))).toContain("/centres/preview?allowance=1&bad=1");
  expect(seen).toHaveLength(0);
  expect(await go(form("900", "450", "exam month"))).toContain("/centres/preview");
  expect(seen[0]?.slice(1, 5)).toEqual(["preview", 900, 45_000, "exam month"]);
});

test("the allowance line counts one call as one (hand run 3, F1)", async () => {
  const { CENTRE } = await import("../../content/centres");
  expect(CENTRE.allowance(1, null)).toBe("allowance 1 call · ₹0 cap (none)");
  expect(CENTRE.allowance(600, "₹500")).toBe("allowance 600 calls · ₹500 cap");
});

test("an allowance of 0 calls is refused: it would stop every draft (review R-portal-1)", async () => {
  const { setAllowance } = await import("../../app/centres/[id]/actions");
  const { withData } = await import("../../lib/data");
  const { previewData } = await import("../../lib/data/preview");
  let asked = 0;
  const fake = { ...previewData, setAllowance: async () => (asked++, true) };
  const f = new FormData();
  for (const [k, v] of Object.entries({ centre: "preview", calls: "0", cap: "0", reason: "no cap" })) f.set(k, v);
  const to =
    ((await withData(fake, () => setAllowance(f)).catch((e: { digest?: string }) => e)) as { digest?: string })
      .digest ?? "";
  expect(to).toContain("/centres/preview?allowance=1&bad=calls");
  expect(asked).toBe(0);
  expect(await centre({ allowance: "1", bad: "calls" })).toContain("Calls a month: 1 or more");
});
