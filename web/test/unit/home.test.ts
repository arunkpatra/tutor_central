import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import Home from "../../app/page";
import { HOME } from "../../content/home";
import { EMAIL } from "../../content/site";

const render = () => renderToStaticMarkup(createElement(Home));

test("before the App Store: the email call to action and no badge", () => {
  delete process.env.APP_STORE_URL;
  const html = render();
  expect(html).toContain(HOME.headline);
  expect(html).toContain(`href="mailto:${EMAIL}"`);
  expect(html).toContain(HOME.comingSoon);
  expect(html).not.toContain("App Store<");
});

test("once the app is live: Apple's badge with the link, no email button in the hero", () => {
  process.env.APP_STORE_URL = "https://apps.apple.com/in/app/id0000000000";
  const html = render();
  expect(html).toContain('href="https://apps.apple.com/in/app/id0000000000"');
  expect(html).toContain("Download on the");
  expect(html).toContain(HOME.badgeLine);
  expect(html).not.toContain(HOME.comingSoon);
  delete process.env.APP_STORE_URL;
});

test("a blank APP_STORE_URL counts as unset", () => {
  process.env.APP_STORE_URL = "  ";
  const html = render();
  expect(html).toContain(HOME.comingSoon);
  expect(html).not.toContain("Download on the");
  delete process.env.APP_STORE_URL;
});

test("the seven features, the six ways, the four nots and the privacy link are on the page", () => {
  const html = render();
  expect(HOME.features).toHaveLength(7);
  expect(HOME.how).toHaveLength(6);
  expect(HOME.not).toHaveLength(4);
  for (const f of HOME.features) expect(html).toContain(f.title);
  for (const h of HOME.how) expect(html).toContain(h.title);
  for (const n of HOME.not) expect(html).toContain(n.title);
  expect(html).toContain('href="/privacy"');
  expect(html).toContain('src="/today-dark.png"');
});
