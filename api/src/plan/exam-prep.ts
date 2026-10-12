import { addDays, istDay, weekday } from "./dates.js";
import { cut } from "./exam.js";
import type { Chapter, Revision, Skill } from "./types.js";

/** The exam window and the split of portions across the batch's days (Domain's ExamPreparation, SchoolItemRules'
 *  nearest exam and HolidayRules; docs/spec-v2.md section 6.6, plan/phase-13-plan.md decisions 8, 9 and 17), as the
 *  phone's plan maker read them for each member (PlanMaker+Exam). */
export const WINDOW_DAYS = 14;
export const MOCK_DAYS_BEFORE = 2;

/** A school item as the split reads it (`school_items`): who it reaches, its days, its portions, when it came. */
export type PrepItem = {
  id: string;
  kind: "exam" | "homework" | "notice" | "holiday";
  audience: { student?: string; school?: string; classLevel?: string };
  title: string;
  subject?: string;
  date: string;
  endDate?: string;
  portions?: string;
  /** An instant (ISO 8601). */
  receivedAt: string;
  windowDays?: number;
};
export type PrepStudent = { id: string; name: string; classLevel?: string; schoolID?: string };
export type PrepDay = { day: string; kind: "revise" | "mock" | "afterMock" | "exam"; index?: number; title: string; skills: string[]; skillIDs: string[] };

/** Whether the item is for the student: their own, their school's class, or their whole school. */
export function reachesStudent(item: PrepItem, student: PrepStudent): boolean {
  const { student: own, school, classLevel } = item.audience;
  if (own) return own === student.id;
  if (!school) return false;
  if (classLevel) return student.schoolID === school && student.classLevel === classLevel;
  return student.schoolID === school;
}

const lastDay = (item: PrepItem) => (item.endDate && item.endDate > item.date ? item.endDate : item.date);
export const windowOf = (exam: PrepItem) => exam.windowDays ?? WINDOW_DAYS;

/** From the window's first day to the exam day. */
export function withinWindow(exam: PrepItem, today: string): boolean {
  return exam.kind === "exam" && today >= addDays(exam.date, -windowOf(exam)) && today <= exam.date;
}

export function onHoliday(student: PrepStudent, day: string, items: PrepItem[]): boolean {
  return items.some((i) => i.kind === "holiday" && i.date <= day && day <= lastDay(i) && reachesStudent(i, student));
}

const byDateThenTitle = (a: PrepItem, b: PrepItem) => (a.date !== b.date ? (a.date < b.date ? -1 : 1) : a.title < b.title ? -1 : a.title > b.title ? 1 : 0);

/** The exam that drives the student's revision: the earliest reaching them within its window (ties by title). */
export function nearestExam(student: PrepStudent, items: PrepItem[], today: string): PrepItem | undefined {
  return items.filter((i) => i.kind === "exam" && withinWindow(i, today) && reachesStudent(i, student)).sort(byDateThenTitle)[0];
}

/** Where the split starts when it is read again each day: the day the item came, or the window's first day when it came
 *  earlier, never after today. */
export function prepStart(exam: PrepItem, today: string): string {
  const windowStart = addDays(exam.date, -windowOf(exam));
  const came = istDay(new Date(exam.receivedAt));
  const later = windowStart > came ? windowStart : came;
  return today < later ? today : later;
}

const MARKER = /\bch(?:apter)?\.?\s*\d+\b/gi;

/** "Ch 1 Chemical reactions Ch 2 Acids" in two parts, each starting at its marker. */
function splitAtMarkers(text: string): string[] {
  const starts = [...text.matchAll(MARKER)].map((m) => m.index as number).filter((i) => i !== 0);
  if (starts.length === 0) return [text];
  const parts: string[] = [];
  let from = 0;
  for (const start of starts) {
    parts.push(text.slice(from, start));
    from = start;
  }
  parts.push(text.slice(from));
  return parts;
}

/** "Ch 1 Chemical reactions" → "Chemical reactions"; "Ch 1" alone stays. */
function dropMarker(text: string): string {
  const match = new RegExp(`^${MARKER.source}`, "i").exec(text);
  if (!match) return text;
  const rest = text.slice(match[0].length).trim();
  return rest === "" ? text : rest;
}

/** The portions cut into parts at "·", ";", new lines and "Ch n" markers, each without its "Ch n" prefix when words
 *  follow it. */
export function portionsOf(text: string): string[] {
  return text
    .split(/[·;\n]/)
    .flatMap(splitAtMarkers)
    .map((p) => dropMarker(p.trim()))
    .filter((p) => p !== "");
}

