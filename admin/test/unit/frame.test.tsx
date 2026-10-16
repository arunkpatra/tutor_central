import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { renderToStaticMarkup } from "react-dom/server";
import { AuthFrame, Frame } from "../../components/Frame";

test("the frame carries the brand with its ADMIN mark, the pages marking the current one, Sign out and the footer", () => {
  process.env.TC_COMMIT = "6d973b9b5ea6db2c34586cb9689439fd7dbe3ef9";
  const html = renderToStaticMarkup(<Frame current="Jobs">page</Frame>);
  delete process.env.TC_COMMIT;
  expect(html).toContain("Tutor Central");
  expect(html).toContain(">ADMIN<");
  for (const p of ["centres", "cost", "calls", "errors", "alerts", "models", "audit"])
    expect(html).toContain(`<a href="/${p}">`);
  expect([...html.matchAll(/<a (?:aria-current="page" )?href="\/([a-z]+)">/g)].map((m) => m[1])).toEqual([
    "centres",
    "figures",
    "cost",
    "calls",
    "jobs",
    "errors",
    "alerts",
    "models",
    "evals",
    "syllabi",
    "audit",
  ]);
  expect(html).toContain('<a aria-current="page" href="/jobs">');
  expect(html).toContain('action="/sign-out" method="post"');
  expect(html).toContain("Sign out");
  expect(html).toContain("Tutor Central admin · local · 6d973b9 · times in India (IST)");
  expect(html).toContain("Every open of a centre’s record and every action is written to the audit.");
});

test("the sign-in frame has no nav and the staff footer", () => {
  const html = renderToStaticMarkup(<AuthFrame>form</AuthFrame>);
  expect(html).not.toContain('aria-label="Pages"');
  expect(html).toContain("Tutor Central admin · for Tutor Central’s own staff");
});

/** The brand kit's small-size master (a held copy, `docs/design/brand-kit.json`): its one path, as the tile draws it. */
const MARK = (() => {
  const svg = readFileSync(
    join(import.meta.dir, "..", "..", "..", "docs", "design", "brand", "tc-mark-ink-small.svg"),
    "utf8",
  );
  return svg.replace(/<metadata>.*?<\/metadata>/s, "").match(/<path d="([^"]+)"/)?.[1] ?? "";
})();

test("the brand tile carries the kit's mark at 16, never the book (D120, D122)", () => {
  expect(MARK.length).toBeGreaterThan(100);
  for (const html of [
    renderToStaticMarkup(<Frame current="Jobs">page</Frame>),
    renderToStaticMarkup(<AuthFrame>form</AuthFrame>),
  ]) {
    expect(html).toContain(`d="${MARK}"`);
    expect(html).toContain('width="16" height="16" viewBox="0 0 256 256"');
    expect(html).not.toContain("M20.001 19A2");
  }
});
