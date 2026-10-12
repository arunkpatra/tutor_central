import { istDay } from "../plan/dates.js";
import { nearestExam, type PrepItem, type PrepStudent } from "../plan/exam-prep.js";
import { currentSkill } from "../plan/step.js";
import type { Chapter, Skill } from "../plan/types.js";
import { shortWeekdayText } from "../reminders/planner.js";

/** What a parent's weekly note says (Domain's NoteWeek and CanDoWeek, plan/phase-14-plan.md decisions 2 and 3), worked
 *  out from the week's record; the model words these facts and nothing else. Pure. */
export const TAUGHT_LIMIT = 6;
export const PRACTISE_LIMIT = 3;

/** A student's record as the note reads it: their book, checks, the batch's sessions with their mark, marks, and the
 *  school's items (the shared cases' shape). */
export type NoteRecord = {
  student: PrepStudent;
  chapters: Chapter[];
  skills: Skill[];
  checks: { skillID: string; at: string; correct: boolean; isPlacement: boolean }[];
  sessions: { date: string; mark: "present" | "absent" }[];
  marks: { subject: string; test: string; date: string; score: number; max: number }[];
  items: PrepItem[];
};
export type Week = { from: string; to: string };
export type FactRow = { label: string; fact: string; symbol: string };
export type NoteFacts = {
  taught: string[];
  taughtLine: string;
  right?: string;
  practise: string[];
  coming: string[];
  attendance?: string;
  absentAllWeek: boolean;
  rows: FactRow[];
};

const inWeek = (week: Week, day: string) => week.from <= day && day <= week.to;
const dayOf = (instant: string) => istDay(new Date(instant));

/** "Balancing equations" → "balancing equations"; a name that starts with an acronym stays. */
export function lowered(text: string): string {
  const chars = [...text];
  const second = chars[1];
  if (chars.length === 0 || (second !== undefined && second !== second.toLowerCase() && second === second.toUpperCase())) return text;
  return (chars[0] as string).toLowerCase() + chars.slice(1).join("");
}

/** Skills in chapter order, then skill order; a skill whose chapter is not in the book is left out. */
function ordered(chapters: Chapter[], skills: Skill[]): Skill[] {
  const position = new Map(chapters.map((c) => [c.id, c.position]));
  return skills
    .filter((s) => position.has(s.chapterID))
    .sort((a, b) => {
      const [x, y] = [position.get(a.chapterID) ?? 0, position.get(b.chapterID) ?? 0];
      return x !== y ? x - y : a.position - b.position;
    });
}

/** The week's facts for a student's note (NoteWeek.facts). */
export function noteFacts(record: NoteRecord, week: Week): NoteFacts {
  const { chapters, skills } = record;
  const chapterOf = new Map(chapters.map((c) => [c.id, c]));
  const attended = record.sessions.filter((s) => inWeek(week, s.date));
  const absences = attended.filter((s) => s.mark === "absent").length;
  const absentAllWeek = attended.length > 0 && absences === attended.length;
  // First taught this week: moved from not started to taught in the week.
  const taught = absentAllWeek ? [] : ordered(chapters, skills.filter((s) => s.state === "taught" && inWeek(week, dayOf(s.stateAt)))).slice(0, TAUGHT_LIMIT);
  const weekChecks = record.checks.filter((c) => !c.isPlacement && inWeek(week, dayOf(c.at)));
  const right = weekChecks.filter((c) => c.correct).length;
  let mark: NoteRecord["marks"][number] | undefined;
  for (const m of record.marks) if (inWeek(week, m.date) && (!mark || mark.date < m.date)) mark = m;
  const rightParts = [weekChecks.length > 0 ? `${right} of ${weekChecks.length} checks` : undefined, mark ? `${mark.score} of ${mark.max} on ${mark.test}` : undefined].filter(
    (p): p is string => p !== undefined,
  );
  const rightWords = rightParts.length ? rightParts.join(" · ") : undefined;
  const practise = practiseOf(chapters, skills, taught, weekChecks.filter((c) => !c.correct));
  const coming = comingOf(record, week);
  const attendance = absences === 0 ? undefined : absences === attended.length ? `absent all week (${attended.length} ${attended.length === 1 ? "class" : "classes"})` : `absent ${absences} of ${attended.length} classes`;
  let taughtLine: string;
  if (absentAllWeek) taughtLine = "Nothing new this week: absent all week";
  else if (taught.length === 0) taughtLine = "Nothing new this week";
  else {
    const runs: { chapter: string; names: string[] }[] = [];
    for (const s of taught) {
      const chapter = chapterOf.get(s.chapterID)?.name ?? "";
      const last = runs.at(-1);
      if (last && last.chapter === chapter) last.names.push(lowered(s.name));
      else runs.push({ chapter, names: [lowered(s.name)] });
    }
    taughtLine = runs.map((r) => (r.chapter === "" ? r.names.join(", ") : `${r.chapter}: ${r.names.join(", ")}`)).join(" · ");
  }
  return {
    taught: taught.map((s) => s.name),
    taughtLine,
    ...(rightWords !== undefined ? { right: rightWords } : {}),
    practise,
    coming,
    ...(attendance !== undefined ? { attendance } : {}),
    absentAllWeek,
    rows: [
      { label: "Taught", fact: taughtLine, symbol: "book.closed" },
      { label: "Got right", fact: rightWords ?? "No checks yet", symbol: "checkmark.circle" },
      { label: "To practise", fact: practise.length ? practise.join(" · ") : "Nothing to add", symbol: "pencil.line" },
      { label: "Coming", fact: coming.length ? coming.join(" · ") : "Nothing set", symbol: "calendar" },
    ],
  };
}

