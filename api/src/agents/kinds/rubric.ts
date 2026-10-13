/** What every kind's rubric holds (plan decision 10): the facts only from the request, the class's level, the format and
 *  limits, the language. A kind adds its own lines. The same text is `api/evals/<kind>/rubric.md`. */
export function rubric(own: string[]): string {
  return [
    "- Facts come only from the request: no student, school, place or page text that the request does not give.",
    "- The level fits the class named: a student of that class, at a tuition centre in India, can do it.",
    "- The words are Indian English in the idiom of CBSE and state-board classrooms; sentence case; no exclamation marks.",
    "- Nothing is copied from a textbook.",
    ...own.map((line) => `- ${line}`),
  ].join("\n");
}

/** A count of words, as a reader counts them. */
export const words = (text: string) => text.trim().split(/\s+/).filter(Boolean).length;
