import { request } from "../../prompts/placement.js";
import type { ClassLevel, PlacementOutput } from "../../schemas.js";
import type { Finding, Kind } from "../agent.js";
import { rubric, words } from "./rubric.js";

export type PlacementInput = { classLevel: ClassLevel; subject: string; chapters: string[] };

/** A placement question asks one thing (the first nightly's placement, D105): no question mark but its last, the
 *  chapter's own title aside ("How Many Squares?" quoted). */
export function oneQuestionFindings(questions: PlacementOutput["questions"]): Finding[] {
  return questions
    .filter((q) => q.question.split(q.chapter).join("").trim().replace(/\?$/, "").includes("?"))
    .map((q) => ({ item: q.chapter, problem: "it asks more than one question; ask one thing in one sentence" }));
}

/** The placement: one question per chapter, the chapter as given, each asking one thing. */
export const placement: Kind<PlacementInput, PlacementOutput> = {
  kind: "placement",
  classLevel: (input) => input.classLevel,
  maths: true,
  draft: (input) => request(input.classLevel, input.subject, input.chapters),
  verify: (input, draft) => {
    const findings: Finding[] = [];
    const asked = input.chapters.join(" | ");
    if (draft.questions.map((q) => q.chapter).join(" | ") !== asked) findings.push({ item: "chapters", problem: `one question per chapter, in order, each repeating its chapter as given: ${asked}` });
    for (const q of draft.questions) if (words(q.answer) > 16) findings.push({ item: q.chapter, problem: "the answer is longer than twelve words" });
    return [...findings, ...oneQuestionFindings(draft.questions)];
  },
  rubric: rubric([
    "One question per chapter named, on the chapter's most basic idea, answered aloud in a few words; for a story or a poem, the plainest thing its title promises (who or what it is about), never an event of its plot, since only the title is given.",
    "Each expected answer is right. An answer is right by what the class's textbook teaches, not by everyday practice.",
    "A chapter's title is quoted as printed, its punctuation included (a book's exclamation mark is not the writer's).",
  ]),
};
