import type { Tone } from "@/components/parts";
import type { Consent } from "@/lib/data/types";
import { dayMonth } from "@/lib/format";

/** The record's words (P19-Centre-OpenAsk, P19-Centre-Record). */
export const ASK = {
  title: (centre: string) => `Open the record of ${centre}?`,
  lead: "Say why. The reason and the time go into the audit with your name.",
  reason: "Reason",
  reasonHint: "What you were asked, by whom",
  empty: "Say why: the reason goes into the audit.",
  cancel: "Cancel",
  open: "Open the record",
} as const;

export const RECORD = {
  eyebrow: "Centre · the record",
  lead: "Students, consent and batches as the tutor keeps them. No parent’s number, no photo, no message text.",
  opened: (time: string) => `Opened at ${time} by you`,
  reason: (reason: string) => `reason: ${reason}`,
  audited: "· written to the audit",
  students: "Students",
  studentsLead: (n: number) =>
    `${n} ${n === 1 ? "student" : "students"}. Consent is the parent’s, with its date; a withdrawal stops the personal kinds at once.`,
  head: { student: "Student", class: "Class", batch: "Batch", consent: "Consent", tracking: "Tracking" },
  batches: "Batches",
  batchHead: { batch: "Batch", meets: "Meets", time: "Time", students: "Students" },
  made: "What the AI service made about these students",
  madeLead: "Outputs only. A personal kind’s input is shown only while the student’s consent stands.",
  madeHead: { when: "When", what: "Made about them", cost: "Cost" },
  nothingKept: "Nothing kept",
  time: (start: string, end: string) => `${start} to ${end}`,
} as const;

const TRACKING: Record<string, string> = {
  on_track: "On track",
  watch: "Watch",
  not_on_track: "Not on track",
  not_known: "Not known",
};
export function tracking(status: string | null): string {
  return (status && TRACKING[status]) ?? "Not known";
}

/** Consent as its chip: given in ok, withdrawn in overdue, asked in due, not asked neutral. */
export function consentChip(c: Consent): { tone: Tone; text: string } {
  switch (c.state) {
    case "given":
      return { tone: "ok", text: `given · ${c.day ? dayMonth(c.day) : ""}` };
    case "withdrawn":
      return { tone: "overdue", text: `withdrawn · ${c.day ? dayMonth(c.day) : ""}` };
    case "asked":
      return { tone: "due", text: "asked · waiting" };
    case "not_asked":
      return { tone: "neutral", text: "not asked" };
  }
}

const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
/** A batch's days (1 Monday to 7 Sunday): "Mon to Fri" for a run of three or more, else "Tue, Thu, Sat". */
export function meets(days: number[] | null): string {
  const sorted = [...new Set(days ?? [])].filter((d) => d >= 1 && d <= 7).sort((a, b) => a - b);
  if (sorted.length === 0) return "—";
  const run = sorted.length >= 3 && sorted.every((d, i) => i === 0 || d === (sorted[i - 1] ?? 0) + 1);
  if (run) return `${DAYS[(sorted[0] ?? 1) - 1]} to ${DAYS[(sorted[sorted.length - 1] ?? 1) - 1]}`;
  return sorted.map((d) => DAYS[d - 1]).join(", ");
}

/** What was made, in words: "Hemanth’s gap report · Science unit test 2", "Practise set 1 · sheet". */
export function madeWords(m: { kind: string; title: string | null; student: string | null }): string {
  const kind = m.kind.replace(/_/g, " ");
  if (m.student) return `${m.student.split(" ")[0]}’s ${kind}${m.title ? ` · ${m.title}` : ""}`;
  return m.title ? `${m.title} · ${kind}` : kind;
}
