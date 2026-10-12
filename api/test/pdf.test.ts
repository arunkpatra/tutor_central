import { expect, test } from "bun:test";
import { briefPdf } from "../src/pdf/brief.js";
import { mockPdf } from "../src/pdf/mock.js";
import { renderPdf } from "../src/pdf/render.js";
import { sheetPdf } from "../src/pdf/sheet.js";
import { str } from "../src/pdf/typst.js";

// The server's PDFs (D89, D90): Typst with the committed fonts, the phone's layout for each kind.
const SHEET = {
  title: "Balancing equations",
  instructions: "Balance each equation.",
  questions: Array.from({ length: 10 }, (_, i) => ({ number: i + 1, text: `Balance H2 + O2 → H2O, part ${i + 1}.`, answer: "2H2 + O2 → 2H2O" })),
};
const latin1 = (bytes: Uint8Array) => new TextDecoder("latin1").decode(bytes);
const fontsIn = (bytes: Uint8Array) => [...latin1(bytes).matchAll(/\/BaseFont\s*\/(?:[A-Z]{6}\+)?([A-Za-z-]+)/g)].map((m) => (m[1] as string).split("-")[0] as string);

test("a sheet renders as an A4 PDF with its questions; the key takes a page of its own", async () => {
  const { bytes, pages } = await renderPdf(sheetPdf(SHEET, { title: "Balancing equations · set 1" }, false));
  expect(latin1(bytes.slice(0, 5))).toBe("%PDF-");
  expect(latin1(bytes)).toContain("/MediaBox [0 0 595.2756 841.8898]");
  expect(pages).toBe(1);
  expect((await renderPdf(sheetPdf(SHEET, { title: "Balancing equations · set 1" }, true))).pages).toBe(2);
});

test("Devanagari and Kannada shape with the bundled fonts", async () => {
  const { bytes } = await renderPdf(`#set text(font: ("Noto Sans", "Noto Sans Devanagari", "Noto Sans Kannada"))\n${"#"}${str("नमस्ते, ಹೆಮಂತ್")}`);
  expect(fontsIn(bytes)).toEqual(expect.arrayContaining(["NotoSansDevanagari", "NotoSansKannada"]));
});

test("markup in a question is text, not Typst: a hash, maths, a comment, a heading, brackets", async () => {
  const tricky = { ...SHEET, questions: [{ number: 1, text: 'Find #x when $2x = 4$ [hint] // see "page" 2\n= not a heading -- dash \\ slash', answer: "x = 2" }] };
  const src = sheetPdf(tricky, { title: "Tricky · set 1" }, false);
  expect(src).toContain(str(tricky.questions[0]!.text));
  const { pages } = await renderPdf(src);
  expect(pages).toBe(1);
});

test("a mock lists its sections with their marks, its pattern and portions, and the key on its own page", async () => {
  const mock = {
    title: "Science unit test",
    duration_minutes: 60,
    pattern: { marks: 40, duration_minutes: 60 },
    portions: ["Chemical reactions", "Acids"],
    sections: [
      { name: "Section A", marks_each: 1, questions: Array.from({ length: 10 }, (_, i) => ({ number: i + 1, text: `Question ${i + 1}`, marks: 1, answer: "a" })) },
      { name: "Section B", marks_each: 5, questions: Array.from({ length: 6 }, (_, i) => ({ number: i + 11, text: `Long question ${i + 11}`, marks: 5, answer: "b" })) },
    ],
  };
  const src = mockPdf(mock, { title: "Science unit test" }, true);
  expect(src).toContain(str("40 marks · 60 minutes · Chemical reactions and Acids"));
  expect(src).toContain(str("Section B · 5 marks each"));
  const { pages } = await renderPdf(src);
  expect(pages).toBeGreaterThanOrEqual(2);
});

test("a brief renders its four parts", async () => {
  const brief = {
    about: "Reactions rearrange atoms.",
    mistakes: [{ title: "Changing subscripts", how_to_catch: "Ask which number they changed." }],
    worked_example: { problem: "Balance H2 + O2", steps: [{ title: "Count atoms", working: "H: 2, O: 2" }], slip: "Do not change H2O to H2O2." },
    words: ["Atoms are not made or lost."],
  };
  const src = briefPdf(brief, { title: "Your brief · Chemical reactions" });
  for (const words of ["What the chapter is about", "Three common mistakes", "The worked example to use", "Words to say"]) expect(src).toContain(str(words));
  expect((await renderPdf(src)).pages).toBe(1);
});
