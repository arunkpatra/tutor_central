import { addDays, shortWeekday, weekday } from "./dates.js";
import { byName, cut, examGroup, examGroups, examLines, levels, revisionTeach } from "./exam.js";
import { checkHeads, currentSkill, effectiveStep, skillBefore, teachWords } from "./step.js";
import { CLASS_LEVELS, type ClassLevel, type LineKind, type PlanDraft, type PlanGroup, type PlanInput, type PlanLine, type Student } from "./types.js";

/** The plan's rules (docs/spec-v2.md section 6; Domain's PlanRules.swift, held equal by the shared cases in
 *  tools/contract/plan-cases.json): the level groups, each student's subject and lines, made from the register and the
 *  record. Pure. */
export const MAX_GROUPS = 3;
export const CATCH_UP_AFTER_ABSENCES = 2;
export const SCHOOL_ITEM_WINDOW_DAYS = 14;
/** The brief's title and line before its chapter ("Your brief · Chemical reactions"). */
export const BRIEF_PREFIX = "Your brief · ";
/** A teach line while /ai/plan has not named the group's skill. */
export const WITH_THE_GROUP = "Teach: with the group";

const ordinal = (level: ClassLevel) => CLASS_LEVELS.indexOf(level);
const compare = (a: string, b: string) => (a < b ? -1 : a > b ? 1 : 0);

/** The draft: groups (largest first), one teach, practise, check and homework line per student (a catch-up line before
 *  the teach line when the student missed the last two), a brief line per group above class 7. A group whose members
 *  have no skill in its subject has `skill == ""` and `chapter == ""`: /ai/plan names them. */
export function planRules(input: PlanInput): PlanDraft {
  const holidays = new Set(input.holidays);
  const present = input.students.filter((s) => !holidays.has(s.id));
  const away = input.students.filter((s) => holidays.has(s.id)).map((s) => s.id);
  const exams = examGroups(present, input);
  const inExams = new Set(exams.flatMap((g) => g.map((s) => s.id)));
  const rest = present.filter((s) => !inExams.has(s.id));
  const pattern = input.classroom.patterns[String(weekday(input.date))];
  const count = input.groupCount ?? pattern?.groups ?? input.classroom.planGroups;
  const left = MAX_GROUPS - exams.length;
  const levelCut = rest.length === 0 ? [] : groups(rest, count !== undefined ? Math.min(count, left) : left);
  const top = (members: Student[]) => Math.max(...members.map(levelKey));
  const ranked = [...levelCut].sort((a, b) => (a.length !== b.length ? b.length - a.length : top(b) - top(a)));
  const planned: PlanGroup[] = [];
  const lines: PlanLine[] = [];
  exams.forEach((members, index) => {
    const group = examGroup(index + 1, members, input);
    planned.push(group);
    for (const member of members) lines.push(...examLines(member, group, input));
  });
  ranked.forEach((members, index) => {
    const number = exams.length + index + 1;
    const override = input.subjects[String(number)] ?? pattern?.subjects[number - 1];
    const group = makeGroup(number, members, groupSubject(members, input, override), input);
    planned.push(group);
    for (const member of members) {
      for (const line of studentLines(member, group, input)) {
        // A student whose exam has no group of its own keeps the group's material and their own words.
        const revision = input.revisions[member.id];
        lines.push(line.kind === "teach" && revision ? { ...line, words: revisionTeach(revision) } : line);
      }
    }
    lines.push({ studentID: undefined, groupNo: number, kind: "worked_example", skillID: group.skillID, words: groupLineWords("worked_example", group), personalChecks: false });
    const figure = figureLine(group);
    if (figure) lines.push(figure);
    if (group.classLevels.some((level) => ordinal(level) > ordinal("7"))) lines.push(briefLine(group));
  });
  return {
    classID: input.classroom.id,
    date: input.date,
    groups: planned,
    lines: lines.map((line) => ({ ...line, words: cut(line.words) })),
    leftOut: away,
    personalCheckSkills: checkHeads(present, input),
  };
}

/** The words of a group's worked example and figure lines ("Worked example · Balancing equations"). */
export function groupLineWords(kind: LineKind, group: PlanGroup): string {
  const name = kind === "figure" ? "Figure" : "Worked example";
  return group.skill === "" ? name : `${name} · ${group.skill}`;
}

