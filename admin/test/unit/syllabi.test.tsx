import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import SyllabiPage from "../../app/syllabi/page";

// Phase 22 (P22-Syllabi): the syllabus data, read only; one opens in place.
beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const page = async (q: Record<string, string> = {}) =>
  renderToStaticMarkup(await SyllabiPage({ searchParams: Promise.resolve(q) }));

test("Syllabus data: the tiles, every syllabus, one open with its chapters and skills", async () => {
  const closed = await page();
  for (const words of ["Syllabus data", "syllabi", "boards: CBSE, Karnataka", "Every syllabus", "Mathematics", "Open"])
    expect(closed).toContain(words);
  expect(closed).not.toContain("Rational Numbers");
  const open = await page({ open: "preview" });
  for (const words of [
    "Rational Numbers",
    "Close",
    "Properties of rational numbers",
    "No",
    "Chapter",
    "Skills",
    "Blueprint",
  ])
    expect(open).toContain(words);
});

test("the filters: a board and a class", async () => {
  const html = await page({ board: "karnataka" });
  expect(html).toContain("Karnataka");
  expect(html).not.toContain(`<span class="k">Board</span>CBSE`);
  expect(await page({ class: "10" })).not.toContain(`<span class="k">Class</span>8<`);
});

test("each row's Open names its syllabus; the opened one says when it last changed (review R-portal-7, -8)", async () => {
  const html = await page({ open: "preview" });
  expect(html).toContain('aria-label="Open CBSE 8 Science"');
  expect(html).toContain("last changed 9 Oct");
});
