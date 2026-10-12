import type { Chapter, NextStep, PlanInput, Skill, Student, TrackStatus } from "./types.js";

/** The plan's own choice from the stored status (NextStep.planned). */
export function planned(status: TrackStatus): NextStep {
  if (status === "not_on_track") return "tell_parent";
  if (status === "watch") return "teach_again";
  return "leave";
}

/** The tutor's choice when one is kept, else the plan's own (Student.effectiveStep). */
export function effectiveStep(student: Student): NextStep {
  return student.nextStep ?? planned(student.trackStatus);
}

/** The first skill not yet secure, by chapter then skill position; none when there is none (TrackingRules.currentSkill). */
export function currentSkill(skills: Skill[], chapters: Chapter[]): Skill | undefined {
  const positions = new Map(chapters.map((c) => [c.id, c.position]));
  let best: Skill | undefined;
  for (const skill of skills) {
    if (skill.state === "secure" || !positions.has(skill.chapterID)) continue;
    if (!best) {
      best = skill;
      continue;
    }
    const [left, right] = [positions.get(skill.chapterID) ?? 0, positions.get(best.chapterID) ?? 0];
    if (left !== right ? left < right : skill.position < best.position) best = skill;
  }
  return best;
}

/** The teach line for the student's step (plan/phase-14-plan.md decision 9): telling the parent and teaching again both
 *  teach again with the worked example; stepping back teaches the skill before first; the rest teach as usual. */
export function teachWords(skill: string, step: NextStep, before: string | undefined): string {
  if (step === "tell_parent" || step === "teach_again") return `Teach again: ${skill}, with the worked example`;
  if (step === "step_back") return before !== undefined ? `Step back: ${before}, then ${skill}` : `Teach again: ${skill}, with the worked example`;
  return `Teach: ${skill}`;
}

/** The skill before this one: the one before it in its chapter, else the last of the chapter before. */
export function skillBefore(skill: Skill, chapters: Chapter[], skills: Skill[]): Skill | undefined {
  const position = new Map(chapters.map((c) => [c.id, c.position]));
  const ordered = [...skills].sort((a, b) => {
    const [left, right] = [position.get(a.chapterID) ?? 0, position.get(b.chapterID) ?? 0];
    return left !== right ? left - right : a.position - b.position;
  });
  const index = ordered.findIndex((s) => s.id === skill.id);
  return index > 0 ? ordered[index - 1] : undefined;
}

/** The skills put at the head of a student's own checks: the current skill when the step is "Add it to the checks". */
export function checkHeads(students: Student[], input: PlanInput): Record<string, string[]> {
  const heads: Record<string, string[]> = {};
  for (const student of students) {
    if (!(student.trackStatus === "watch" || student.trackStatus === "not_on_track") || effectiveStep(student) !== "add_to_checks") continue;
    const current = currentSkill(input.skills[student.id] ?? [], input.chapters[student.id] ?? []);
    if (current) heads[student.id] = [current.id];
  }
  return heads;
}
