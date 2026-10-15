/** The weekly report's words (D115, P22-Weekly-Email): plain text from `admin_figures` (0067), the week before in
 *  brackets, no tutor's or student's name. Pure. */
export type Figures = {
  week_monday: string;
  so_far: boolean;
  tutors_active: number;
  closes: number;
  plans_made: number;
  plans_followed: number;
  notes_sent: number;
  made: number;
  again: number;
  make: number;
  consent_given: number;
  cost_paise: number;
  per_active_tutor_paise: number;
};
/** `admin_reasons_week`: a menu's reason by its words, the tutor's own as `typed`. */
export type Reasons = {
  again: { reason: string; count: number }[];
  edits: number;
  made: number;
  notes: number;
};
export type ReportInput = {
  week: Figures;
  before: Figures;
  reasons: Reasons;
  centres: { total: number; inUse: number };
  openAlerts: number;
  soFar: boolean;
};

export const FIGURES_PAGE = "https://admin.tutorcentral.in/figures";
const MONTHS = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

/** ₹214, ₹3.26: rupees as the portal writes them. */
function rupees(paise: number): string {
  const r = paise / 100;
  if (r === 0) return "₹0";
  return r < 10 ? `₹${r.toFixed(2)}` : `₹${Math.round(r).toLocaleString("en-IN")}`;
}

/** "6 to 12 October", "29 September to 5 October"; "13 October so far". */
export function weekWords(monday: string, soFar: boolean): string {
  const start = new Date(`${monday}T12:00:00Z`);
  const end = new Date(start.getTime() + 6 * 86_400_000);
  const day = (d: Date) => d.getUTCDate();
  const month = (d: Date) => MONTHS[d.getUTCMonth()] as string;
  if (soFar) return `${day(start)} ${month(start)} so far`;
  return start.getUTCMonth() === end.getUTCMonth()
    ? `${day(start)} to ${day(end)} ${month(end)}`
    : `${day(start)} ${month(start)} to ${day(end)} ${month(end)}`;
}

export function reportText(input: ReportInput): {
  subject: string;
  text: string;
} {
  const { week: w, before: b, reasons, centres, openAlerts, soFar } = input;
  const span = weekWords(w.week_monday, soFar);
  const reasonLine =
    reasons.again.length > 0
      ? `made again by reason: ${reasons.again.map((r) => `${r.reason} ${r.count}`).join(" · ")}`
      : null;
  const lines = [
    `The week of ${span}, with the week before in brackets.`,
    "",
    `Tutors active: ${w.tutors_active} (${b.tutors_active})`,
    `Closes: ${w.closes} (${b.closes})`,
    `Plans made: ${w.plans_made} · followed: ${w.plans_followed} (${b.plans_made} · ${b.plans_followed})`,
    `Notes sent: ${w.notes_sent} (${b.notes_sent})`,
    `Made: ${w.made} · made again: ${w.again} (${b.made} · ${b.again})`,
    ...(reasonLine ? [reasonLine] : []),
    `Make something: ${w.make} (${b.make})`,
    `Consent given: ${w.consent_given} (${b.consent_given})`,
    `AI cost: ${rupees(w.cost_paise)} · per active tutor ${rupees(w.per_active_tutor_paise)} (${rupees(b.cost_paise)} · ${rupees(b.per_active_tutor_paise)})`,
    `Centres: ${centres.total} · in use: ${centres.inUse} · open alerts: ${openAlerts}`,
    "",
    `The figures, by week: ${FIGURES_PAGE}`,
    "",
    `${soFar ? "Sent from the figures page" : "Sent every Monday at 08:00 IST"} by Tutor Central’s own job. No AI service wrote this; nothing in it names a tutor or a student.`,
  ];
  return {
    subject: `Tutor Central, the week of ${span}`,
    text: lines.join("\n"),
  };
}
