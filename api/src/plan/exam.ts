import { catchUp, MAX_GROUPS } from "./rules.js";
import { type ClassLevel, CLASS_LEVELS, type PlanGroup, type PlanInput, type PlanLine, type Revision, type Student } from "./types.js";

/** The plan in exam mode (PlanRules+Exam.swift; docs/spec-v2.md section 6.6): students of one exam within the window form
 *  a group of their own, nearest exam first, with revision lines from the day's portion. */
export const REVISION_PREFIX = "Revise: ";
/** The set's line on the mock day: the mock is the set. */
export const MOCK_LINE = "The mock";
/** `plan_items.words`' limit. */
export const WORDS_LIMIT = 200;

/** At most 200 scalars, cut at a word, with no trailing space, comma or " ·". */
export function cut(words: string): string {
  const scalars = [...words];
  if (scalars.length <= WORDS_LIMIT) return words;
  let text = scalars.slice(0, WORDS_LIMIT).join("");
  const space = text.lastIndexOf(" ");
  if (space >= 0) text = text.slice(0, space);
  return trim(text, " ·,;");
}

function trim(text: string, chars: string): string {
  let start = 0;
  let end = text.length;
  while (start < end && chars.includes(text[start] as string)) start += 1;
  while (end > start && chars.includes(text[end - 1] as string)) end -= 1;
  return text.slice(start, end);
}

/** The teach line's words for a student revising: the day's portion, the mock with its pattern, the gap report's line
 *  after the mock. */
export function revisionTeach(revision: Revision): string {
  switch (revision.day.kind) {
    case "revise":
      return REVISION_PREFIX + revision.day.title;
    case "mock":
      return [MOCK_LINE, revision.pattern ? `${revision.pattern.marks} marks · ${revision.pattern.durationMinutes} minutes` : undefined]
        .filter((part): part is string => part !== undefined)
        .join(" · ");
    case "afterMock":
      return revision.gapLine ?? "Revise: what the mock showed";
    case "exam":
      return "The test today";
  }
}

export const byName = (a: Student, b: Student) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0);

/** Distinct, ascending (the head's "Class 8 · 3 students"). */
export function levels(members: Student[]): ClassLevel[] {
  const seen = new Set(members.flatMap((m) => (m.classLevel ? [m.classLevel] : [])));
  return CLASS_LEVELS.filter((level) => seen.has(level));
}

/** The students of each exam, nearest exam first (ties by title, then the item's id as Swift writes it), by name; at most
 *  two groups when other students remain (a level group is left for them), else three. Students of a later exam stay in
 *  the level cut. */
export function examGroups(students: Student[], input: PlanInput): Student[][] {
  const revising = students.filter((s) => input.revisions[s.id] !== undefined);
  const byItem = new Map<string, Student[]>();
  for (const s of revising) {
    const item = (input.revisions[s.id] as Revision).itemID;
    byItem.set(item, [...(byItem.get(item) ?? []), s]);
  }
  const key = (members: Student[]) => {
    const r = input.revisions[(members[0] as Student).id] as Revision;
    return [r.examDate, r.title, r.itemID.toUpperCase()] as const;
  };
  const ordered = [...byItem.values()].sort((a, b) => {
    const [x, y] = [key(a), key(b)];
    for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return (x[i] as string) < (y[i] as string) ? -1 : 1;
    return 0;
  });
  const cap = students.length > revising.length ? MAX_GROUPS - 1 : MAX_GROUPS;
  return ordered.slice(0, cap).map((members) => [...members].sort(byName));
}

export function examGroup(number: number, members: Student[], input: PlanInput): PlanGroup {
  const revision = members[0] ? input.revisions[members[0].id] : undefined;
  return {
    number,
    subject: revision?.subject ?? "",
    chapter: revision?.title ?? "",
    skill: revision?.day.title ?? "",
    classLevels: levels(members),
    memberIDs: members.map((m) => m.id),
    skillID: undefined,
    examItemID: revision?.itemID,
  };
}

/** A revising student's lines: a catch-up first when they missed the last two, the day's revision, the set (the mock on
 *  the mock day), Check 3, the revision sheet (none on the mock day). */
export function examLines(student: Student, group: PlanGroup, input: PlanInput): PlanLine[] {
  const revision = input.revisions[student.id];
  if (!revision) return [];
  const line = (kind: PlanLine["kind"], words: string): PlanLine => ({
    studentID: student.id,
    groupNo: group.number,
    kind,
    skillID: revision.day.skillIDs[0],
    words,
    personalChecks: false,
  });
  const lines: PlanLine[] = [];
  const missed = catchUp(student, input);
  if (missed) lines.push(line("catch_up", `${missed} · then ${revision.day.title}`));
  lines.push(line("teach", revisionTeach(revision)));
  const mockDay = revision.day.kind === "mock";
  lines.push(line("practise", mockDay ? MOCK_LINE : `Revision set ${revision.setNumber}`));
  lines.push(line("check", "Check 3"));
  if (!mockDay) lines.push(line("homework", `Revision sheet ${revision.setNumber}`));
  return lines;
}
