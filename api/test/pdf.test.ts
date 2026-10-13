import { expect, test } from "bun:test";
import { briefPdf } from "../src/pdf/brief.js";
import { mockPdf } from "../src/pdf/mock.js";
import { renderPdf, withoutMaths } from "../src/pdf/render.js";
import { sheetPdf } from "../src/pdf/sheet.js";
import { str, t } from "../src/pdf/typst.js";

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

test("markup in a question is text, not Typst: a hash, a comment, a heading, brackets; a formula goes to mitex as a string", async () => {
  const tricky = { ...SHEET, questions: [{ number: 1, text: 'Find #x when $2x = 4$ [hint] // see "page" 2\n= not a heading -- dash \\ slash', answer: "x = 2" }] };
  const src = sheetPdf(tricky, { title: "Tricky · set 1" }, false);
  expect(src).toContain(`#${str("Find #x when ")};#mi(${str("2x = 4")});#${str(' [hint] // see "page" 2\n= not a heading -- dash \\ slash')};`);
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

// Mathematics (D102): mitex in the function's workspace, STIX Two Math for formulae.
const MATHS = {
  title: "Linear equations",
  instructions: "Solve for x.",
  questions: [
    { number: 1, text: "Solve $3x + 5 = 20$.", answer: "$x = 5$" },
    { number: 2, text: "Solve $\\frac{x}{4} - 2 = 1$.", answer: "$x = 12$" },
    { number: 3, text: "Find $x$ when $$2(x + 3) = 5x - 9$$", answer: "$x = 5$" },
  ],
};

test("a sheet with formulae compiles to one page, its words as text, its formulae in STIX Two Math", async () => {
  const { bytes, pages } = await renderPdf(sheetPdf(MATHS, { title: "Linear equations · set 1" }, false));
  expect(pages).toBe(1);
  expect(fontsIn(bytes)).toEqual(expect.arrayContaining(["STIXTwoMath", "NotoSans"]));
});

test("a Devanagari word in a formula renders: it is drawn as words in Noto, outside the maths", async () => {
  const { bytes, pages } = await renderPdf(sheetPdf({ ...MATHS, questions: [{ number: 1, text: "$\\text{आधा} = \\frac{1}{2}$", answer: "$\\frac{1}{2}$" }] }, { title: "आधा · set 1" }, false));
  expect(pages).toBe(1);
  expect(fontsIn(bytes)).toEqual(expect.arrayContaining(["STIXTwoMath", "NotoSansDevanagari"]));
});

test("a formula Typst cannot draw is drawn as its words, and the page is not lost", async () => {
  const src = sheetPdf({ ...MATHS, questions: [{ number: 1, text: "Solve $\\undefinedcommand{x} = 2$.", answer: "x" }] }, { title: "Slip · set 1" }, false);
  const { pages } = await renderPdf(src);
  expect(pages).toBe(1);
  expect(withoutMaths(src)).toContain(`#${str("\\undefinedcommand{x} = 2")};`);
  expect(withoutMaths(src)).not.toContain("#mi(");
});

test("the sheet, mock and brief carry the foot the job names (P20-PDF-Sheet): the centre and the batch, then the page", () => {
  const foot = "Bright Minds Tuition · Class 8";
  expect(sheetPdf(MATHS, { title: "Linear equations · sheet 1", foot }, false)).toContain(`footer: context [#set text(8pt, fill: luma(110)); ${t(foot)} #h(1fr) Page`);
  expect(sheetPdf(MATHS, { title: "Linear equations · sheet 1" }, false)).not.toContain("footer:");
});

test("an inline formula is drawn at the text's size, as the board draws a fraction (math.display)", () => {
  expect(sheetPdf(MATHS, { title: "t" }, false)).toContain("#show math.equation.where(block: false): it => math.display(it)");
});
