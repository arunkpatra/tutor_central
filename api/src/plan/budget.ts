import { figureFor } from "./rules.js";
import { SPACED_COUNT, spacedPick } from "./spaced.js";
import { CLASS_LEVELS, type Chapter, type ClassLevel, type PlanDraft, type PlanGroup, type Revision, type Skill, type Student } from "./types.js";

/** Which artefacts a plan makes and in what order (Domain's ArtefactBudget, plan/phase-12-plan.md decision 6): per group
 *  the checks, the set, the homework sheet, the worked example, a figure when the skill has one, the brief above class 7
 *  or when asked before; the exam groups' material first; then at most four personal checks; at most 20 calls. */
export const MAX_CALLS = 20;
export const MAX_PERSONAL_CHECKS = 4;
export const CHECKS_PER_CLASS = 3;
export const SET_QUESTIONS = 10;
export const HOMEWORK_QUESTIONS = 10;
export const LIGHT_HOMEWORK_QUESTIONS = 5;

/** One call the plan will make (ArtefactRequest): group material names skills and a level, never a student; the personal
 *  checks and the placement name the student by id only, so the answer can be linked (D62). */
export type MaterialRequest =
  | { kind: "checks"; group: number; skills: string[]; skillIDs: string[]; classLevel: ClassLevel; subject: string }
  | { kind: "personalChecks"; student: string; skills: string[]; skillIDs: string[]; classLevel: ClassLevel; subject: string }
  | { kind: "placement"; student: string; classLevel: ClassLevel }
  | { kind: "sheet"; group: number; skills: string[]; classLevel: ClassLevel; subject: string; questions: number; forHomework: boolean }
  | { kind: "workedExample"; group: number; skills: [string]; classLevel: ClassLevel; subject: string }
  | { kind: "figure"; group: number; figure: string; skills: [string]; classLevel: ClassLevel; subject: string }
  | { kind: "brief"; group: number; chapter: string; classLevel: ClassLevel; subject: string }
  | {
      kind: "mock";
      group: number;
      item: string;
      title: string;
      portions: string[];
      pattern: { marks: number; durationMinutes: number };
      classLevel: ClassLevel;
      subject: string;
    };

/** What the budget reads besides the draft: the members, their books, their exam lines, the clock, what was made before. */
export type BudgetInput = {
  students: Student[];
  chapters: Record<string, Chapter[]>;
  skills: Record<string, Skill[]>;
  revisions: Record<string, Revision>;
  now: string;
  /** Chapters a brief exists for (the tutor asked before). */
  briefsMade: string[];
  /** Exams whose mock exists. */
  mocksMade: string[];
};

const rank = (level: ClassLevel) => CLASS_LEVELS.indexOf(level);
const highest = (levels: ClassLevel[]): ClassLevel | undefined =>
  levels.reduce<ClassLevel | undefined>((best, l) => (best === undefined || rank(l) > rank(best) ? l : best), undefined);
const isLight = (level: ClassLevel) => rank(level) <= rank("5");

/** The group's class for the model's sake: the highest level among its members; class 5 when no member has one. */
export function groupLevel(group: PlanGroup, students: Map<string, Student>): ClassLevel {
  const own = group.memberIDs.flatMap((id) => {
    const level = students.get(id)?.classLevel;
    return level ? [level] : [];
  });
  return highest(own) ?? highest(group.classLevels) ?? "5";
}

/** The mock's default pattern by class (MockPattern.default). */
export function defaultPattern(level: ClassLevel | undefined): { marks: number; durationMinutes: number } {
  if (level === undefined || level === "10") return { marks: 80, durationMinutes: 180 };
  if (level === "8" || level === "9") return { marks: 40, durationMinutes: 60 };
  if (level === "6" || level === "7") return { marks: 25, durationMinutes: 40 };
  return { marks: 20, durationMinutes: 30 };
}