/** The chapter numbers a part gives after "Ch", "Chapter" or "Chapters": a list, or a range with "to" or "-". */
export function chapterNumbers(text: string): Set<number> {
  const numbers = new Set<number>();
  for (const match of text.matchAll(/\bch(?:apters?)?\.?\s*(\d+(?:\s*(?:,|and|&|to|-)\s*\d+)*)/gi)) {
    const run = match[1] as string;
    const values = [...run.matchAll(/\d+/g)].map((m) => Number(m[0]));
    const [low, high] = values;
    if ((run.includes("to") || run.includes("-")) && values.length === 2 && low !== undefined && high !== undefined && low <= high) {
      for (let n = low; n <= high; n++) numbers.add(n);
    } else for (const v of values) numbers.add(v);
  }
  return numbers;
}

/** The student's chapters a part names: either name contains the other, ignoring case and a "Ch n" prefix; else the
 *  chapters whose numbers it gives. */
export function matching(portion: string, chapters: Chapter[]): Chapter[] {
  const words = dropMarker(portion.trim()).toLowerCase();
  if (words === "") return [];
  const byPosition = (a: Chapter, b: Chapter) => a.position - b.position;
  const named = chapters.filter((c) => {
    const name = c.name.toLowerCase();
    return words.includes(name) || name.includes(words);
  });
  if (named.length > 0) return named.sort(byPosition);
  const positions = chapterNumbers(portion);
  return chapters.filter((c) => positions.has(c.position)).sort(byPosition);
}

/** n split into k sizes as even as possible, the larger first: 4 into 3 is 2, 1, 1. */
export function sizes(total: number, parts: number): number[] {
  if (parts <= 0) return [];
  return Array.from({ length: parts }, (_, i) => Math.floor(total / parts) + (i < total % parts ? 1 : 0));
}

const runWords = (run: number, count: number) => (count === 2 ? (run === 0 ? "first half" : "second half") : `part ${run + 1} of ${count}`);

/** The parts over the revision days in order: a part over k days in k runs of its skills, or several parts on one day
 *  when the days are fewer. */
function spread(parts: string[], days: string[], chapters: Chapter[], skills: Skill[]): PrepDay[] {
  if (days.length === 0) return [];
  const named = parts.map((part) => ({
    title: part,
    skills: matching(part, chapters).flatMap((c) => skills.filter((s) => s.chapterID === c.id).sort((a, b) => a.position - b.position)),
  }));
  const result: PrepDay[] = [];
  if (days.length >= parts.length) {
    const shares = sizes(days.length, parts.length);
    let next = 0;
    named.forEach((part, p) => {
      const share = shares[p] as number;
      const runs = sizes(part.skills.length, share);
      let start = 0;
      for (let run = 0; run < share; run++) {
        const size = runs[run] as number;
        const slice = size > 0 ? part.skills.slice(start, start + size) : part.skills;
        start += size;
        result.push({
          day: days[next] as string,
          kind: "revise",
          index: next + 1,
          title: share === 1 ? part.title : `${part.title} · ${runWords(run, share)}`,
          skills: slice.length === 0 ? [part.title] : slice.map((s) => s.name),
          skillIDs: slice.map((s) => s.id),
        });
        next += 1;
      }
    });
  } else {
    let start = 0;
    sizes(parts.length, days.length).forEach((size, index) => {
      const group = named.slice(start, start + size);
      start += size;
      result.push({
        day: days[index] as string,
        kind: "revise",
        index: index + 1,
        title: group.map((g) => g.title).join(" · "),
        skills: group.flatMap((g) => (g.skills.length === 0 ? [g.title] : g.skills.map((s) => s.name))),
        skillIDs: group.flatMap((g) => g.skills.map((s) => s.id)),
      });
    });
  }
  return result;
}

/** The days from the split's start to the exam for one student of the batch: the batch's meeting days before the exam,
 *  less the student's holidays, then the exam day. With three days or more the mock takes the last meeting day at least
 *  two days before the exam (one revision day before it at least) and the days after it are the gap report's; with
 *  fewer, every day is revision (ExamPreparation.days). */
export function examDays(exam: PrepItem, student: PrepStudent, chapters: Chapter[], skills: Skill[], context: { meetingDays: number[]; start: string; holidays: PrepItem[] }): PrepDay[] {
  const count = Math.max(0, Math.round((Date.parse(exam.date) - Date.parse(context.start)) / 86_400_000));
  const meeting = Array.from({ length: count }, (_, i) => addDays(context.start, i))
    .filter((d) => context.meetingDays.includes(weekday(d)))
    .filter((d) => !onHoliday(student, d, context.holidays));
  let revision = meeting;
  let after: string[] = [];
  let mockDay: string | undefined;
  if (meeting.length >= 3) {
    const latest = addDays(exam.date, -MOCK_DAYS_BEFORE);
    let last = -1;
    meeting.forEach((d, i) => {
      if (d <= latest) last = i;
    });
    const index = last >= 0 ? Math.max(last, 1) : meeting.length - 1;
    mockDay = meeting[index];
    revision = meeting.slice(0, index);
    after = meeting.slice(index + 1);
  }
  const parts = portionsOf(exam.portions ?? exam.title);
  const result = spread(parts.length === 0 ? [exam.title] : parts, revision, chapters, skills);
  if (mockDay !== undefined) result.push({ day: mockDay, kind: "mock", title: "The mock", skills: [], skillIDs: [] });
  for (const d of after) result.push({ day: d, kind: "afterMock", title: "What the mock showed", skills: [], skillIDs: [] });
  result.push({ day: exam.date, kind: "exam", title: "The test", skills: [], skillIDs: [] });
  return result;
}

