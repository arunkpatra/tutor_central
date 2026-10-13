import type { Figure } from "../schemas.js";
import { preamble, t, title } from "./typst.js";

/** A figure's PDF (D90's last half): the seven templates drawn in Typst from the spec on one A4 page, the app's words
 *  and geometry (Artefacts/Figures/*), in print's greys, the caption under it. Every text through `t()`. */
export function figurePdf(figure: Figure, meta: { title: string; caption: string; foot?: string }): string {
  return [preamble(meta.foot), title(meta.title), "#v(18pt)", `#align(center)[#box(width: ${W}pt, height: ${H}pt)[${draw(figure).join("")}]]`, "#v(14pt)", `#align(center)[${t(meta.caption)}]`].join("\n\n");
}

const W = 420;
const H = 280;
const INK = "luma(30)";
const SOFT = "luma(110)";
const SHADE = "luma(205)";
const pt = (n: number) => `${round(n)}pt`;
const round = (n: number) => Math.round(n * 100) / 100;

function draw(f: Figure): string[] {
  switch (f.kind) {
    case "number_line":
      return numberLine(f.from, f.to, f.step, f.start, f.jumps);
    case "fraction_bar":
      return fractionBar(f.parts, f.shaded, f.label);
    case "place_value":
      return placeValue(f.number);
    case "unit_circle":
      return unitCircle(f.angleDegrees);
    case "triangle":
      return triangle(f.angles, f.labels);
    case "labelled_cell":
      return cell(f.cell, f.labels);
    case "food_chain":
      return foodChain(f.links);
  }
}

// --- the pieces, placed from the box's top left ---
const line = (x1: number, y1: number, x2: number, y2: number, stroke = `1pt + ${INK}`) => `#place(top + left, line(start: (${pt(x1)}, ${pt(y1)}), end: (${pt(x2)}, ${pt(y2)}), stroke: ${stroke}))`;
const dot = (x: number, y: number, r = 3) => `#place(top + left, dx: ${pt(x - r)}, dy: ${pt(y - r)}, circle(radius: ${pt(r)}, fill: ${INK}))`;
/** A text centred on a point (or from its left edge with `align: "left"`), as the app's labels. */
function label(x: number, y: number, text: string, opts: { size?: number; bold?: boolean; fill?: string; align?: "center" | "left" | "right"; width?: number } = {}): string {
  const width = opts.width ?? 160;
  const align = opts.align ?? "center";
  const dx = align === "center" ? x - width / 2 : align === "left" ? x : x - width;
  const size = opts.size ?? 9;
  return `#place(top + left, dx: ${pt(dx)}, dy: ${pt(y - size * 0.7)}, box(width: ${pt(width)}, align(${align}, text(${size}pt${opts.bold ? ', weight: "bold"' : ""}, fill: ${opts.fill ?? INK})[${t(text)}])))`;
}

/** 0.5, 0.87, 1, 0: two places at most, never -0 (FigureNumbers.decimal). */
export function decimal(value: number): string {
  const rounded = Math.round(value * 100) / 100;
  return String(rounded === 0 ? 0 : rounded);
}

/** 1,20,304: India's grouping (FigureNumbers.grouped). */
export const grouped = (n: number) => n.toLocaleString("en-IN");

function numberLine(from: number, to: number, step: number, start: number, jumps: number[]): string[] {
  const side = 24;
  const axis = 170;
  const x = (v: number) => side + ((v - from) / Math.max(to - from, 1)) * (W - side * 2);
  const total = jumps.reduce((a, b) => a + b, 0);
  const out = [label(W / 2, 24, `${start} ${total < 0 ? "−" : "+"} ${Math.abs(total)} = ${start + total}`, { size: 11, bold: true }), line(x(from), axis, x(to), axis, `1.4pt + ${INK}`)];
  for (let v = from; v <= to; v += step) out.push(line(x(v), axis - 5, x(v), axis + 5));
  let at = start;
  for (const jump of jumps) {
    const [x1, x2] = [x(at), x(at + jump)];
    out.push(`#place(top + left, curve(stroke: 1.2pt + ${SOFT}, curve.move((${pt(x1)}, ${pt(axis - 4)})), curve.quad((${pt((x1 + x2) / 2)}, ${pt(axis - 70)}), (${pt(x2)}, ${pt(axis - 4)}))))`);
    const tip = x2 > x1 ? -1 : 1;
    out.push(`#place(top + left, polygon(fill: ${SOFT}, (${pt(x2)}, ${pt(axis - 4)}), (${pt(x2 + tip * 7)}, ${pt(axis - 12)}), (${pt(x2 + tip * 1)}, ${pt(axis - 14)})))`);
    at += jump;
  }
  out.push(dot(x(start), axis, 4), dot(x(at), axis, 4));
  for (const v of [...new Set([from, to, start, at])]) out.push(label(x(v), axis + 22, String(v), { size: 10, bold: v === start || v === at }));
  return out;
}