/** Each member's spaced pick in their group's subject (PlanMaker.spaced). */
export function spacedSkills(draft: PlanDraft, input: Pick<BudgetInput, "chapters" | "skills" | "now">): Map<string, Skill[]> {
  const picks = new Map<string, Skill[]>();
  for (const group of draft.groups) {
    for (const member of group.memberIDs) {
      const chapters = (input.chapters[member] ?? []).filter((c) => c.subject === group.subject);
      const ids = new Set(chapters.map((c) => c.id));
      const skills = (input.skills[member] ?? []).filter((s) => ids.has(s.chapterID));
      picks.set(member, spacedPick(skills, chapters, input.now));
    }
  }
  return picks;
}

/** The requests in the order to make them (ArtefactBudget.requests). */
export function budget(draft: PlanDraft, input: BudgetInput): MaterialRequest[] {
  const students = new Map(input.students.map((s) => [s.id, s] as const));
  const spaced = spacedSkills(draft, input);
  const made: MaterialRequest[] = [];
  for (const group of draft.groups) if (group.examItemID !== undefined) made.push(...examRequests(group, students, input));
  for (const group of draft.groups) {
    if (group.examItemID === undefined && group.skill !== "") made.push(...groupRequests(group, students, spaced, new Set(input.briefsMade)));
  }
  made.push(...personalRequests(draft, students, spaced, input));
  return made.slice(0, MAX_CALLS);
}

function groupRequests(group: PlanGroup, students: Map<string, Student>, spaced: Map<string, Skill[]>, briefs: Set<string>): MaterialRequest[] {
  const level = groupLevel(group, students);
  const pair = spacedPair(group, spaced);
  // Three questions a class: the day's skill fills the places the spaced queue leaves (a new batch has none).
  const fill = Math.max(0, CHECKS_PER_CLASS - 1 - pair.length);
  const teachIDs = group.skillID !== undefined ? Array<string>(1 + fill).fill(group.skillID) : [];
  const { number, skill, subject } = group;
  const requests: MaterialRequest[] = [
    {
      kind: "checks",
      group: number,
      skills: [...Array<string>(1 + fill).fill(skill), ...pair.map((s) => s.name)],
      skillIDs: [...teachIDs, ...pair.map((s) => s.id)],
      classLevel: level,
      subject,
    },
    { kind: "sheet", group: number, skills: [skill], classLevel: level, subject, questions: SET_QUESTIONS, forHomework: false },
    {
      kind: "sheet",
      group: number,
      skills: [skill],
      classLevel: level,
      subject,
      questions: isLight(level) ? LIGHT_HOMEWORK_QUESTIONS : HOMEWORK_QUESTIONS,
      forHomework: true,
    },
    { kind: "workedExample", group: number, skills: [skill], classLevel: level, subject },
  ];
  const figure = figureFor(skill);
  if (figure !== undefined) requests.push({ kind: "figure", group: number, figure, skills: [skill], classLevel: level, subject });
  if (group.chapter !== "" && (rank(level) > rank("7") || briefs.has(group.chapter))) {
    requests.push({ kind: "brief", group: number, chapter: group.chapter, classLevel: level, subject });
  }
  return requests;
}

/** The two most overdue distinct skills across the members' spaced picks (by last checked, else the state's change,
 *  oldest first), the teach skill left out. */
function spacedPair(group: PlanGroup, spaced: Map<string, Skill[]>): Skill[] {
  const time = (s: Skill) => Date.parse(s.lastCheckedAt ?? s.stateAt);
  const candidates = group.memberIDs
    .flatMap((id) => spaced.get(id) ?? [])
    .filter((s) => s.name !== group.skill && s.id !== group.skillID)
    .sort((a, b) => time(a) - time(b));
  const seen = new Set<string>();
  return candidates.filter((s) => (seen.has(s.name) ? false : (seen.add(s.name), true))).slice(0, 2);
}

