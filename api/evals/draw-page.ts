#!/usr/bin/env bun
/** bun evals/draw-page.ts: draws the golden set's contents pages (api/evals/parse_textbook/pages/*.png) as text on a white
 *  page with headless Chrome, so no photo of a real book is in the repository (D74). Run once when a page changes; the
 *  PNGs are committed. The chapter names are the syllabus data's (supabase/syllabi) or invented. */
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const CHROME = process.env.TC_CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

export type Page = { file: string; title: string; heading: string; rows: { number?: string; name: string; sections?: string[]; page: number }[] };

export function html(page: Page): string {
  const rows = page.rows
    .map((r) => `<tr><td class="n">${r.number ?? ""}</td><td><b>${r.name}</b>${(r.sections ?? []).map((s) => `<div class="s">${s}</div>`).join("")}</td><td class="p">${r.page}</td></tr>`)
    .join("");
  return `<!doctype html><meta charset="utf-8"><style>body{font:18px Georgia,serif;margin:48px 64px;color:#222;background:#fff}h1{font-size:22px;text-align:center;margin:0 0 4px}h2{font-size:28px;text-align:center;margin:0 0 28px;letter-spacing:4px}table{width:100%;border-collapse:collapse}td{padding:7px 4px;vertical-align:top}.n{width:40px}.p{width:50px;text-align:right}.s{font-size:15px;margin:3px 0 0 14px;color:#444}</style><h1>${page.title}</h1><h2>${page.heading}</h2><table>${rows}</table>`;
}

if (import.meta.main) {
  const pages: Page[] = (await Bun.file(join(import.meta.dir, "parse_textbook/pages.json")).json()) as Page[];
  const dir = mkdtempSync(join(tmpdir(), "tc-pages-"));
  for (const page of pages) {
    const source = join(dir, `${page.file}.html`);
    writeFileSync(source, html(page));
    const out = join(import.meta.dir, "parse_textbook/pages", `${page.file}.png`);
    const p = Bun.spawnSync([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", `--screenshot=${out}`, "--window-size=900,1200", `file://${source}`], { stderr: "pipe" });
    if (p.exitCode !== 0) throw new Error(`Chrome did not draw ${page.file}: ${p.stderr.toString()}`);
    console.log(`drew ${page.file}.png`);
  }
}
