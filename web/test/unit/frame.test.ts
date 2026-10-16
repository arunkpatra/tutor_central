import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { SiteFooter } from "../../components/SiteFooter";
import { SiteHeader } from "../../components/SiteHeader";
import { EMAIL } from "../../content/site";

test("the header carries the brand and the three pages, marking the current one", () => {
  const html = renderToStaticMarkup(createElement(SiteHeader, { current: "Privacy" }));
  expect(html).toContain("Tutor Central");
  expect(html).toContain('href="/support"');
  expect(html).toContain('href="/privacy" aria-current="page"');
  expect(html).toContain('href="/terms"');
  expect(html).not.toContain('href="/support" aria-current="page"');
});

test("the footer carries the promise, the links, the email and the copyright", () => {
  const html = renderToStaticMarkup(createElement(SiteFooter));
  expect(html).toContain("Made in India for tutors who run their own centre.");
  expect(html).toContain(`href="mailto:${EMAIL}"`);
  for (const href of ["/support", "/privacy", "/terms"]) expect(html).toContain(`href="${href}"`);
  expect(html).toContain(`© ${new Date().getFullYear()} GoodGround LLP`);
});

/** The brand kit's small-size master (a held copy, `docs/design/brand-kit.json`): its one path, as the tile draws it. */
const MARK = (() => {
  const svg = readFileSync(
    join(import.meta.dir, "..", "..", "..", "docs", "design", "brand", "tc-mark-ink-small.svg"),
    "utf8",
  );
  return svg.replace(/<metadata>.*?<\/metadata>/s, "").match(/<path d="([^"]+)"/)?.[1] ?? "";
})();

test("the brand is the kit's mark: 16 px in the header, 14 in the footer, never the book (D120, D122)", () => {
  expect(MARK.length).toBeGreaterThan(100);
  const header = renderToStaticMarkup(createElement(SiteHeader, { current: "Privacy" }));
  const footer = renderToStaticMarkup(createElement(SiteFooter));
  for (const [html, size] of [
    [header, 16],
    [footer, 14],
  ] as const) {
    expect(html).toContain(`d="${MARK}"`);
    expect(html).toContain(`width="${size}" height="${size}" viewBox="0 0 256 256"`);
    expect(html).not.toContain("M20.001 19A2");
  }
  // The tile's sizes are the stylesheet's (rule 3), never inline.
  expect(header).toContain('<span class="brandMark" aria-hidden="true">');
  expect(footer).toContain('<span class="brandMark brandMarkSmall" aria-hidden="true">');
});
