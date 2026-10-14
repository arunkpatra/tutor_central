#!/usr/bin/env bun
/** bun evals/draw-page.ts: draws the golden sets' pages as text on a white page with headless Chrome, so no photo of a
 *  real book, answer sheet or report card is in the repository (D74): the contents pages (parse_textbook), the answer
 *  sheets in a handwriting face (check_paper), the report cards and marked tests (read_marks) and the registers
 *  (scan_register; Phase 21). Run once when
 *  a page changes; the PNGs are committed. The names are the seed's, the rest invented. */
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

/** A page of lines (Phase 21): an answer sheet in a handwriting face, or a report card whose `|` columns are a table. */
export type Sheet = { file: string; title: string; hand: boolean; lines: string[] };

export function sheetHtml(page: Sheet): string {
  const face = page.hand ? "'Bradley Hand','Noteworthy','Segoe Print',cursive" : "Georgia,serif";
  const table = !page.hand && page.lines.some((l) => l.includes("|"));
  const body = table
    ? `<table>${page.lines.map((l, i) => `<tr>${l.split("|").map((c) => (i === 0 ? `<th>${c.trim()}</th>` : `<td>${c.trim()}</td>`)).join("")}</tr>`).join("")}</table>`
    : page.lines.map((l) => `<p>${l}</p>`).join("");
  return `<!doctype html><meta charset="utf-8"><style>body{font:${page.hand ? 26 : 19}px ${face};margin:48px 64px;color:${page.hand ? "#1a2a6c" : "#222"};background:#fff}h1{font:20px Georgia,serif;color:#222;margin:0 0 28px}p{margin:0 0 22px}table{width:100%;border-collapse:collapse}th,td{border:1px solid #888;padding:8px;text-align:left}</style><h1>${page.title}</h1>${body}`;
}

function draw(source: string, out: string, name: string) {
  const p = Bun.spawnSync([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", `--screenshot=${out}`, "--window-size=900,1200", `file://${source}`], { stderr: "pipe" });
  if (p.exitCode !== 0) throw new Error(`Chrome did not draw ${name}: ${p.stderr.toString()}`);
  console.log(`drew ${name}.png`);
}

if (import.meta.main) {
  const dir = mkdtempSync(join(tmpdir(), "tc-pages-"));
  for (const kind of ["check_paper", "read_marks", "scan_register"]) {
    const sheets = (await Bun.file(join(import.meta.dir, kind, "pages.json")).json()) as Sheet[];
    for (const sheet of sheets) {
      const source = join(dir, `${sheet.file}.html`);
      writeFileSync(source, sheetHtml(sheet));
      draw(source, join(import.meta.dir, kind, "pages", `${sheet.file}.png`), sheet.file);
    }
  }
  const pages: Page[] = (await Bun.file(join(import.meta.dir, "parse_textbook/pages.json")).json()) as Page[];
  for (const page of pages) {
    const source = join(dir, `${page.file}.html`);
    writeFileSync(source, html(page));
    const out = join(import.meta.dir, "parse_textbook/pages", `${page.file}.png`);
    draw(source, out, page.file);
  }
}
