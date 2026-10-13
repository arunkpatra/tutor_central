import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import ErrorsPage from "../../app/errors/page";

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const page = async (q: Record<string, string> = {}) =>
  renderToStaticMarkup(await ErrorsPage({ searchParams: Promise.resolve(q) }));

test("errors: the tiles, by route and reason, the latest with their request ids", async () => {
  const html = await page();
  for (const words of [
    "requests in 24 h",
    "errors · 0.5%",
    "502 timeouts",
    "312 ms",
    "By route and reason",
    "The latest",
    "timeout · the model did not answer in 110 s",
    "student_consent · a note asked without consent",
    "sign in again · a stale token",
    "7a1e…c0d4",
    "b02f…77e1",
    "0c9a…14b2",
    "e1d3…9f00",
    "5f67…a3c1",
  ])
    expect(html).toContain(words);
});

test("a route narrows both tables", async () => {
  const html = await page({ route: "POST /ai/check-paper" });
  expect(html).toContain("too large · a photo over the limit");
  expect(html).not.toContain("student_consent · a note asked without consent");
});
