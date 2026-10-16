import { expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const OUT = join(import.meta.dir, "..", "..", "out");
const page = (file: string) => readFileSync(join(OUT, file), "utf8");

/** The files Vercel serves: `/` → index.html, `/privacy` → privacy.html, …, anything else → 404.html. */
const PAGES: Record<string, string> = {
  "index.html": "Tutor Central",
  "privacy.html": "How Tutor Central handles your records",
  "terms.html": "Terms of use",
  "support.html": "We are one email away",
  "trust.html": "How Tutor Central treats your students",
  "404.html": "There is nothing at this address.",
};

test("the export holds the six pages with their titles and the commit", () => {
  for (const [file, words] of Object.entries(PAGES)) {
    if (!existsSync(join(OUT, file))) throw new Error(`${file} was not exported`);
    expect(page(file)).toContain(words);
    expect(page(file)).toMatch(/<meta name="tc-commit" content="[^"]+"\/>/);
  }
});

test("no legal page ships with a placeholder", () => {
  for (const file of ["privacy.html", "terms.html", "trust.html"]) {
    expect(page(file)).not.toContain("[OWNER:");
  }
});

test("the export carries the brand kit's tab icons, the touch icon and the link preview (D120, D122)", () => {
  for (const file of ["icon.svg", "favicon.ico", "apple-icon.png", "opengraph-image.png"])
    expect(existsSync(join(OUT, file)), `${file} was not exported`).toBe(true);
  expect(readFileSync(join(OUT, "icon.svg"), "utf8")).not.toContain("M20.001 19A2");
  for (const file of Object.keys(PAGES)) {
    const html = page(file);
    expect(html, file).toMatch(/<link rel="icon" href="\/icon\.svg[^"]*"[^>]*type="image\/svg\+xml"/);
    expect(html, file).toMatch(/<link rel="icon" href="\/favicon\.ico[^"]*"/);
    expect(html, file).toMatch(/<link rel="apple-touch-icon" href="\/apple-icon\.png[^"]*"/);
    expect(html, file).toMatch(
      /<meta property="og:image" content="https:\/\/tutorcentral\.in\/opengraph-image\.png[^"]*"/,
    );
    expect(html, file).not.toContain("M20.001 19A2");
  }
});