function fractionBar(parts: number, shaded: number, text: string): string[] {
  const [left, top, width, height] = [30, 110, W - 60, 46];
  const cell = width / Math.max(parts, 1);
  const out = [label(W / 2, 40, `${shaded} of ${parts} parts shaded`, { size: 11, bold: true })];
  for (let i = 0; i < parts; i++) {
    out.push(`#place(top + left, dx: ${pt(left + i * cell)}, dy: ${pt(top)}, rect(width: ${pt(cell)}, height: ${pt(height)}, fill: ${i < shaded ? SHADE : "white"}, stroke: 1pt + ${INK}))`);
  }
  out.push(label(W / 2, top + height + 40, `${text} = ${decimal(shaded / Math.max(parts, 1))}`, { size: 12 }));
  return out;
}

const PLACES = ["Ones", "Tens", "Hundreds", "Thousands", "Ten thousands", "Lakhs", "Ten lakhs"];

/** The columns, the highest place first; 0 is one column, Ones (PlaceValueFigure.columns). */
export function placeColumns(number: number): { place: string; digit: number; times: string; worth: string }[] {
  const digits = String(number).split("").map(Number);
  return digits.map((digit, i) => {
    const power = digits.length - 1 - i;
    const unit = 10 ** power;
    return { place: PLACES[Math.min(power, PLACES.length - 1)] as string, digit, times: `${digit} × ${grouped(unit)}`, worth: grouped(digit * unit) };
  });
}

function placeValue(number: number): string[] {
  const columns = placeColumns(number);
  const width = Math.min(70, (W - 20) / columns.length);
  const left = (W - width * columns.length) / 2;
  const out: string[] = [];
  columns.forEach((c, i) => {
    const x = left + width * i + width / 2;
    out.push(label(x, 50, c.place, { size: 8, fill: SOFT, width }));
    out.push(`#place(top + left, dx: ${pt(x - width / 2 + 4)}, dy: 66pt, rect(width: ${pt(width - 8)}, height: 56pt, stroke: 1pt + ${INK}))`);
    out.push(label(x, 98, String(c.digit), { size: 26, bold: true, width }));
    out.push(label(x, 142, c.times, { size: 8, fill: SOFT, width }));
  });
  const worths = columns.filter((c) => c.digit !== 0).map((c) => c.worth);
  out.push(label(W / 2, 200, `${worths.length ? worths.join(" + ") : "0"} = ${grouped(number)}`, { size: 11, bold: true, width: W }));
  return out;
}

function unitCircle(angle: number): string[] {
  const [cx, cy, r] = [150, 140, 105];
  const radians = (angle * Math.PI) / 180;
  const [px, py] = [cx + r * Math.cos(radians), cy - r * Math.sin(radians)];
  const [sine, cosine] = [decimal(Math.sin(radians)), decimal(Math.cos(radians))];
  return [
    line(cx - r - 14, cy, cx + r + 14, cy, `0.8pt + ${SOFT}`),
    line(cx, cy - r - 14, cx, cy + r + 14, `0.8pt + ${SOFT}`),
    `#place(top + left, dx: ${pt(cx - r)}, dy: ${pt(cy - r)}, circle(radius: ${pt(r)}, stroke: 1.2pt + ${INK}))`,
    line(cx, cy, px, py, `1.8pt + ${INK}`),
    line(px, py, px, cy, `(paint: ${INK}, thickness: 1pt, dash: "dashed")`),
    dot(px, py, 3.5),
    label(px + (px >= cx ? 46 : -46), py + (py <= cy ? -12 : 12), `(${cosine}, ${sine})`, { size: 10, bold: true, width: 90 }),
    label(px + (px >= cx ? 26 : -26), (py + cy) / 2, `sin ${angle}°`, { size: 8, fill: SOFT, width: 60 }),
    label(cx + 26, cy + 14, `${angle}°`, { size: 8, fill: SOFT, width: 40 }),
    label(cx + r + 24, cy - 14, `cos ${angle}° = ${cosine}`, { size: 10, bold: true, align: "left", width: 130 }),
    label(cx + r + 24, cy + 6, `sin ${angle}° = ${sine}`, { size: 10, bold: true, align: "left", width: 130 }),
  ];
}

