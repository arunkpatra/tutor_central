import type { Tone } from "@/components/parts";
import { count, shortId } from "@/lib/format";

/** The calls' words (P19-Calls, P19-Call). */
export const CALLS = {
  title: "AI calls",
  lead: "Every paid call, recorded once at its finish: the kind, the model, the prompt version, the tokens, the latency, the outcome and the fallback when one was used.",
  day: "Day",
  days: { today: "Today", yesterday: "Yesterday", all: "All days" },
  centre: "Centre",
  kind: "Kind",
  outcome: "Outcome",
  all: "All",
  outcomes: { ok: "ok", failed: "failed", refused: "refused", pending: "pending" },
  tiles: {
    calls: (day: string) => (day === "all" ? "calls" : `calls ${day === "today" ? "today" : "yesterday"}`),
    failed: "failed",
    refused: "refused",
    latency: "median latency",
  },
  list: (day: string) => `${day === "all" ? "Every day" : day === "today" ? "Today" : "Yesterday"}, newest first`,
  listLead:
    "A row opens with its input and output. A personal kind’s input is shown only while the student’s consent stands; a parent’s number never.",
  head: {
    time: "Time",
    centre: "Centre",
    kind: "Kind",
    outcome: "Outcome",
    tokens: "Tokens in · out",
    latency: "Latency",
    cost: "Cost",
    from: "From",
  },
  /** A check, repair or grade beside its kind ("sheet · check"); a draft is its kind alone. */
  kindStep: (kind: string, step: string) => (step === "draft" ? kind : `${kind} · ${step}`),
  sub: (model: string, version: string | null, student: boolean) =>
    [model, version, student ? "student" : null].filter(Boolean).join(" · "),
} as const;

export const CALL = {
  eyebrow: (at: string) => `AI call · ${at}`,
  title: (kind: string, centre: string | null) => `${kind}, ${centre ?? "no centre"}`,
  openJob: "Open the job",
  head: { fact: "Fact", value: "Value" },
  facts: {
    kind: "Kind",
    model: "Model",
    prompt: "Prompt",
    step: "Step",
    outcome: "Outcome",
    tokens: "Tokens",
    latency: "Latency",
    cost: "Cost",
    started: "Started by",
    request: "Request",
    centre: "Centre",
  },
  kindOf: (kind: string, personal: boolean) =>
    `${kind} · ${personal ? "a personal kind (a student)" : "a group kind (no student)"}`,
  model: (model: string, fallback: string | null) => `${model} · ${fallback ? `fallback ${fallback}` : "no fallback"}`,
  /** The agent's step in the trade's words (D99). */
  step: (step: string) =>
    ({
      draft: "draft · the first answer",
      check: "check · the other model held it to the rubric",
      repair: "repair · the draft fixed once",
      grade: "grade · the nightly evals' grader",
    })[step] ?? step,
  prompt: (kind: string, version: string | null, hash: string | null) =>
    `${kind} ${version ?? ""}${hash ? ` · hash ${shortId(hash)}` : ""}`,
  outcomeMore: (stop: string | null, error: string | null) =>
    ` · stop reason ${stop ?? "none"}${error ? ` · error_reason ${error}` : ""}`,
  tokens: (inn: number | null, out: number | null) =>
    `${count(inn ?? 0)} in · ${count(out ?? 0)} out${inn === null ? "" : " · billed"}`,
  latency: (ms: string, deadline: boolean) => `${ms} ms${deadline ? " (the deadline)" : ""}`,
  cost: (rupees: string, paise: number) => `${rupees} (${paise} paise)`,
  started: (by: string, subject: string | null, step: string | null) =>
    [by, subject, step ? `step ${step}` : null].filter(Boolean).join(" · "),
  openJobLink: "open the job",
  request: (id: string | null, key: string | null) =>
    [id ? `request id ${shortId(id)}` : null, key ? `idempotency key ${shortKey(key)}` : null]
      .filter(Boolean)
      .join(" · ") || "—",
  input: "Input",
  output: "Output",
  held: "Held: the student’s consent is not current",
  reduced: "Reduced after 90 days: only what came back is kept (D79)",
  noOutput: "No output: the call ended without an answer.",
  openCentre: "Open the centre",
} as const;

/** The call's Feedback row (P22-Call-Feedback, D107): the kind, the reason and the time; never the revised text. */
export const FEEDBACK = {
  label: "Feedback",
  again: (reason: string | null, at: string) => `made again · ${reason ?? "no reason"} · ${at}`,
  replace: (at: string) => `replaced · ${at}`,
  edit: (at: string) => `edited at Send · ${at} · the text is never shown here`,
} as const;

/** The deadline of both tries (api's CLAUDE_DEADLINE_MS): a call at it timed out. */
export const DEADLINE_MS = 110_000;

/** An outcome as its chip: ok; refused and unfit in due; failed with its reason in overdue; pending neutral. */
export function outcomeChip(status: string, reason: string | null): { tone: Tone; text: string } {
  if (status === "ok") return { tone: "ok", text: "ok" };
  if (status === "pending") return { tone: "neutral", text: "pending" };
  if (reason === "refused" || reason === "unfit") return { tone: "due", text: reason };
  // Refused after its check and one repair (D99): the tutor read the kind's refusal.
  if (reason?.startsWith("check:")) return { tone: "due", text: `refused · ${reason}` };
  return { tone: "overdue", text: reason ? `failed · ${reason}` : "failed" };
}

const GENERIC = new Set(["tuition", "centre", "center", "classes", "coaching", "academy", "institute"]);
/** A centre's name as the lists write it: before a comma, without its trailing "Tuition Centre". */
export function shortCentre(name: string | null): string {
  if (!name) return "—";
  const words = (name.split(",")[0] ?? name).trim().split(/\s+/);
  while (words.length > 1 && GENERIC.has((words[words.length - 1] ?? "").toLowerCase())) words.pop();
  return words.join(" ");
}

/** An idempotency key with its id cut: "c9f2…e4a1:make:4". */
export function shortKey(key: string): string {
  const m = key.match(/^([0-9a-f]{8}-[0-9a-f-]{27})(.*)$/i);
  return m?.[1] ? `${shortId(m[1])}${m[2] ?? ""}` : key;
}

/** The kinds a call can be, for the filter (0012's ai_kind and later). */
export const CALL_KINDS = [
  "plan",
  "sheet",
  "worked_example",
  "figure",
  "brief",
  "check",
  "placement",
  "mock",
  "note",
  "can_do",
  "test_tomorrow",
  "not_on_track",
  "progress_note",
  "gap_report",
  "check_paper",
  "read_marks",
  "parse_school",
  "parse_textbook",
] as const;