/** The words in a skill's name that make each template the skill's figure, in this order (FigureSpec.Kind.words). */
const FIGURE_WORDS: [string, string[]][] = [
  ["number_line", ["number line", "jumps", "count on"]],
  ["fraction_bar", ["fraction", "half", "quarter", "parts of a whole"]],
  ["place_value", ["place value", "ones, tens", "large numbers"]],
  ["unit_circle", ["sine", "cosine", "unit circle", "trigonometric ratios"]],
  ["triangle", ["triangle", "pythagoras", "right angle"]],
  ["labelled_cell", ["cell", "nucleus", "cytoplasm"]],
  ["food_chain", ["food chain", "producer", "consumer"]],
];

/** The template a skill has, read from its name (case-insensitive); none when it has none. */
export function figureFor(skill: string): string | undefined {
  const name = skill.toLowerCase();
  return FIGURE_WORDS.find(([, words]) => words.some((w) => name.includes(w)))?.[0];
}

/** The group's figure line when its skill names a template (plan decision 7). */
export function figureLine(group: PlanGroup): PlanLine | undefined {
  if (group.skill === "" || !figureFor(group.skill)) return undefined;
  return { studentID: undefined, groupNo: group.number, kind: "figure", skillID: group.skillID, words: groupLineWords("figure", group), personalChecks: false };
}

/** The group's brief line ("Your brief · Chemical reactions"; "Your brief" until the chapter is named). */
export function briefLine(group: PlanGroup): PlanLine {
  const words = group.chapter === "" ? "Your brief" : BRIEF_PREFIX + group.chapter;
  return { studentID: undefined, groupNo: group.number, kind: "brief", skillID: undefined, words, personalChecks: false };
}

// Groups

/** The class level's ordinal (LKG 0 to class 10 11), one less for a student not on track; -1 for no class (the grouping
 *  gives those the batch's most common level). */
export function levelKey(student: Student): number {
  if (!student.classLevel) return -1;
  const at = ordinal(student.classLevel);
  return student.trackStatus === "not_on_track" ? at - 1 : at;
}

/** The students sorted by level key then name, cut at the largest gaps into `count` groups (ties: the later gap); without
 *  a count, the smaller of three and the number of distinct levels. */
export function groups(students: Student[], count: number | undefined): Student[][] {
  if (students.length === 0) return [];
  const tally = new Map<number, number>();
  for (const key of students.map(levelKey).filter((k) => k >= 0)) tally.set(key, (tally.get(key) ?? 0) + 1);
  let common = 0;
  let best = -1;
  for (const [key, n] of tally) {
    if (n > best || (n === best && key > common)) [common, best] = [key, n];
  }
  const keyed = students
    .map((student) => ({ student, key: levelKey(student) < 0 ? common : levelKey(student) }))
    .sort((a, b) => (a.key !== b.key ? a.key - b.key : compare(a.student.name, b.student.name)));
  const distinct = new Set(keyed.map((k) => k.key)).size;
  const wanted = Math.min(Math.max(count ?? Math.min(MAX_GROUPS, distinct), 1), MAX_GROUPS, distinct);
  const gaps = keyed.slice(0, -1).map((k, at) => ({ at, size: (keyed[at + 1] as { key: number }).key - k.key }));
  const cuts = gaps
    .sort((a, b) => (a.size !== b.size ? b.size - a.size : b.at - a.at))
    .slice(0, wanted - 1)
    .map((g) => g.at)
    .sort((a, b) => a - b);
  const result: Student[][] = [];
  let start = 0;
  for (const end of [...cuts, keyed.length - 1]) {
    result.push(keyed.slice(start, end + 1).map((k) => k.student).sort(byName));
    start = end + 1;
  }
  return result;
}

