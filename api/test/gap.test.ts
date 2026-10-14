import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { tallies } from "../src/plan/gap.js";
import { weakestSkills } from "../src/plan/exam-prep.js";

// The gap report's tallies (Domain's GapTallies, ported for the exam job, D106), held equal to the app's by the shared
// case file (tools/contract/gap-cases.json; DomainTests/GapCasesTests reads its copy).
type GapCase = {
  name: string;
  mock: { number: number; marks: number; skill: string }[];
  marks: { number: number; marks: number; note: string }[];
  tallies: { skill: string; right: number; of: number; note: string | null }[];
  weakest: string[];
  count?: number;
};
const file = JSON.parse(readFileSync(join(import.meta.dir, "../../tools/contract/gap-cases.json"), "utf8")) as { cases: GapCase[] };

test("every shared gap case tallies and picks the weakest as the app does", () => {
  expect(file.cases.length).toBeGreaterThanOrEqual(8);
  for (const c of file.cases) {
    const got = tallies(c.marks, { sections: [{ questions: c.mock }] });
    expect({ name: c.name, tallies: got.map((t) => ({ ...t, note: t.note ?? null })) }).toEqual({ name: c.name, tallies: c.tallies });
    expect({ name: c.name, weakest: weakestSkills(got, c.count ?? 6) }).toEqual({ name: c.name, weakest: c.weakest });
  }
});
