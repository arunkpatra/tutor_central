/** The syllabus data's words (P22-Syllabi). */
export const SYLLABI = {
  title: "Syllabus data",
  lead: "The chapters and skills of each board, class and subject for classes 8 to 10, as the plan’s chapter check, the mock and the gap report read them. Read only: a correction is a JSON edit under supabase/syllabi, bun syllabi and a migration.",
  board: "Board",
  class: "Class",
  all: "All",
  boards: { cbse: "CBSE", icse: "ICSE", karnataka: "Karnataka" } as Record<string, string>,
  tiles: {
    syllabi: "syllabi",
    boards: (names: string) => `boards: ${names}`,
    classes: (levels: string) => `classes: ${levels}`,
    chapters: "chapters",
  },
  list: "Every syllabus",
  listLead: "A row opens its chapters in place.",
  head: { board: "Board", class: "Class", subject: "Subject", edition: "Edition", chapters: "Chapters", act: "" },
  open: "Open",
  close: "Close",
  line: (edition: string, chapters: number, skills: number, blueprint: string, changed: string) =>
    `${edition} · ${chapters} chapters · ${skills} skills · ${blueprint} · read by the plan’s chapter check, the mock and the gap report · last changed ${changed}`,
  openLabel: (board: string, level: string, subject: string) => `Open ${board} ${level} ${subject}`,
  blueprint: (marks: number | null, sections: number) =>
    `a blueprint (${marks ?? "—"} marks in ${sections} ${sections === 1 ? "section" : "sections"})`,
  noBlueprint: "no blueprint",
  chapterHead: { no: "No", chapter: "Chapter", skills: "Skills", marks: "Blueprint" },
  skills: (names: string[]) =>
    names.length <= 3 ? names.join(" · ") : `${names.slice(0, 3).join(" · ")} · ${names.length} skills`,
  marks: (n: number) => `${n} marks`,
} as const;