type Point = { x: number; y: number };

/** The corners on a unit base, in drawing order (TriangleFigure): the right angle, or the largest, first at the origin;
 *  the smaller of the others along the base; the third up at the first's angle. Each side is the sine of the angle
 *  across from it. */
export function triangleCorners(ordered: number[]): Point[] {
  const [a, b, c] = ordered.map((d) => (d * Math.PI) / 180) as [number, number, number];
  const base = Math.sin(c);
  const rise = Math.sin(b);
  return [
    { x: 0, y: 0 },
    { x: base, y: 0 },
    { x: rise * Math.cos(a), y: rise * Math.sin(a) },
  ];
}

/** "4² + 3² = 5²" and "16 + 9 = 25": only for a right angle whose three sides are whole numbers that keep the rule. */
function pythagoras(angles: number[], labels: string[]): string[] | null {
  const right = angles.indexOf(90);
  const numbers = labels.map((l) => (/^\d+$/.test(l.trim()) ? Number(l) : Number.NaN));
  if (right === -1 || numbers.some(Number.isNaN)) return null;
  const legs = numbers.filter((_, i) => i !== right);
  const long = numbers[right] as number;
  if (legs.reduce((s, n) => s + n * n, 0) !== long * long) return null;
  return [`${legs.map((n) => `${n}²`).join(" + ")} = ${long}²`, `${legs.map((n) => n * n).join(" + ")} = ${long * long}`];
}

function triangle(angles: number[], labels: string[]): string[] {
  const first = angles.indexOf(90) !== -1 ? angles.indexOf(90) : angles.indexOf(Math.max(...angles));
  const others = [0, 1, 2].filter((i) => i !== first).sort((i, j) => (angles[i] as number) - (angles[j] as number));
  const order = [first, ...others];
  const unit = triangleCorners(order.map((i) => angles[i] as number));
  const rule = pythagoras(angles, labels);
  const room = rule ? 280 : W - 60;
  const span = { w: Math.max(...unit.map((p) => p.x)) - Math.min(0, ...unit.map((p) => p.x)), h: Math.max(...unit.map((p) => p.y)) };
  const scale = Math.min(room / span.w, (H - 70) / span.h);
  const left = (rule ? 30 : (W - span.w * scale) / 2) - Math.min(0, ...unit.map((p) => p.x)) * scale;
  const bottom = H - 34;
  const at = unit.map((p) => ({ x: left + p.x * scale, y: bottom - p.y * scale }));
  const [p0, p1, p2] = at as [Point, Point, Point];
  const centre = { x: (p0.x + p1.x + p2.x) / 3, y: (p0.y + p1.y + p2.y) / 3 };
  const out = [`#place(top + left, polygon(fill: luma(235), stroke: 1.4pt + ${INK}, ${at.map((p) => `(${pt(p.x)}, ${pt(p.y)})`).join(", ")}))`];
  if (angles[first] === 90) {
    // The right angle: a small square in its corner.
    const s = 12;
    out.push(`#place(top + left, dx: ${pt(p0.x)}, dy: ${pt(p0.y - s)}, rect(width: ${pt(s)}, height: ${pt(s)}, stroke: 1pt + ${INK}))`);
  }
  order.forEach((index, k) => {
    const corner = at[k] as Point;
    const inward = { x: corner.x + (centre.x - corner.x) * 0.28, y: corner.y + (centre.y - corner.y) * 0.28 };
    out.push(label(inward.x, inward.y, `${angles[index]}°`, { size: 9, fill: SOFT, width: 50 }));
    // The side across from this corner joins the other two; its name sits outside its middle.
    const [q1, q2] = at.filter((_, j) => j !== k) as [Point, Point];
    const middle = { x: (q1.x + q2.x) / 2, y: (q1.y + q2.y) / 2 };
    const away = { x: middle.x - centre.x, y: middle.y - centre.y };
    const length = Math.hypot(away.x, away.y) || 1;
    out.push(label(middle.x + (away.x / length) * 16, middle.y + (away.y / length) * 16, labels[index] ?? "", { size: 11, bold: true, width: 90 }));
  });
  if (rule) {
    out.push(label(330, 110, rule[0] as string, { size: 11, bold: true, width: 160 }), label(330, 132, rule[1] as string, { size: 10, fill: SOFT, width: 160 }));
  }
  return out;
}

