/** The product figures' words (P22-Figures). */
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

const FULL = [
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

function span(monday: string, names: string[]): string {
  const start = new Date(`${monday}T12:00:00Z`);
  const end = new Date(start.getTime() + 6 * 86_400_000);
  const m = (d: Date) => names[d.getUTCMonth()] as string;
  return start.getUTCMonth() === end.getUTCMonth()
    ? `${start.getUTCDate()} to ${end.getUTCDate()} ${m(end)}`
    : `${start.getUTCDate()} ${m(start)} to ${end.getUTCDate()} ${m(end)}`;
}

/** "12 to 18 Oct", "28 Sep to 4 Oct": a week from its Monday. */
export function weekLabel(monday: string): string {
  return span(monday, MONTHS);
}

/** "5 to 11 October": the report card's line, months in full (P22-Weekly-Email's grammar). */
export function weekLong(monday: string): string {
  return span(monday, FULL);
}

export const FIGURES = {
  title: "Product figures",
  lead: "What tutors did with the app, week by week, from the record’s own tables and the app’s few events: no tracker, no SDK (D82). A week runs Monday to Sunday in India; the current week so far is first. A tutor is active when they opened the app that week.",
  weeks: "Weeks",
  weekChoices: ["8", "12", "26"],
  tiles: {
    tutors: "tutors active this week",
    closes: "closes this week",
    notes: "notes sent this week",
    perTutor: "AI cost per active tutor, this week",
  },
  byWeek: "By week",
  byWeekLead:
    "Followed: a plan whose batch was closed that day. Made · again: artefacts made, and made again with a reason. Make: made from More → Make something. Consent: parents who agreed that week.",
  head: {
    week: "Week",
    tutors: "Tutors active",
    closes: "Closes",
    plans: "Plans made · followed",
    notes: "Notes sent",
    made: "Made · again",
    make: "Make",
    consent: "Consent given",
    perTutor: "Cost per active tutor",
  },
  soFar: (day: number) => `so far, to ${DAYS[day] ?? "today"}`,
  reasons: "Made again this week, by reason",
  reasonsHead: { reason: "Reason", count: "Count", of: "Of made" },
  typed: "Typed by the tutor",
  typedSub: "“Say what to change”",
  edited: "Edited at Send",
  editedSub: "a note changed before it went",
  ofNotes: (pct: number) => `${pct}% of notes`,
  report: "The weekly report",
  reportLead:
    "Emailed every Monday at 08:00 IST to the alert address: the week’s row and the week before it, in these words. No AI service writes it. Each send is a job and is written to the audit.",
  lastSent: "Last sent",
  never: "not yet sent",
  reportLine: (state: string, week: string, soFar: boolean) =>
    `${state === "done" ? "delivered" : state} · the week of ${week}${soFar ? ", so far" : ""}`,
  send: "Send this week so far, now",
  sent: "Sent to the alert address",
} as const;

/** "Less about marks": a menu's reason as it reads, first letter up. */
export function reasonLabel(reason: string): string {
  return reason.charAt(0).toUpperCase() + reason.slice(1);
}
