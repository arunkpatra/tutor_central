import { addDays } from "./dates.js";
import type { ClassLevel } from "./types.js";

/** A school item as the plan job reads it (`school_items`): who it reaches by its three columns. */
export type SchoolItem = {
  kind: "exam" | "homework" | "notice" | "holiday";
  studentId?: string | null;
  schoolId?: string | null;
  classLevel?: ClassLevel | string | null;
  date: string;
  endDate?: string | null;
  subject?: string | null;
  title: string;
  windowDays?: number | null;
};
export type Reached = { id: string; schoolId?: string | null; classLevel?: string };

/** An exam this close turns its students' lines to revision (SchoolItemRules.windowDays). */
export const EXAM_WINDOW_DAYS = 14;

/** Whether the item is for the student: their own, their school's class, or their whole school (SchoolItemRules.reaches). */
export function reaches(item: SchoolItem, student: Reached): boolean {
  if (item.studentId) return item.studentId === student.id;
  if (!item.schoolId) return false;
  if (item.classLevel) return student.schoolId === item.schoolId && student.classLevel === item.classLevel;
  return student.schoolId === item.schoolId;
}

/** From the window's first day to the exam day (ExamPreparation.isWithinWindow). */
export function examWithinWindow(item: SchoolItem, day: string): boolean {
  if (item.kind !== "exam") return false;
  const first = addDays(item.date, -(item.windowDays ?? EXAM_WINDOW_DAYS));
  return day >= first && day <= item.date;
}

/** A holiday covers its first to its last day, both included (HolidayRules.covers). */
export function holidayCovers(item: SchoolItem, day: string): boolean {
  const last = item.endDate && item.endDate > item.date ? item.endDate : item.date;
  return item.kind === "holiday" && item.date <= day && day <= last;
}

/** The day is in exam mode for the batch when an exam within its window or a holiday on the day reaches a member: the
 *  phone's maker plans it (its exam split is Phase 18's port). */
export function examMode(items: SchoolItem[], members: Reached[], day: string): boolean {
  return items.some((item) => (examWithinWindow(item, day) || holidayCovers(item, day)) && members.some((m) => reaches(item, m)));
}