/** Practising or revisit skills in the week's chapters (those taught, else the current skill's); else the skills the
 *  week's wrong checks were on. */
function practiseOf(chapters: Chapter[], skills: Skill[], taught: Skill[], wrong: NoteRecord["checks"]): string[] {
  const current = ordered(chapters, skills).find((s) => s.state !== "secure");
  const weekChapters = new Set(taught.length === 0 ? (current ? [current.chapterID] : []) : taught.map((s) => s.chapterID));
  const weak = ordered(chapters, skills.filter((s) => (s.state === "practising" || s.state === "revisit") && weekChapters.has(s.chapterID)));
  if (weak.length > 0) return weak.slice(0, PRACTISE_LIMIT).map((s) => s.name);
  const names: string[] = [];
  for (const c of [...wrong].sort((a, b) => Date.parse(a.at) - Date.parse(b.at))) {
    const name = skills.find((s) => s.id === c.skillID)?.name;
    if (name && !names.includes(name)) names.push(name);
  }
  return names.slice(0, PRACTISE_LIMIT);
}

/** The next skill not started after the current one (a new chapter's name when it opens one), then the nearest exam
 *  reaching the student within its window from the note day. */
function comingOf(record: NoteRecord, week: Week): string[] {
  const coming: string[] = [];
  const sorted = ordered(record.chapters, record.skills);
  const current = sorted.findIndex((s) => s.state !== "secure");
  const next = current >= 0 ? sorted.slice(current).find((s) => s.state === "not_started") : undefined;
  if (next) {
    const opens = !sorted.some((s) => s.chapterID === next.chapterID && s.state !== "not_started");
    coming.push(opens ? (record.chapters.find((c) => c.id === next.chapterID)?.name ?? next.name) : next.name);
  }
  const exam = nearestExam(record.student, record.items, week.to);
  if (exam) coming.push(`the ${lowered(exam.title)} on ${shortWeekdayText(exam.date)}`);
  return coming;
}

/** The Notes card's topic: the first taught skill's chapter, else the current skill's. */
export function noteTopic(facts: NoteFacts, chapters: Chapter[], skills: Skill[]): string | undefined {
  const first = (facts.taught[0] !== undefined ? skills.find((s) => s.name === facts.taught[0]) : undefined) ?? currentSkill(skills, chapters);
  return first ? chapters.find((c) => c.id === first.chapterID)?.name : undefined;
}

