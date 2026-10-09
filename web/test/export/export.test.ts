import { expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const OUT = join(import.meta.dir, "..", "..", "out");
const page = (file: string) => readFileSync(join(OUT, file), "utf8");

/** The files Vercel serves: `/` → index.html, `/privacy` → privacy.html, …, anything else → 404.html. */
const PAGES: Record<string, string> = {
  "index.html": "Tutor Central",
};

test("the export holds the pages with their titles and the commit", () => {
  for (const [file, words] of Object.entries(PAGES)) {
    if (!existsSync(join(OUT, file))) throw new Error(`${file} was not exported`);
    expect(page(file)).toContain(words);
    expect(page(file)).toMatch(/<meta name="tc-commit" content="[^"]+"\/>/);
  }
});

test("no legal page ships with a placeholder", () => {
  for (const file of ["privacy.html", "terms.html"]) {
    if (!existsSync(join(OUT, file))) continue; // Task 6 adds them; this line goes when it does.
    expect(page(file)).not.toContain("[OWNER:");
  }
});
