import { expect, test } from "bun:test";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeJobsDb } from "../src/jobs/db-fake.js";
import { type ReminderSource, reminderSweep } from "../src/jobs/kinds/reminder-sweep.js";
import type { Job, StepContext, StepOutcome } from "../src/jobs/types.js";
import type { NotificationRow } from "../src/push/db.js";
import { DEFAULT_SETTINGS, type ReminderSettings } from "../src/reminders/settings.js";
import type { ReminderClass } from "../src/reminders/planner.js";

// The reminder plan (plan decision 7, review focus 2): each member with a live token gets the next 26 hours of their
// reminders in the outbox, by their own settings; a moved class's old reminder is replaced in one transaction.
const CENTRE = "c0000000-0000-4000-8000-0000000000aa";
const USER = "u0000000-0000-4000-8000-000000000001";

function fakeReminderSource(over: { classes: ReminderClass[]; users: string[]; settings?: Record<string, Partial<ReminderSettings>> }) {
  const replaced: { centre: string; user: string; kinds: string[]; from: string; rows: NotificationRow[] }[] = [];
  const src: ReminderSource & { classes: ReminderClass[]; settings: Record<string, Partial<ReminderSettings>>; replaced: typeof replaced; centres: string[] } = {
    classes: over.classes,
    settings: over.settings ?? {},
    replaced,
    centres: [],
    async read(centre, today) {
      src.centres.push(centre);
      return {
        classes: src.classes,
        memberCounts: Object.fromEntries(src.classes.map((c) => [c.id, 3])),
        events: [],
        dueFees: null,
        users: over.users.map((user) => ({ user, settings: { ...DEFAULT_SETTINGS, ...(src.settings[user] ?? {}) } })),
        today,
      };
    },
    async replace(centre, user, kinds, from, rows) {
      replaced.push({ centre, user, kinds, from, rows });
      return rows.length;
    },
  };
  return src;
}
const cls = (id: string, name: string, days: number[], start: string): ReminderClass => ({ id, name, days, start, end: null });
const jobFor = (centre: string): Job => ({ id: "job-1", centreId: centre, kind: "reminder_sweep", attempts: 1, step: {}, input: { centre_id: centre }, leaseUntil: "" });
const at = (iso: string) => {
  const now = Date.parse(iso);
  return { now: () => now, sleep: async () => {} };
};
async function run(handler: ReturnType<typeof reminderSweep>, job: Job, clock: ReturnType<typeof at>): Promise<StepOutcome> {
  const ctx: StepContext = { db: fakeDb(), jobs: fakeJobsDb(clock as never), claude: fakeClaude({}), clock, requestId: "r1", worker: "w1" };
  return handler.step(job, ctx);
}

test("a replan cancels the unsent row of a moved class and writes its new one", async () => {
  const src = fakeReminderSource({ classes: [cls("c1", "Class 10 Maths", [1], "17:00")], users: [USER] });
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:00:00+05:30"));
  expect(src.replaced.at(-1)!.rows.map((r) => [r.key, r.due_at])).toContainEqual(["class:c1:2026-11-02T17:00", "2026-11-02T16:00:00+05:30"]);
  src.classes[0]!.start = "17:30";
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T16:00:00+05:30"));
  const last = src.replaced.at(-1)!;
  expect(last.rows.map((r) => [r.key, r.due_at])).toContainEqual(["class:c1:2026-11-02T17:30", "2026-11-02T16:30:00+05:30"]);
  expect(last.rows.map((r) => r.key)).not.toContain("class:c1:2026-11-02T17:00");
  expect(last).toMatchObject({ centre: CENTRE, user: USER, kinds: ["class", "event", "fees"], from: "2026-11-02T10:30:00.000Z" });
});

test("the tutor's settings decide: classes off writes no class rows; 15 minutes moves them", async () => {
  const src = fakeReminderSource({ classes: [cls("c1", "Class 10 Maths", [1], "17:00")], users: [USER], settings: { [USER]: { classOn: false } } });
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:00:00+05:30"));
  expect(src.replaced.at(-1)!.rows.filter((r) => r.kind === "class")).toEqual([]);
  src.settings[USER] = { classOn: true, classMinutes: 15 };
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:01:00+05:30"));
  expect(src.replaced.at(-1)!.rows.find((r) => r.kind === "class")!.due_at).toBe("2026-11-02T16:45:00+05:30");
});

test("only the next 26 hours are written, with the words and the link", async () => {
  const src = fakeReminderSource({ classes: [cls("c1", "Class 10 Maths", [1, 2, 3], "17:00")], users: [USER] });
  // Monday 15:00 to Tuesday 17:00: Monday's and Tuesday's 16:00, not Wednesday's.
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T15:00:00+05:30"));
  expect(src.replaced.at(-1)!.rows).toEqual([
    { kind: "class", key: "class:c1:2026-11-02T17:00", due_at: "2026-11-02T16:00:00+05:30", title: "Class 10 Maths at 17:00", body: "In 1 hour · 3 students. Open for today's plan.", link: "tutorcentral://today" },
    { kind: "class", key: "class:c1:2026-11-03T17:00", due_at: "2026-11-03T16:00:00+05:30", title: "Class 10 Maths at 17:00", body: "In 1 hour · 3 students. Open for today's plan.", link: "tutorcentral://today" },
  ]);
});

test("a member without a live token gets nothing; the job is done with users 0", async () => {
  const src = fakeReminderSource({ classes: [cls("c1", "Class 10 Maths", [1], "17:00")], users: [], settings: {} });
  const out = await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:00:00+05:30"));
  expect(out).toMatchObject({ kind: "done", result: { users: 0, rows: 0 } });
  expect(src.replaced).toEqual([]);
});

test("the job reads the centre of its own row, never its input's", async () => {
  const src = fakeReminderSource({ classes: [], users: [USER] });
  await run(reminderSweep(src), { ...jobFor(CENTRE), input: { centre_id: "someone-else" } }, at("2026-11-02T10:00:00+05:30"));
  expect(src.centres).toEqual([CENTRE]);
});
