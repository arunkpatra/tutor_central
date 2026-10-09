import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import NotFound from "../../app/not-found";

test("not found keeps the frame and offers Home and Support", () => {
  const html = renderToStaticMarkup(createElement(NotFound));
  expect(html).toContain("There is nothing at this address.");
  expect(html).toContain("The page may have moved, or the link may be mistyped.");
  expect(html).toContain('href="/" class="btn btnPrimary"');
  expect(html).toContain('href="/support" class="btn btnSecondary"');
  expect(html).toContain('aria-label="Pages"');
  expect(html).toContain('aria-label="Footer"');
});
