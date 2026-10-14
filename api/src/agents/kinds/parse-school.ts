import { request, type ParseSchoolSource } from "../../prompts/parse-school.js";
import type { ParseSchoolOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";

const DAY = 86_400_000;

/** What the school sent read into items: dates no older than 400 days, a class only from the centre's, a school only
 *  from those given; a message with nothing announced is refused before any check. */
export const parseSchool: Kind<ParseSchoolSource, ParseSchoolOutput> = {
  kind: "parse_school",
  classLevel: (input) => input.classLevels[0],
  draft: (input) => request(input),
  empty: (draft) => draft.items.length === 0,
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const oldest = Date.parse(input.today) - 400 * DAY;
    draft.items.forEach((item, i) => {
      const at = `item ${i + 1}`;
      for (const day of [item.date, item.endDate]) if (day && Date.parse(day) < oldest) findings.push({ item: at, problem: `${day} is more than 400 days before today` });
      if (item.classLevel && input.classLevels.length > 0 && !input.classLevels.includes(item.classLevel)) findings.push({ item: at, problem: `class ${item.classLevel} is not one of the centre's classes` });
      if (item.school && !input.schools.includes(item.school)) findings.push({ item: at, problem: `${item.school} is not one of the schools given` });
      // Portions belong to an exam or homework; a notice's day and time are its title's and date's (D105).
      if ((item.kind === "notice" || item.kind === "holiday") && item.portions !== null) findings.push({ item: at, problem: `a ${item.kind} has no portions` });
    });
    return findings;
  },
  rubric: [
    "- One item per announcement in what the school sent, and nothing it did not announce. When school reopens or classes resume after a holiday, that is the holiday's end, not an item of its own.",
    "- Titles and portions in the school's own words; a subject only when one is named.",
    "- Each date is the one the message gives, resolved from today's date; a date the message does not give is null, never guessed.",
    "- A student's name only when the message is about one student.",
  ].join("\n"),
};