/** The part a chapter's name means, by its words (LabelledCellFigure). */
function partOf(name: string): "wall" | "membrane" | "nucleus" | "vacuole" | "chloroplast" | "cytoplasm" {
  const words = name.toLowerCase();
  if (words.includes("wall")) return "wall";
  if (words.includes("membrane")) return "membrane";
  if (words.includes("nucle")) return "nucleus";
  if (words.includes("vacuole")) return "vacuole";
  if (words.includes("chloroplast") || words.includes("plastid")) return "chloroplast";
  return "cytoplasm";
}

function cell(kind: "plant" | "animal", names: string[]): string[] {
  const out: string[] = [];
  const points: Record<string, Point> = kind === "plant"
    ? { wall: { x: 244, y: 64 }, membrane: { x: 234, y: 150 }, nucleus: { x: 140, y: 108 }, vacuole: { x: 212, y: 176 }, chloroplast: { x: 214, y: 86 }, cytoplasm: { x: 206, y: 124 } }
    : { wall: { x: 258, y: 140 }, membrane: { x: 258, y: 140 }, nucleus: { x: 164, y: 126 }, vacuole: { x: 220, y: 176 }, chloroplast: { x: 220, y: 176 }, cytoplasm: { x: 222, y: 100 } };
  if (kind === "plant") {
    out.push(`#place(top + left, dx: 24pt, dy: 40pt, rect(width: 220pt, height: 200pt, radius: 10pt, stroke: 3pt + ${INK}))`);
    out.push(`#place(top + left, dx: 34pt, dy: 50pt, rect(width: 200pt, height: 180pt, radius: 6pt, stroke: 1pt + ${INK}))`);
    out.push(`#place(top + left, dx: 130pt, dy: 136pt, ellipse(width: 90pt, height: 74pt, fill: luma(240), stroke: 1pt + ${SOFT}))`);
    for (const [x, y] of [[196, 80], [60, 170], [190, 206], [64, 66]] as const) out.push(`#place(top + left, dx: ${pt(x)}, dy: ${pt(y)}, ellipse(width: 24pt, height: 12pt, fill: ${SHADE}, stroke: 0.8pt + ${INK}))`);
    out.push(`#place(top + left, dx: 96pt, dy: 88pt, circle(radius: 24pt, fill: ${SHADE}, stroke: 1pt + ${INK}))`);
  } else {
    out.push(`#place(top + left, dx: 30pt, dy: 50pt, ellipse(width: 230pt, height: 180pt, stroke: 1.4pt + ${INK}))`);
    out.push(`#place(top + left, dx: 116pt, dy: 106pt, circle(radius: 24pt, fill: ${SHADE}, stroke: 1pt + ${INK}))`);
  }
  const step = (H - 60) / Math.max(names.length, 1);
  names.forEach((name, i) => {
    const y = 40 + step * (i + 0.5);
    const target = points[partOf(name)] as Point;
    out.push(line(300, y, target.x, target.y, `0.8pt + ${SOFT}`), dot(target.x, target.y, 2));
    out.push(label(306, y, name, { size: 10, bold: true, align: "left", width: 114 }));
  });
  return out;
}

function foodChain(links: string[]): string[] {
  const box = Math.min(74, (W - 20 * (links.length - 1)) / links.length);
  const gap = (W - box * links.length) / Math.max(links.length - 1, 1);
  const y = 110;
  const out = [label(W / 2, 40, "Who eats whom: the arrow points to the eater", { size: 11, bold: true, width: W })];
  links.forEach((name, i) => {
    const x = i * (box + gap);
    out.push(`#place(top + left, dx: ${pt(x)}, dy: ${pt(y)}, rect(width: ${pt(box)}, height: 54pt, radius: 6pt, fill: ${i === 0 ? SHADE : "white"}, stroke: 1pt + ${INK}))`);
    out.push(label(x + box / 2, y + 27, name, { size: 9, bold: true, width: box - 6 }));
    if (i < links.length - 1) {
      const [x1, x2] = [x + box + 4, x + box + gap - 4];
      out.push(line(x1, y + 27, x2 - 6, y + 27, `1.2pt + ${INK}`), `#place(top + left, polygon(fill: ${INK}, (${pt(x2)}, ${pt(y + 27)}), (${pt(x2 - 8)}, ${pt(y + 22)}), (${pt(x2 - 8)}, ${pt(y + 32)})))`);
    }
  });
  out.push(label(W / 2, y + 90, "Producer → consumers", { size: 10, fill: SOFT, width: W }));
  return out;
}

