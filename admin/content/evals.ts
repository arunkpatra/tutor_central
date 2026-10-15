/** The golden sets' words (P22-Evals). */
export const EVALS = {
  title: "Golden sets",
  lead: "Each kind’s golden set run on its agent and graded by Opus 5.5 (D74): the last run per kind, what failed and why. The gate is every free check and the rubric at 85% a kind, a failed case tried once more (D103). Runs start only when a person starts one (D112).",
  show: "Show",
  shows: { all: "Last run per kind", below: "Below the gate" },
  tiles: {
    kinds: "kinds with a golden set",
    passed: "passed on their last run",
    below: "below the gate",
    last: "last run · its cost",
  },
  list: "Last run per kind",
  listLead:
    "Schema · verify: the free checks passed. Check pass: the other tier’s check with no finding. Rubric: the grader’s pass rate, 85% is the gate.",
  head: {
    kind: "Kind",
    run: "Last run",
    cases: "Cases",
    free: "Schema · verify",
    check: "Check pass",
    rubric: "Rubric",
    gate: "Gate",
    cost: "Cost",
  },
  nightly: "the nightly set",
  here: "started here",
  never: "never",
  passed: "passed",
  below: "below the gate",
  noRun: "no run yet",
  failed: "What failed on the last run",
  failedLead: "The grader’s reason for each case, as the result keeps it.",
  failedHead: { case: "Case", why: "Why" },
  run: "Run golden sets now",
  runLead:
    "Queues one run as the nightly did: every case of the chosen kinds as Message Batches at half price under the Smoke centre, about ₹10 a kind. A person starts it here, with bun evals, or with the workflow; nothing starts it on its own (D112). The run is a job; starting it is written to the audit.",
  every: "every kind",
  button: (n: number | null, rupees: number) =>
    n === null
      ? `Run every kind now · about ₹${rupees}`
      : `Run ${n} ${n === 1 ? "kind" : "kinds"} now · about ₹${rupees}`,
  runNote:
    "The result lands on this page when the batches end, usually within the hour; the job is on the Jobs page meanwhile.",
  queued: "Queued: the result lands here when the batches end",
  openJob: "open the job",
  busy: "A run is already queued: see the Jobs page",
} as const;

/** About ₹10 a kind (D116's card). */
export const RUPEES_A_KIND = 10;