function personalRequests(draft: PlanDraft, students: Map<string, Student>, spaced: Map<string, Skill[]>, input: BudgetInput): MaterialRequest[] {
  const lines = draft.lines
    .filter((l) => l.kind === "check" && l.personalChecks && l.studentID !== undefined && students.has(l.studentID))
    .map((l) => ({ line: l, student: students.get(l.studentID as string) as Student }))
    .sort((a, b) => (a.student.name < b.student.name ? -1 : a.student.name > b.student.name ? 1 : 0));
  const requests = lines.map(({ line, student }): MaterialRequest => {
    const group = draft.groups.find((g) => g.number === line.groupNo);
    const level = student.classLevel ?? (group ? groupLevel(group, students) : "5");
    // Nothing taught in the subject: the spaced queue has nothing to pick, so the student is placed. "Add it to the
    // checks" puts the current skill first (Phase 14).
    const own = input.skills[student.id] ?? [];
    const heads = (draft.personalCheckSkills[student.id] ?? []).flatMap((id) => own.filter((s) => s.id === id));
    const rest = (spaced.get(student.id) ?? []).filter((s) => !heads.some((h) => h.id === s.id));
    const picked = [...heads, ...rest].slice(0, SPACED_COUNT);
    if (picked.length === 0) return { kind: "placement", student: student.id, classLevel: level };
    return { kind: "personalChecks", student: student.id, skills: picked.map((s) => s.name), skillIDs: picked.map((s) => s.id), classLevel: level, subject: group?.subject ?? "" };
  });
  return requests.slice(0, MAX_PERSONAL_CHECKS);
}

/** An exam group's material (Phase 13 decision 11): checks on the day's skills (at most three, else the portion), the set
 *  and the homework sheet from them; on the mock day the mock in the set's place (once per exam) and no sheet; after the
 *  mock, the set from the members' weakest skills (up to six), else the portions. */
function examRequests(group: PlanGroup, students: Map<string, Student>, input: BudgetInput): MaterialRequest[] {
  const item = group.examItemID;
  const revision = group.memberIDs.map((id) => input.revisions[id]).find((r) => r !== undefined);
  if (item === undefined || revision === undefined) return [];
  const level = groupLevel(group, students);
  const portions = revision.portions ?? [];
  let skills: string[];
  let skillIDs: string[];
  switch (revision.day.kind) {
    case "revise":
      skills = (revision.skills ?? []).length === 0 ? [revision.day.title] : (revision.skills as string[]);
      skillIDs = revision.day.skillIDs;
      break;
    case "afterMock": {
      const seen = new Set<string>();
      const weakest = group.memberIDs
        .flatMap((id) => input.revisions[id]?.gapSkills ?? [])
        .filter((s) => (seen.has(s) ? false : (seen.add(s), true)));
      skills = (weakest.length === 0 ? portions : weakest).slice(0, 6);
      skillIDs = [];
      break;
    }
    case "mock":
    case "exam":
      skills = portions.length === 0 ? [revision.title] : portions;
      skillIDs = [];
      break;
  }
  const checks: MaterialRequest = {
    kind: "checks",
    group: group.number,
    skills: (skills.length === 0 ? [group.skill] : skills).slice(0, 3),
    skillIDs: skillIDs.slice(0, 3),
    classLevel: level,
    subject: group.subject,
  };
  const requests: MaterialRequest[] = [checks];
  if (revision.day.kind === "mock") {
    if (!input.mocksMade.includes(item)) {
      requests.push({
        kind: "mock",
        group: group.number,
        item,
        title: revision.title,
        portions,
        pattern: revision.pattern ?? defaultPattern(level),
        classLevel: level,
        subject: group.subject,
      });
    }
    return requests;
  }
  requests.push({ kind: "sheet", group: group.number, skills, classLevel: level, subject: group.subject, questions: SET_QUESTIONS, forHomework: false });
  requests.push({
    kind: "sheet",
    group: group.number,
    skills,
    classLevel: level,
    subject: group.subject,
    questions: isLight(level) ? LIGHT_HOMEWORK_QUESTIONS : HOMEWORK_QUESTIONS,
    forHomework: true,
  });
  return requests;
}
