import { PAUSED, PROMPT_VERSIONS } from "@/lib/generated/contract";

/** A model's id as the boards write it: "claude-sonnet-5-5" is "Sonnet 5.5", its family "Sonnet". */
const ID = /^claude-([a-z]+)-(\d+)-(\d+)$/;

export function family(model: string | null): string {
  const m = model?.match(ID);
  return m?.[1] ? m[1].charAt(0).toUpperCase() + m[1].slice(1) : (model ?? "—");
}

export function modelName(model: string | null): string {
  const m = model?.match(ID);
  return m ? `${family(model)} ${m[2]}.${m[3]}` : (model ?? "—");
}

/** The models the API can price (api/models.json's sheet; `known-models.test.ts` holds them equal): a change naming any
 *  other is refused before it is written. */
export const KNOWN_MODELS = ["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"] as const;
export function knownModel(name: string): boolean {
  return (KNOWN_MODELS as readonly string[]).includes(name);
}
export const STEPS = ["draft", "check", "repair"] as const;
export const EFFORTS = ["low", "medium", "high"] as const;

/** Each kind of work in a line (P22-Models), and the longer words of its page's lead where the board has them. */
const KINDS: Record<string, { line: string; about?: string }> = {
  plan: { line: "the plan's groups and lines" },
  mock: { line: "a mock test for an exam" },
  brief: {
    line: "the chapter brief",
    about: "The chapter brief: what to teach, the slip to watch for, one worked example.",
  },
  sheet_to_5: { line: "a sheet, LKG to class 5" },
  sheet_from_6: { line: "a sheet, class 6 to 10" },
  placement: { line: "a new student's first checks" },
  check_paper: { line: "marks from a photo of an answered paper" },
  gap_report: { line: "the last days from a student's marks" },
  note: { line: "the weekly note to a parent" },
  can_do: { line: "what a young student can now do" },
  worked_example: { line: "a worked example with its slip" },
  scan_register: { line: "names from a paper register" },
  figure: { line: "a figure for a skill" },
  check: { line: "a short check of a skill" },
  parse_school: { line: "a test, homework or holiday from a school's message" },
  parse_textbook: { line: "the chapters from a textbook's contents page" },
  test_tomorrow: { line: "the message to a parent before a test" },
  not_on_track: { line: "the message to a parent when a student is not on track" },
  read_marks: { line: "marks from a photo of a report card" },
  paper: { line: "a question paper" },
  homework: { line: "a homework sheet" },
  worksheet: { line: "a worksheet" },
  progress_note: { line: "a progress note to a parent" },
};

export function kindLine(kind: string): string {
  return KINDS[kind]?.line ?? kind;
}

/** The Models page (P22-Models). */
export const MODELS = {
  title: "AI models",
  lead: "The model, effort and fallback of each kind of work and its three steps, as the API reads them each minute. A change is a new row and the rows before it stay as the history. A kind switched off refuses in the tutor’s words within a minute.",
  show: "Show",
  shows: { all: "All kinds", off: "Switched off", changed: "Changed by hand" },
  tiles: { kinds: "kinds", off: "switched off", changes: "changes this month", last: "last change" },
  never: "never",
  list: "Every kind, by its draft step",
  listLead:
    "The draft is the answer the tutor gets; the check runs on the other tier; the repair is the draft’s model once more.",
  head: { kind: "Kind", draft: "Draft", check: "Check", repair: "Repair", on: "On", changed: "Changed", act: "" },
  on: "on",
  off: "off",
  change: "Change",
  fallback: (model: string) => `fallback ${model}`,
  how: "How a change takes effect",
  howLines: [
    ["Within a minute", "the API reads the table once a minute; the next call after that uses the new row."],
    [
      "Switched off",
      "a tap is refused in the tutor’s words; a job counts the request not made and pays nothing; the golden sets skip the kind.",
    ],
    ["The override", "an AI_MODEL_<KIND> set at deploy wins over the table (D100); none is set today."],
    ["The seed", "api/models.json seeds a new kind and prices every call; the table is the truth for a running one."],
  ],
} as const;

/** One kind's page (P22-Model, P22-Model-SwitchOff). */
export const MODEL = {
  eyebrow: (kind: string) => `AI model · ${kind}`,
  lead: (kind: string) => {
    const about = KINDS[kind]?.about ?? `${kindLine(kind).charAt(0).toUpperCase()}${kindLine(kind).slice(1)}.`;
    const version = PROMPT_VERSIONS[kind];
    return `${about} Each step on its own model; the check on the other tier. ${
      version ? `Its golden set and prompt version: ${kind.startsWith("sheet_") ? "sheet" : kind} v${version}.` : ""
    }`.trim();
  },
  switchOff: "Switch off",
  switchOn: "Switch on",
  current: "Current",
  head: { step: "Step", model: "Model", effort: "Effort", fallback: "Fallback", on: "On", since: "Since" },
  steps: {
    draft: "the answer the tutor reads",
    check: "the other tier, against the rubric",
    repair: "the draft fixed once, with the findings",
  },
  change: "Change a step",
  changeLead: "Pick the step and what it runs on. Effort is the model’s thinking: low, medium or high.",
  noFallback: "none",
  note: "Note, for the history",
  noteHint: "Why: what you saw, what you expect",
  save: "Save: a new row from now",
  saveNote:
    "The API reads it within a minute. The step stays switched on; Switch off above stops the whole kind. Written to the audit.",
  badModel: "Not a model this API knows",
  history: "History",
  historyLead: "Every row ever written for this kind, newest first. Nothing here is edited or deleted.",
  historyHead: {
    when: "When",
    step: "Step",
    model: "Model",
    effort: "Effort",
    fallback: "Fallback",
    on: "On",
    by: "By",
    note: "Note",
  },
  you: "you",
  seed: (note: string | null) => (note ? `seed ${note}` : "seed"),
  offTitle: (kind: string) => `Switch off ${kind}?`,
  offLead: (kind: string) =>
    `From the next minute every ${kind} is refused in the tutor’s words: “${PAUSED[kind] ?? ""}” A job counts it not made and pays nothing. Written to the history and the audit with your reason.`,
  reason: "Reason",
  reasonHint: "What you saw, and what you will check",
  empty: "Say why: it goes to the history and the audit.",
  cancel: "Cancel",
  switchedOn: "switched on",
} as const;
