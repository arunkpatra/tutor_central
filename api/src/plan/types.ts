/** The plan's types as the shared case file writes them (tools/contract/plan-cases.json), ported from Domain's
 *  PlanTypes.swift and PlanRules.swift's PlanInput. Ids are lowercase UUIDs, days "YYYY-MM-DD", instants ISO 8601. */

export const CLASS_LEVELS = ["lkg", "ukg", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"] as const;
export type ClassLevel = (typeof CLASS_LEVELS)[number];
export type TrackStatus = "not_on_track" | "watch" | "on_track" | "not_known";
export type NextStep = "tell_parent" | "teach_again" | "step_back" | "add_to_checks" | "leave";
export type SkillState = "not_started" | "taught" | "practising" | "secure" | "revisit";
export type LineKind = "teach" | "practise" | "check" | "homework" | "brief" | "catch_up" | "worked_example" | "figure";

export type Student = { id: string; name: string; classLevel?: ClassLevel; trackStatus: TrackStatus; nextStep?: NextStep; gender?: string };
export type Chapter = { id: string; subject: string; position: number; name: string };
export type Skill = {
  id: string;
  chapterID: string;
  position: number;
  name: string;
  state: SkillState;
  stateAt: string;
  /** The spaced queue's clock: the last check on it, when there was one. */
  lastCheckedAt?: string;
};
export type Session = { classID: string; date: string; marks: Record<string, "present" | "absent"> };
/** A school item near enough to choose a student's subject (Phase 13's SchoolItemHint). */
export type Hint = { studentID: string; subject: string; date: string };
export type Pattern = { groups: number; subjects: string[] };
/** A student's exam line for the day (RevisionLine): the exam, the day's portion, the mock's pattern, the gap line. */
export type Revision = {
  itemID: string;
  title: string;
  subject: string;
  examDate: string;
  day: { day: string; kind: "revise" | "mock" | "afterMock" | "exam"; index?: number; title: string; skillIDs: string[] };
  gapLine?: string;
  pattern?: { marks: number; durationMinutes: number };
  setNumber: number;
  /** What the budget reads (ArtefactBudget's exam groups): the day's skill names, the exam's portions as parts, the
   *  student's weakest skills in a marked mock. */
  skills?: string[];
  portions?: string[];
  gapSkills?: string[];
};

export type PlanInput = {
  classroom: { id: string; subject?: string; planGroups?: number; patterns: Record<string, Pattern> };
  date: string;
  /** The batch's active members. */
  students: Student[];
  /** By student. */
  chapters: Record<string, Chapter[]>;
  skills: Record<string, Skill[]>;
  /** The batch's sessions, any month, for the catch-up line. */
  sessions: Session[];
  /** Each student's nearest exam within the window, for the subject rule. */
  hints: Hint[];
  /** Today's choices from the Change sheet (absent: the batch's kept pattern, else the rules). */
  groupCount?: number;
  /** By group number. */
  subjects: Record<string, string>;
  /** By student: the exam they revise for today (Phase 13). */
  revisions: Record<string, Revision>;
  /** Students on holiday today: left out. */
  holidays: string[];
};

export type PlanGroup = {
  number: number;
  subject: string;
  /** Empty while /ai/plan has not named it. */
  chapter: string;
  skill: string;
  classLevels: ClassLevel[];
  memberIDs: string[];
  skillID?: string;
  examItemID?: string;
};

export type PlanLine = { studentID?: string; groupNo: number; kind: LineKind; skillID?: string; words: string; personalChecks: boolean };

export type PlanDraft = {
  classID: string;
  date: string;
  groups: PlanGroup[];
  lines: PlanLine[];
  /** Students with no lines (left out today). */
  leftOut: string[];
  /** By student: the skill ids put first in their own checks ("Add it to the checks"). */
  personalCheckSkills: Record<string, string[]>;
};
