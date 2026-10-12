import type { Chapter, Skill, SkillState } from "./types.js";

/** Which skills the close checks (Domain's SpacedQueue): the most recently taught first, then the most overdue by its
 *  state's interval. A skill not started is never checked. */
export const SPACED_COUNT = 3;

/** Days until a skill in this state is due again; none for a skill not started (SpacedQueue.interval). */
export function interval(state: SkillState): number | undefined {
  switch (state) {
    case "not_started":
      return undefined;
    case "taught":
    case "revisit":
      return 1;
    case "practising":
      return 3;
    case "secure":
      return 7;
  }
}

const DAY_MS = 86_400_000;

/** At most three skills: the eligible one with the latest state change, then the rest by how overdue they are; ties by
 *  chapter position, then skill position (SpacedQueue.pick). Whole days elapsed, as the calendar counts them in India
 *  (no daylight saving: a day is 24 hours). */
export function spacedPick(skills: Skill[], chapters: Chapter[], now: string): Skill[] {
  const positions = new Map(chapters.map((c) => [c.id, c.position]));
  const order = (s: Skill): [number, number] => [positions.get(s.chapterID) ?? Number.MAX_SAFE_INTEGER, s.position];
  const before = (a: [number, number], b: [number, number]) => a[0] < b[0] || (a[0] === b[0] && a[1] < b[1]);
  const at = Date.parse(now);
  const overdue = (s: Skill) => Math.trunc((at - Date.parse(s.lastCheckedAt ?? s.stateAt)) / DAY_MS) - (interval(s.state) ?? 0);
  const eligible = skills.filter((s) => interval(s.state) !== undefined);
  let current: Skill | undefined;
  for (const s of eligible) {
    // Swift's max(by:): the running maximum gives way only to an element strictly above it.
    if (!current) current = s;
    else {
      const [x, y] = [Date.parse(current.stateAt), Date.parse(s.stateAt)];
      if (x !== y ? x < y : before(order(s), order(current))) current = s;
    }
  }
  if (!current) return [];
  const first = current;
  const rest = eligible
    .filter((s) => s.id !== first.id)
    .sort((a, b) => {
      const [left, right] = [overdue(a), overdue(b)];
      if (left !== right) return right - left;
      return before(order(a), order(b)) ? -1 : before(order(b), order(a)) ? 1 : 0;
    });
  return [first, ...rest].slice(0, SPACED_COUNT);
}
