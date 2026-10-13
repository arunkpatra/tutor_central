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
