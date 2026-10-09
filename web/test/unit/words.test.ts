import { expect, test } from "bun:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import NotFound from "../../app/not-found";
import Home from "../../app/page";

/** The app's banned words (ErrorWordsTests) less "database", which the privacy page uses in its plain sense (D41). */
const BANNED = [
  "server",
  "servers",
  "sync",
  "syncing",
  "synced",
  "cache",
  "cached",
  "queue",
  "queued",
  "upload",
  "uploaded",
  "api",
  "backend",
  "endpoint",
  "token",
  "json",
  "http",
  "https",
  "url",
  "error code",
  "status code",
  "401",
  "404",
  "500",
];

const PAGES: Record<string, () => string> = {
  home: () => renderToStaticMarkup(createElement(Home)),
  notFound: () => renderToStaticMarkup(createElement(NotFound)),
};

/** The words a reader sees: tags (and so attributes such as href) removed. */
function visibleText(html: string): string {
  return html
    .replace(/<[^>]+>/g, " ")
    .replace(/&[a-z#0-9]+;/g, " ")
    .toLowerCase();
}

test("no technical words on any page", () => {
  for (const [name, render] of Object.entries(PAGES)) {
    const text = visibleText(render());
    const found = new Set(text.split(/[^a-z0-9]+/).filter(Boolean));
    for (const banned of BANNED) {
      if (banned.includes(" ")) expect(text.includes(banned), `${name}: ${banned}`).toBe(false);
      else expect(found.has(banned), `${name}: ${banned}`).toBe(false);
    }
  }
});

test("the check itself finds a banned word in visible text but not in an attribute", () => {
  const text = visibleText('<a href="https://x.in">Saved on the server</a>');
  expect(text).toContain("server");
  expect(text).not.toContain("https");
});
