import { expect, test } from "bun:test";
import { FIGURES } from "../src/claude-fake.js";
import { figurePdf, placeColumns, triangleCorners } from "../src/pdf/figure.js";
import { renderPdf } from "../src/pdf/render.js";
import type { Figure } from "../src/schemas.js";

// The figure's PDF drawn on the server from its spec (D90's last half, D102), the app's words and geometry.
test("each of the seven templates compiles to one page", async () => {
  for (const [kind, sample] of Object.entries(FIGURES)) {
    const { pages } = await renderPdf(figurePdf(sample.figure, { title: `A ${kind}`, caption: sample.caption, foot: "Bright Minds Tuition" }));
    expect({ kind, pages }).toEqual({ kind, pages: 1 });
  }
});

test("a triangle with a right angle is marked, its angles and its sides named, Pythagoras beside whole sides", () => {
  const right: Figure = { kind: "triangle", angles: [90, 53, 37], labels: ["5", "4", "3"] };
  const src = figurePdf(right, { title: "Right triangle", caption: "A 3, 4, 5 triangle." });
  expect(src).toContain(`#"90°";`);
  expect(src).toContain(`#"53°";`);
  expect(src).toContain(`#"4² + 3² = 5²";`);
  expect(src).toContain(`#"16 + 9 = 25";`);
  // The right angle's square, in its corner.
  expect(src).toContain("rect(width: 12pt, height: 12pt");
});

test("the triangle is drawn to its angles: the right angle at the bottom left, each side as the sine across it", () => {
  // Drawn in order: the right angle, then the smaller of the others (37°) at the bottom right, then 53° on top.
  const [a, b, c] = triangleCorners([90, 37, 53]);
  const length = (p: { x: number; y: number }, q: { x: number; y: number }) => Math.hypot(p.x - q.x, p.y - q.y);
  expect(a!.y).toBeCloseTo(b!.y, 6);
  expect(c!.x).toBeCloseTo(a!.x, 6);
  // The base is across from the top corner (53°), the upright across from the bottom right one (37°): the base is longer.
  expect(length(a!, b!) / length(a!, c!)).toBeCloseTo(Math.sin((53 * Math.PI) / 180) / Math.sin((37 * Math.PI) / 180), 6);
});

test("place value names the columns the Indian way, the worth under each, the sum of those not 0", () => {
  expect(placeColumns(347)).toEqual([
    { place: "Hundreds", digit: 3, times: "3 × 100", worth: "300" },
    { place: "Tens", digit: 4, times: "4 × 10", worth: "40" },
    { place: "Ones", digit: 7, times: "7 × 1", worth: "7" },
  ]);
  expect(figurePdf({ kind: "place_value", number: 120304 }, { title: "t", caption: "c" })).toContain(`#"1,00,000 + 20,000 + 300 + 4 = 1,20,304";`);
});

test("the number line, the fraction bar, the unit circle and the food chain say what the app says", () => {
  expect(figurePdf({ kind: "number_line", from: 0, to: 10, step: 1, start: 9, jumps: [-2, -2] }, { title: "t", caption: "c" })).toContain(`#"9 − 4 = 5";`);
  const bar = figurePdf({ kind: "fraction_bar", parts: 4, shaded: 3, label: "3/4" }, { title: "t", caption: "c" });
  expect(bar).toContain(`#"3 of 4 parts shaded";`);
  expect(bar).toContain(`#"3/4 = 0.75";`);
  expect(figurePdf({ kind: "unit_circle", angleDegrees: 30 }, { title: "t", caption: "c" })).toContain(`#"sin 30° = 0.5";`);
  const chain = figurePdf({ kind: "food_chain", links: ["Grass", "Grasshopper", "Frog"] }, { title: "t", caption: "c" });
  expect(chain).toContain(`#"Who eats whom: the arrow points to the eater";`);
  expect(chain).toContain(`#"Producer → consumers";`);
});
