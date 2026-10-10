import { expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { readBoard, renderMigration, SyllabusFile } from "./syllabi";

const file: SyllabusFile = {
  board: "cbse",
  classLevel: "9",
  subject: "Mathematics",
  edition: "2026-27",
  source: "NCERT contents page",
  chapters: [{ position: 1, name: "Number Systems", skills: ["Irrational numbers", "Decimal expansions", "Laws of exponents"] }],
  blueprint: null,
};
const loose = (over: object) => ({ ...file, ...over });

test("a syllabus file is validated", () => {
  expect(SyllabusFile.safeParse(file).success).toBe(true);
  expect(SyllabusFile.safeParse(loose({ classLevel: "7" })).success).toBe(false);
  expect(SyllabusFile.safeParse(loose({ subject: "Maths" })).success).toBe(false);
  expect(SyllabusFile.safeParse(loose({ chapters: [{ position: 1, name: "X", skills: [] }] })).success).toBe(false);
  expect(SyllabusFile.safeParse(loose({ chapters: [{ position: 2, name: "X", skills: ["a"] }] })).success).toBe(false);
  expect(SyllabusFile.safeParse(loose({ edition: "x".repeat(41) })).success).toBe(false);
});

test("the migration upserts one row per file with the chapters as jsonb", () => {
  const sql = renderMigration([file]);
  expect(sql).toContain("insert into public.syllabi (board, class_level, subject, edition, chapters, blueprint)");
  expect(sql).toContain("('cbse', '9', 'Mathematics', '2026-27', $json$");
  expect(sql).toContain("on conflict (board, class_level, subject, edition) do update");
  expect(sql).toContain('"name":"Number Systems"');
});

test("quotes in names survive: SQL strings doubled, JSON kept as written", () => {
  const sql = renderMigration([{ ...file, subject: "Social Science", edition: "2025-26 (2026-27 not published)", chapters: [{ position: 1, name: "India's Neighbours", skills: ["a", "b", "c"] }] }]);
  expect(sql).toContain("'Social Science', '2025-26 (2026-27 not published)'");
  expect(sql).toContain(`"name":"India's Neighbours"`);
});

test("a board's files are read in class and subject order, and a file in the wrong folder is refused", () => {
  const root = mkdtempSync(join(tmpdir(), "syllabi-"));
  for (const [cls, subject] of [["10", "Science"], ["9", "Mathematics"], ["9", "English"]] as const) {
    mkdirSync(join(root, "cbse", cls), { recursive: true });
    writeFileSync(join(root, "cbse", cls, `${subject.toLowerCase()}.json`), JSON.stringify(loose({ classLevel: cls, subject })));
  }
  expect(readBoard(root, "cbse").map((f) => `${f.classLevel} ${f.subject}`)).toEqual(["9 English", "9 Mathematics", "10 Science"]);
  writeFileSync(join(root, "cbse", "9", "stray.json"), JSON.stringify(loose({ classLevel: "10" })));
  expect(() => readBoard(root, "cbse")).toThrow("names another board or class");
});
