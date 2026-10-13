import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import CentrePage from "../../app/centres/[id]/page";
import { reasonOf, recordAsk } from "../../app/centres/[id]/reason";
import RecordPage from "../../app/centres/[id]/record/page";
import { meets } from "../../content/record";

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const centre = { params: Promise.resolve({ id: "preview" }) };

test("the ask: the dialog over the centre's page, with the reason's field", async () => {
  const html = renderToStaticMarkup(await CentrePage({ ...centre, searchParams: Promise.resolve({ ask: "1" }) }));
  for (const words of [
    "Open the record of Sunrise Tuition Centre?",
    "Say why. The reason and the time go into the audit with your name.",
    'name="reason"',
    "Cancel",
  ])
    expect(html).toContain(words);
  expect(html).toContain('role="dialog"');
  expect(renderToStaticMarkup(await CentrePage({ ...centre, searchParams: Promise.resolve({}) }))).not.toContain(
    'role="dialog"',
  );
  expect(
    renderToStaticMarkup(await CentrePage({ ...centre, searchParams: Promise.resolve({ ask: "1", empty: "1" }) })),
  ).toContain("Say why: the reason goes into the audit.");
});

test("the record: the banner, the students with consent, the batches, what was made; never a parent's number", async () => {
  const html = renderToStaticMarkup(await RecordPage(centre));
  for (const words of [
    "Opened at 10:42 by you",
    "written to the audit",
    "Aarav Sharma",
    "Diya Patel",
    "Hemanth Reddy",
    "Kavya Nair",
    "Rohan Das",
    "Akshita Rao",
    "given · 12 Oct",
    "withdrawn · 12 Oct",
    "asked · waiting",
    "not asked",
    "Not on track",
    "Mon to Fri",
    "Tue, Thu, Sat",
    "17:00 to 18:00",
    "What the AI service made about these students",
    "Hemanth’s gap report · Science unit test 2",
  ])
    expect(html).toContain(words);
  expect(html).not.toContain("+91");
});

test("the record page without a reason sends to the ask: no fresh open, no record", () => {
  expect(recordAsk("preview", undefined, false)).toBe("/centres/preview?ask=1");
  expect(recordAsk("preview", "", false)).toBe("/centres/preview?ask=1");
  expect(recordAsk("preview", "6f1c2a8e-0000-4000-8000-000000000001", false)).toBeNull();
  // Preview mode draws the record from its fixture, with no open.
  expect(recordAsk("preview", undefined, true)).toBeNull();
});

test("a reason is 1 to 200 characters, trimmed", () => {
  const form = (reason: string) => {
    const f = new FormData();
    f.set("reason", reason);
    return f;
  };
  expect(reasonOf(form("  a support ask "))).toBe("a support ask");
  expect(reasonOf(form("  "))).toBeNull();
  expect(reasonOf(form("x".repeat(201)))).toBeNull();
  expect(reasonOf(form("x".repeat(200)))).toBe("x".repeat(200));
});

test("a batch's days in words", () => {
  expect(meets([1, 2, 3, 4, 5])).toBe("Mon to Fri");
  expect(meets([2, 4, 6])).toBe("Tue, Thu, Sat");
  expect(meets([])).toBe("—");
  expect(meets(null)).toBe("—");
});
