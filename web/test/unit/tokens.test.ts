import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { viewport } from "../../app/layout";

const ROOT = join(import.meta.dir, "..", "..");
const css = readFileSync(join(ROOT, "app", "globals.css"), "utf8");
const doc = readFileSync(join(ROOT, "..", "docs", "design", "design-tokens.md"), "utf8");

/** The colour tokens the site uses: `--name` in the CSS must carry the document's dark and light values (D25's spirit). */
const USED = [
  "ground",
  "surface1",
  "surface2",
  "buttonFill",
  "well",
  "line",
  "lineStrong",
  "text",
  "text2",
  "text3",
  "accent",
  "accentPressed",
  "accentText",
  "accentTint",
  "textOnAccent",
];

function themeColor(scheme: "dark" | "light"): string {
  const colours = viewport.themeColor as { media: string; color: string }[];
  return colours.find((c) => c.media.includes(scheme))?.color ?? "";
}

function documented(token: string): { dark: string; light: string } {
  const row = doc.split("\n").find((l) => l.startsWith(`| \`${token}\` |`));
  if (!row) throw new Error(`${token} is not in design-tokens.md`);
  const cells = row.split("|").map((c) => c.trim());
  return { dark: cells[2] ?? "", light: cells[3] ?? "" };
}

/** Biome writes hex in lower case and `0.14` for `.14`; the document does neither. Compare the values, not the spelling. */
function normal(value: string): string {
  return value
    .toLowerCase()
    .replace(/\s+/g, "")
    .replace(/([,(:])\./g, "$10.");
}

function block(scheme: "dark" | "light"): Map<string, string> {
  const marker = scheme === "dark" ? "@media (prefers-color-scheme: dark)" : ":root {";
  const start = css.indexOf(marker);
  if (start < 0) throw new Error(`no ${scheme} block`);
  const body = css.slice(start, css.indexOf("}", start));
  return new Map([...body.matchAll(/--(\w+):\s*([^;]+);/g)].map((m) => [m[1] ?? "", normal(m[2] ?? "")]));
}

test("every colour token the site uses has the document's value in both schemes", () => {
  for (const token of USED) {
    const { dark, light } = documented(token);
    expect(block("light").get(token), `${token} light`).toBe(normal(light));
    expect(block("dark").get(token), `${token} dark`).toBe(normal(dark));
  }
});

test("no raw colour outside the token blocks", () => {
  const after = css.slice(css.indexOf("\n", css.lastIndexOf("--textOnAccent:")));
  // Every colour, shadows' included, is a variable in a token block; the rules below only use var(--…).
  const tail = after.slice(after.indexOf("\n}") + 2);
  expect(tail.match(/#[0-9A-Fa-f]{3,8}\b|rgba?\(/g) ?? []).toEqual([]);
});

test("the browser's bar colour is the ground token in both schemes", () => {
  const { dark, light } = documented("ground");
  expect(normal(themeColor("dark"))).toBe(normal(dark));
  expect(normal(themeColor("light"))).toBe(normal(light));
});
