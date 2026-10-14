import { expect, test } from "bun:test";
import { SAMPLE } from "../src/claude-fake.js";
import { paperPdf } from "../src/pdf/paper.js";
import { renderPdf } from "../src/pdf/render.js";
import { str } from "../src/pdf/typst.js";
import type { PaperOutput, QuestionSetOutput } from "../src/schemas.js";

// V1's results on the server's PDFs (Phase 21 decision 9, P21-PDF-Paper): the paper's sections with their marks each
// and the key on its own last page; homework and a worksheet numbered, the key unless a worksheet leaves it out.
const meta = { title: "Quadratic equations · question paper", subtitle: "Class 10 · Mathematics · 20 marks", foot: "Bright Minds Tuition" };

test("a paper's PDF has its sections with their marks each, and the key on the last page", async () => {
  const src = paperPdf({ kind: "paper", output: SAMPLE.paper as PaperOutput }, meta, true);
  expect(src).toContain(str("Section A"));
  expect(src).toContain(str("1 mark each"));
  expect(src).toContain(str("4 marks each"));
  expect(src).toContain(str("Answer key"));
  expect(src).toContain(str("Class 10 · Mathematics · 20 marks"));
  const { pages } = await renderPdf(src);
  expect(pages).toBe(2);
});

test("a worksheet's PDF without answers has one page; homework keeps its key", async () => {
  const set = SAMPLE.worksheet as QuestionSetOutput;
  const without = paperPdf({ kind: "worksheet", output: set }, { ...meta, title: "Linear equations · worksheet" }, false);
  expect(without).not.toContain(str("Answer key"));
  expect((await renderPdf(without)).pages).toBe(1);
  const work = paperPdf({ kind: "homework", output: SAMPLE.homework as QuestionSetOutput }, { ...meta, title: "Cells · homework" }, true);
  expect(work).toContain(str("Answer key"));
  expect(work).toContain(str("Answer in two or three sentences each."));
});