function makeGroup(number: number, members: Student[], subject: string, input: PlanInput): PlanGroup {
  const taught = members.flatMap((student) => {
    const skill = teachSkill(student, subject, input);
    return skill ? [{ student, skill }] : [];
  });
  const named = new Map<string, number>();
  for (const t of taught) named.set(t.skill.name, (named.get(t.skill.name) ?? 0) + 1);
  // The skill most of the group is on; ties by the first member who has it.
  let chosen = taught[0];
  for (const t of taught.slice(1)) {
    if ((named.get(t.skill.name) ?? 0) > (named.get((chosen as typeof t).skill.name) ?? 0)) chosen = t;
  }
  const chapter = chosen ? input.chapters[chosen.student.id]?.find((c) => c.id === chosen.skill.chapterID)?.name : undefined;
  return {
    number,
    subject,
    chapter: chapter ?? "",
    skill: chosen?.skill.name ?? "",
    classLevels: levels(members),
    memberIDs: members.map((m) => m.id),
    skillID: chosen?.skill.id,
    examItemID: undefined,
  };
}

// Subjects

/** True when `lhs` comes first: the batch's own subject, then by name. */
function tieBreak(lhs: string, rhs: string, batch: string | undefined): boolean {
  if (lhs === batch || rhs === batch) return lhs === batch && rhs !== batch;
  return lhs < rhs;
}

/** The student's subject: the nearest school item within 14 days, else the subject least recently taught (one never
 *  taught first), ties by the batch's subject then by name; none when the student has no chapters. */
export function subjectFor(student: Student, input: PlanInput): string | undefined {
  const soon = addDays(input.date, SCHOOL_ITEM_WINDOW_DAYS);
  let item: { date: string; subject: string } | undefined;
  for (const hint of input.hints) {
    if (hint.studentID !== student.id || hint.date < input.date || hint.date > soon) continue;
    if (!item || hint.date < item.date) item = hint;
  }
  if (item) return item.subject;
  const chapters = input.chapters[student.id] ?? [];
  const skills = input.skills[student.id] ?? [];
  const subjects = [...new Set(chapters.map((c) => c.subject))];
  if (subjects.length === 0) return undefined;
  const latest = (subject: string): number | undefined => {
    const ids = new Set(chapters.filter((c) => c.subject === subject).map((c) => c.id));
    const times = skills.filter((s) => ids.has(s.chapterID) && s.state !== "not_started").map((s) => Date.parse(s.stateAt));
    return times.length ? Math.max(...times) : undefined;
  };
  const before = (lhs: string, rhs: string): boolean => {
    const [left, right] = [latest(lhs), latest(rhs)];
    if (left === undefined && right !== undefined) return true;
    if (left !== undefined && right === undefined) return false;
    if (left !== undefined && right !== undefined && left !== right) return left < right;
    return tieBreak(lhs, rhs, input.classroom.subject);
  };
  return subjects.reduce((best, s) => (before(s, best) ? s : best));
}

/** The group's subject: today's choice or the kept pattern, else the most common among its members, ties by the batch's
 *  subject then by name; the batch's subject when no member has one. */
export function groupSubject(members: Student[], input: PlanInput, override: string | undefined): string {
  if (override !== undefined) return override;
  const counts = new Map<string, number>();
  for (const s of members.flatMap((m) => subjectFor(m, input) ?? [])) counts.set(s, (counts.get(s) ?? 0) + 1);
  let best: string | undefined;
  for (const [subject, n] of counts) {
    if (best === undefined) {
      best = subject;
      continue;
    }
    const m = counts.get(best) ?? 0;
    if (n > m || (n === m && tieBreak(subject, best, input.classroom.subject))) best = subject;
  }
  return best ?? input.classroom.subject ?? "Mathematics";
}

// Lines

/** The student's first skill not secure in the subject's chapters. */
export function teachSkill(student: Student, subject: string, input: PlanInput) {
  const chapters = (input.chapters[student.id] ?? []).filter((c) => c.subject === subject);
  return currentSkill(input.skills[student.id] ?? [], chapters);
}