const AREAS = ["reading", "writing", "numbers"] as const;
type Area = (typeof AREAS)[number];
const STEPS: Record<Area, string[]> = {
  reading: ["Letters", "Words", "Sentences", "Paragraph", "Story"],
  writing: ["Traces", "Letters", "Words", "Sentences", "Short text"],
  numbers: ["To 9", "To 99", "Add", "Subtract", "Multiply"],
};
const CAN: Record<Area, string[]> = {
  reading: ["Know the letters", "Read words", "Read short sentences", "Read a paragraph", "Read a short story"],
  writing: ["Trace letters", "Write letters", "Write words", "Write short sentences", "Write a few lines"],
  numbers: ["Count to 9", "Count to 99", "Add to 20", "Take away within 20", "Multiply small numbers"],
};
const NEXT: Record<Area, string[]> = {
  reading: ["Reading letters", "Reading words", "Reading sentences", "Reading a paragraph", "Reading a story"],
  writing: ["Tracing letters", "Writing letters", "Writing words", "Writing sentences", "Writing a few lines"],
  numbers: ["Counting to 9", "Counting to 99", "Adding to 20", "Taking away within 20", "Multiplying"],
};
const HOME: Record<Area, string[]> = {
  reading: [
    "Point to the letters in the picture book",
    "Five words a day from the picture book",
    "One page a day from the picture book",
    "One page a day, read aloud",
    "One short story a week, read aloud",
  ],
  writing: ["Trace five letters a day", "Five letters a day in the notebook", "Five words a day in the notebook", "Two sentences a day in the notebook", "A few lines a day in the notebook"],
  numbers: ["Count things at home to 9", "Count things at home to 99", "Add small numbers with things at home", "Take away with things at home", "Say a times table aloud"],
};

export type CanDoFacts = {
  movedUp: { area: Area; step: string }[];
  canDo: string[];
  atHome: string;
  next: string[];
  ladderHeading: string;
  movedUpLine: string;
  rows: FactRow[];
};

const joined = (items: string[]) => items.map((item, i) => (i === 0 ? item : lowered(item))).join(" · ");
const atHome = (area: Area, step: number) => {
  const lines = HOME[area];
  return lines[Math.max(0, Math.min(step, lines.length - 1))] as string;
};

/** A young student's can-now-do from the ladder (CanDoWeek.facts): the steps made secure this week, what the student can
 *  now do, one fixed line for home, and what is next. */
export function canDoFacts(chapters: Chapter[], skills: Skill[], week: Week): CanDoFacts {
  const movedUp: CanDoFacts["movedUp"] = [];
  const canDo: string[] = [];
  const next: string[] = [];
  let home: { area: Area; step: number } | undefined;
  for (const chapter of [...chapters].sort((a, b) => a.position - b.position)) {
    const area = chapter.ladder as Area | undefined;
    if (!area || !AREAS.includes(area)) continue;
    const steps = skills.filter((s) => s.chapterID === chapter.id).sort((a, b) => a.position - b.position);
    const firstOpen = steps.findIndex((s) => s.state !== "secure");
    const current = firstOpen >= 0 ? firstOpen : steps.length;
    if (current > 0 && current - 1 < STEPS[area].length) {
      canDo.push(CAN[area][current - 1] ?? (STEPS[area][current - 1] as string));
      const made = steps[current - 1] as Skill;
      if (made.state === "secure" && inWeek(week, dayOf(made.stateAt))) {
        movedUp.push({ area, step: STEPS[area][current - 1] as string });
        home ??= { area, step: current - 1 };
      }
    }
    if (current < STEPS[area].length) next.push(NEXT[area][current] ?? (STEPS[area][current] as string));
    if (!home && area === "reading") home = { area, step: Math.max(0, Math.min(current, STEPS[area].length) - 1) };
  }
  const line = home ? atHome(home.area, home.step) : atHome("reading", 0);
  const can = canDo.slice(0, 4);
  const then = next.slice(0, 3);
  return {
    movedUp,
    canDo: can,
    atHome: line,
    next: then,
    ladderHeading: movedUp.length === 0 ? "On the ladder" : "Moved up",
    movedUpLine: movedUp[0] ? `${movedUp[0].step} · moved up this week` : "No change this week",
    rows: [
      { label: "Can now do", fact: joined(can), symbol: "star" },
      { label: "At home", fact: line, symbol: "house" },
      { label: "Next", fact: then.length === 0 ? "Nothing set" : joined(then), symbol: "arrow.right.circle" },
    ],
  };
}

/** LKG and UKG, and classes 1 to 3 with a ladder chapter, get can-now-do; the rest the weekly note. */
export function isLadderNote(student: { classLevel?: string }, chapters: Chapter[]): boolean {
  if (student.classLevel === "lkg" || student.classLevel === "ukg") return true;
  if (student.classLevel === "1" || student.classLevel === "2" || student.classLevel === "3") return chapters.some((c) => c.ladder !== undefined);
  return false;
}
