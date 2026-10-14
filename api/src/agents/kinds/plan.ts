import { request } from "../../prompts/plan.js";
import { syllabusBoards } from "../../prompts/shared.js";
import type { PlanInput, PlanOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric } from "./rubric.js";

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
/** How far a chapter may sit from the month's place in the year, as a share of the list. */
const PLACE = 0.25;

const plain = (name: string) => name.toLowerCase().replace(/[’‘]/g, "'").replace(/\s+/g, " ").trim();

/** Where a chapter sits in the class's list (the first nightly's plans, D105): listed when a board prints it (case
 *  aside, with or without the data's part or form label, or the start of a printed name up to a word's end), with its
 *  place as a share of the list; a class the data
 *  does not cover (below 8) holds any chapter, with no count. */
export function chapterInSyllabus(classLevel: string, subject: string, chapter: string): { listed: boolean; share?: number; count?: number } {
  const found = syllabusBoards(classLevel, subject);
  if (!found) return { listed: true };
  const named = plain(chapter);
  const lists = Object.values(found.boards);
  for (const list of lists) {
    const at = list.findIndex((printed) => {
      // The data's labels ("Part I: Number Play", "Prose: The Heavenly Parasol") are the book's sections, not the name.
      const whole = plain(printed);
      return [whole, whole.replace(/^[^:]{1,20}:\s*/, "")].some((p) => p === named || (named.length > 0 && p.startsWith(named) && !/[a-z0-9]/.test(p.charAt(named.length))));
    });
    if (at >= 0) return { listed: true, share: at / list.length, count: list.length };
  }
  return { listed: false, count: lists[0]?.length ?? 0 };
}

/** The month's place in the school year as a share: June 0 to March 0.9; April and May, the year's start, 0. */
export function monthShare(month: number): number {
  const place = (month + 6) % 12;
  return place > 9 ? 0 : place / 10;
}

/** The plan's naming: one first topic per group asked; where the syllabus lists the class's chapters, one of them, near
 *  the month's place in the year. */
export const plan: Kind<PlanInput, PlanOutput> = {
  kind: "plan",
  classLevel: (input) => input.groups[0]?.classLevel,
  draft: (input) => request(input),
  verify: (input, draft) => {
    const asked = input.groups.map((g) => g.groupNo).sort();
    const named = [...new Set(draft.groups.map((g) => g.groupNo))].sort();
    if (asked.join(",") !== named.join(",") || draft.groups.length !== asked.length) return [{ item: "groups", problem: `one topic for each group asked: ${asked.join(", ")}` }];
    const findings: Finding[] = [];
    for (const g of draft.groups) {
      const group = input.groups.find((x) => x.groupNo === g.groupNo);
      if (!group) continue;
      const place = chapterInSyllabus(group.classLevel, group.subject, g.chapter);
      if (!place.listed) findings.push({ item: `group ${g.groupNo}`, problem: `"${g.chapter}" is not a chapter the class's book lists; name one from the list as printed` });
      else if (place.share !== undefined && place.count && Math.abs(place.share - monthShare(input.month)) > PLACE) {
        findings.push({ item: `group ${g.groupNo}`, problem: `"${g.chapter}" is chapter ${Math.round(place.share * place.count) + 1} of ${place.count}; in ${MONTHS[input.month - 1]} a class is about ${Math.round(monthShare(input.month) * 100)}% of the way through the list` });
      }
    }
    return findings;
  },
  rubric: rubric([
    "One chapter and one skill for each group, a chapter a class of that level is usually at in the month given (the school year runs June to March, June the first month of ten).",
    "Where the request lists the class's chapters, the chapter is one from that list as printed; where it does not, a chapter or a plain topic name a class of that level studies, never a chapter of another class's book; a skill a tutor can teach in one class and check with one question.",
  ]),
};