/** One student's exam on the batch's day, as the plan maker read it: on holiday, else the nearest exam's split from its
 *  start (the shared cases' shape). */
export function examDay(input: { items: PrepItem[]; student: PrepStudent; chapters: Chapter[]; skills: Skill[]; meetingDays: number[]; today: string }): {
  nearest?: string;
  onHoliday: boolean;
  start?: string;
  days: PrepDay[];
} {
  const holidays = input.items.filter((i) => i.kind === "holiday");
  if (onHoliday(input.student, input.today, holidays)) return { onHoliday: true, days: [] };
  const exam = nearestExam(input.student, input.items, input.today);
  if (!exam) return { onHoliday: false, days: [] };
  const start = prepStart(exam, input.today);
  const days = examDays(exam, input.student, input.chapters, input.skills, { meetingDays: input.meetingDays, start, holidays });
  return { nearest: exam.id, onHoliday: false, start, days };
}

/** A gap report kept for a student's exam (the gap report's content), for the days after the mock. */
export type GapReport = { schoolItemID: string; days: { line: string }[]; bySkill: { skill: string; right: number; of: number }[] };

/** The weakest skills that lost marks, lowest share first (ties in the mock's order) (GapTallies.weakest). */
export function weakestSkills(tallies: GapReport["bySkill"], count: number): string[] {
  return tallies
    .map((t, offset) => ({ t, offset }))
    .filter(({ t }) => t.right < t.of)
    .sort((a, b) => {
      const [x, y] = [a.t.right / a.t.of, b.t.right / b.t.of];
      return x !== y ? x - y : a.offset - b.offset;
    })
    .slice(0, count)
    .map(({ t }) => t.skill);
}

/** Each member's revision line for the batch's day and the members on holiday (PlanMaker.exams): the nearest exam in its
 *  window, its preparation day for the date from the split's start; the test day itself has no revision. After the mock,
 *  the used gap report's line for that day and its weakest skills. */
export function revisionLines(input: {
  members: PrepStudent[];
  items: PrepItem[];
  meetingDays: number[];
  date: string;
  chapters: Record<string, Chapter[]>;
  skills: Record<string, Skill[]>;
  gapReports: Record<string, GapReport>;
}): { revisions: Record<string, Revision>; holidays: string[] } {
  const holidayItems = input.items.filter((i) => i.kind === "holiday");
  const holidays = input.members.filter((m) => onHoliday(m, input.date, holidayItems)).map((m) => m.id);
  const revisions: Record<string, Revision> = {};
  for (const student of input.members) {
    if (holidays.includes(student.id)) continue;
    const exam = nearestExam(student, input.items, input.date);
    if (!exam) continue;
    const days = examDays(exam, student, input.chapters[student.id] ?? [], input.skills[student.id] ?? [], {
      meetingDays: input.meetingDays,
      start: prepStart(exam, input.date),
      holidays: holidayItems,
    });
    const day = days.find((d) => d.day === input.date);
    if (!day || day.kind === "exam") continue;
    const own = input.gapReports[student.id];
    const report = own && own.schoolItemID === exam.id ? own : undefined;
    const afterIndex = days.filter((d) => d.kind === "afterMock").findIndex((d) => d.day === day.day);
    const gapLine = afterIndex >= 0 && report && afterIndex < report.days.length ? cut((report.days[afterIndex] as { line: string }).line) : undefined;
    const revising = days.filter((d) => d.kind === "revise").length;
    const setNumber = afterIndex >= 0 ? revising + afterIndex + 1 : day.kind === "revise" ? (day.index ?? 1) : 1;
    revisions[student.id] = {
      itemID: exam.id,
      title: exam.title,
      subject: exam.subject ?? "",
      examDate: exam.date,
      day: { day: day.day, kind: day.kind, index: day.index, title: day.title, skillIDs: day.skillIDs },
      gapLine,
      setNumber,
      skills: day.skills,
      portions: portionsOf(exam.portions ?? exam.title),
      gapSkills: report ? weakestSkills(report.bySkill, 6) : [],
    };
  }
  return { revisions, holidays };
}
