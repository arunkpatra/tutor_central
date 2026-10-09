import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import RootLayout, { metadata, viewport } from "../../app/layout";

test("the layout names the commit it was built from and both theme colours", () => {
  process.env.TC_COMMIT = "abc123";
  const html = renderToStaticMarkup(RootLayout({ children: createElement("main", null, "x") }));
  expect(html).toContain('<meta name="tc-commit" content="abc123"/>');
  expect(html).toContain('<html lang="en">');
  expect(metadata.title).toEqual({ default: "Tutor Central", template: "%s · Tutor Central" });
  expect(viewport.themeColor).toEqual([
    { media: "(prefers-color-scheme: dark)", color: "#131110" },
    { media: "(prefers-color-scheme: light)", color: "#F8F4EE" },
  ]);
});

test("without TC_COMMIT the page says local", () => {
  delete process.env.TC_COMMIT;
  const html = renderToStaticMarkup(RootLayout({ children: createElement("main", null, "x") }));
  expect(html).toContain('content="local"');
});
