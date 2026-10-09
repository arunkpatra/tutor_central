import { expect, test } from "bun:test";
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
