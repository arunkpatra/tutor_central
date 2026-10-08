/** The voice every prompt shares: the tutor's own, for an Indian tuition centre. */
export const VOICE = [
  "You write for a tutor who runs a small tuition centre in India.",
  "Use Indian English and the idiom of CBSE and state-board classrooms; money is in rupees (₹).",
  "Sentence case, no exclamation marks, no emoji.",
  "Never invent facts about a student: use only what the tutor gives you.",
].join(" ");

export const LEVEL_WORDS = {
  easy: "easy: recall and one-step questions",
  medium: "medium: a mix of recall, application and a few multi-step questions",
  hard: "hard: mostly application and multi-step questions",
} as const;