function studentLines(student: Student, group: PlanGroup, input: PlanInput): PlanLine[] {
  const chapters = (input.chapters[student.id] ?? []).filter((c) => c.subject === group.subject);
  const ids = new Set(chapters.map((c) => c.id));
  const skills = (input.skills[student.id] ?? []).filter((s) => ids.has(s.chapterID));
  const own = chapters.length === 0 ? undefined : teachSkill(student, group.subject, input);
  const skillName = own?.name ?? group.skill;
  const placement = chapters.length > 0 && skills.every((s) => s.state === "not_started");
  const again = chapters.length > 0 && !placement && (student.trackStatus === "watch" || student.trackStatus === "not_on_track");
  const before = own ? skillBefore(own, chapters, skills) : undefined;
  const step = again ? effectiveStep(student) : "leave";
  const teachID = step === "step_back" ? (before?.id ?? own?.id) : (own?.id ?? group.skillID);
  const missed = catchUp(student, input);
  const line = (kind: LineKind, words: string, personal: boolean): PlanLine => ({
    studentID: student.id,
    groupNo: group.number,
    kind,
    skillID: own?.id ?? group.skillID,
    words,
    personalChecks: personal,
  });
  const lines: PlanLine[] = [];
  if (missed) lines.push(line("catch_up", missed + (skillName === "" ? "" : ` · then ${skillName}`), false));
  const teach = skillName === "" ? WITH_THE_GROUP : teachWords(skillName, step, before?.name);
  lines.push({ studentID: student.id, groupNo: group.number, kind: "teach", skillID: teachID, words: teach, personalChecks: false });
  lines.push(line("practise", "Practise set 1", false));
  const personal = chapters.length > 0 && (placement || again || missed !== undefined);
  lines.push(line("check", placement ? `Placement, ${pronoun(student)} first checks` : "Check 3", personal));
  lines.push(line("homework", homeworkWords(student.classLevel), false));
  return lines;
}

/** "Catch up: missed Mon and Fri" when the student was absent at the batch's last two sessions before the day. */
export function catchUp(student: Student, input: PlanInput): string | undefined {
  const last = input.sessions
    .filter((s) => s.classID === input.classroom.id && s.date < input.date && s.marks[student.id] !== undefined)
    .sort((a, b) => compare(b.date, a.date))
    .slice(0, CATCH_UP_AFTER_ABSENCES);
  if (last.length !== CATCH_UP_AFTER_ABSENCES || !last.every((s) => s.marks[student.id] === "absent")) return undefined;
  return `Catch up: missed ${[...last].reverse().map((s) => shortWeekday(s.date)).join(" and ")}`;
}

/** "Homework sheet 1", "Homework sheet 1, light" up to class 5. */
export function homeworkWords(level: ClassLevel | undefined): string {
  return level !== undefined && ordinal(level) <= ordinal("5") ? "Homework sheet 1, light" : "Homework sheet 1";
}

/** "her", "his", "their" (the placement line). */
export function pronoun(student: Student): string {
  return student.gender === "female" ? "her" : student.gender === "male" ? "his" : "their";
}

// The draft named by /ai/plan, and the briefs made before

/** The groups /ai/plan named (by number): their chapter and skill, the teach lines that followed the group, the brief's
 *  words and the figure's line when the skill has a template (PlanDraft.naming). */
export function naming(draft: PlanDraft, topics: Map<number, { chapter: string; skill: string }>): PlanDraft {
  const renamed = draft.groups.map((g) => {
    const topic = topics.get(g.number);
    return topic ? { ...g, chapter: topic.chapter, skill: topic.skill } : g;
  });
  const lines: PlanLine[] = [];
  for (const line of draft.lines) {
    const topic = topics.get(line.groupNo);
    const group = renamed.find((g) => g.number === line.groupNo);
    if (!topic || !group) {
      lines.push(line);
      continue;
    }
    if (line.kind === "teach" && line.words === WITH_THE_GROUP) lines.push({ ...line, words: `Teach: ${topic.skill}` });
    else if (line.kind === "catch_up" && !line.words.includes(" · then ")) lines.push({ ...line, words: `${line.words} · then ${topic.skill}` });
    else if (line.kind === "brief") lines.push(briefLine(group));
    else if (line.kind === "worked_example") {
      lines.push({ ...line, words: groupLineWords("worked_example", group) });
      const figure = figureLine(group);
      if (figure) lines.push(figure);
    } else if (line.kind !== "figure") lines.push(line);
  }
  return { ...draft, groups: renamed, lines };
}

/** A brief line for each group whose chapter the tutor had a brief made for before, when it has none. */
export function addingBriefs(draft: PlanDraft, chapters: Set<string>): PlanDraft {
  const missing = draft.groups.filter((g) => chapters.has(g.chapter) && !draft.lines.some((l) => l.kind === "brief" && l.groupNo === g.number));
  return missing.length === 0 ? draft : { ...draft, lines: [...draft.lines, ...missing.map(briefLine)] };
}
