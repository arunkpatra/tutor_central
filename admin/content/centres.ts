/** The centres' words (P19-Centres, P19-Centre). */
export const CENTRES = {
  title: "Centres",
  lead: "Every centre on Tutor Central, its tutors, what it spent this month against ₹499, and its jobs today.",
  sort: "Sort",
  sorts: { cost: "Cost this month", name: "Name", opened: "Last opened" },
  show: "Show",
  shows: { all: "All", "in-use": "In use", idle: "Idle" },
  tiles: {
    centres: (n: number) => (n === 1 ? "centre" : "centres"),
    active: "active this week",
    cost: "AI cost this month",
    failed: (n: number) => (n === 1 ? "job failed today" : "jobs failed today"),
  },
  list: "All centres",
  listLead:
    "A centre is in use when its tutor opened the app in the last 14 days; the morning plans run for those alone.",
  head: {
    centre: "Centre",
    students: "Students",
    tutors: "Tutors",
    opened: "Last opened",
    cost: "Cost this month, of ₹499",
    jobs: "Jobs",
  },
  since: (owner: string | null, day: string) => `${owner ?? "no owner"} · since ${day}`,
  never: "never",
  idle: "idle",
  jobs: (today: number, failed: number, inUse: boolean) =>
    today === 0 ? (inUse ? "0 today" : "none: not in use") : `${today} today · ${failed} failed`,
} as const;

export const CENTRE = {
  eyebrow: "Centre",
  lead: (owner: string | null, since: string, students: number, batches: number) =>
    `${owner ?? "no owner"} · since ${since} · ${students} ${students === 1 ? "student" : "students"} · ${batches} ${batches === 1 ? "batch" : "batches"}`,
  inUse: "in use",
  idle: "idle",
  month: "Month",
  tiles: {
    cost: "AI cost this month",
    calls: "calls this month",
    jobs: "jobs today · failed",
    lastClose: (day: string) => `last close, ${day}`,
    noClose: "no close yet",
  },
  tutorsAndCost: "Tutors and cost",
  head: { tutor: "Tutor", email: "Email", signIn: "Last sign-in", push: "Push" },
  push: (build: number | null) => (build ? `iPhone · build ${build}` : "iPhone"),
  noDevice: "no device",
  monthSoFar: (month: string) => `${month} so far`,
  allowance: (calls: number | null, cap: string | null) =>
    `allowance ${calls ?? "no"} ${calls === 1 ? "call" : "calls"} · ${cap ? `${cap} cap` : "₹0 cap (none)"}`,
  ofPlan: (pct: number) => `of ₹499 · ${pct}%`,
  calls: (n: number) => `${n} ${n === 1 ? "call" : "calls"}`,
  byKind: (plan: string, notes: string, exams: string) => `plan ${plan} · notes ${notes} · exams ${exams}`,
  jobs: "Jobs",
  jobsLead: "The last five; every job of the centre is on the Jobs page.",
  allJobs: "All jobs of this centre",
  jobsHead: { kind: "Kind", subject: "Subject", state: "State", finished: "Finished", cost: "Cost" },
  activity: "Activity",
  activityLead: "What the tutor did, by kind and time. Never the content.",
  activityHead: { when: "When", what: "What", who: "Who" },
  record: "The centre’s record",
  recordLead:
    "Students by name, their consent and their batches. Opening it is written to the audit with your reason. A parent’s number and a student’s photos are never shown here.",
  openRecord: "Open the record",
  changeAllowance: "Change",
} as const;

/** The allowance's dialog (P22-Centre-Allowance). */
export const ALLOWANCE = {
  title: (centre: string) => `Change the allowance of ${centre}?`,
  lead: "Calls a month, and a cap on the month’s cost in rupees. The next call the centre makes meets the new limit; a draft alone counts. Written to the audit with your reason.",
  calls: "Calls a month",
  cap: "Cap, ₹ a month",
  capHint: "0 is no cap",
  reason: "Reason",
  reasonHint: "Who asked, and why",
  empty: "Say why: the reason goes into the audit.",
  bad: "Whole numbers, 0 or more",
  badCalls: "Calls a month: 1 or more",
  cancel: "Cancel",
  save: "Save the allowance",
} as const;

/** The allowance line every centre is measured against (D64): ₹499 a month, in paise. */
export const PLAN_PAISE = 49_900;
