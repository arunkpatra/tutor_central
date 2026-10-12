import { expect, test } from "bun:test";
import { fakeClaude, kindOf, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { type NoteRead, type NoteSource, noteDay, weekEnding } from "../src/jobs/kinds/note-day.js";
import type { Job, StepContext, StepOutcome } from "../src/jobs/types.js";
import type { NotificationRow } from "../src/push/db.js";

// The note day's job (plan decision 13, review focus 4): each consented student's note made and kept as the phone kept
// it; a student without consent is held, never paid; the tutor told the notes are ready.
const CENTRE = "c0000000-0000-4000-8000-0000000000aa";
const CLASS = "c0000000-0000-4000-8000-000000000001";
const DEV = "a0000000-0000-4000-8000-000000000001";
const RIYA = "a0000000-0000-4000-8000-000000000002";
const SAHIL = "a0000000-0000-4000-8000-000000000003";
const SUNDAY = "2026-10-11";

const chapter = { id: "b0000000-0000-4000-8000-000000000001", subject: "Science", position: 1, name: "Chemical reactions" };
const skill = { id: "d0000000-0000-4000-8000-000000000001", chapterID: chapter.id, position: 1, name: "Balancing equations", state: "taught" as const, stateAt: "2026-10-06T11:30:00Z" };
const ladder = { id: "b0000000-0000-4000-8000-000000000002", subject: "English", position: 1, name: "Reading", ladder: "reading" };
const steps = ["Letters", "Words", "Sentences", "Paragraph", "Story"].map((name, i) => ({
  id: `d0000000-0000-4000-8000-00000000001${i}`,
  chapterID: ladder.id,
  position: i + 1,
  name,
  state: (i < 2 ? "secure" : "not_started") as "secure" | "not_started",
  stateAt: i === 1 ? "2026-10-07T11:30:00Z" : "2026-09-01T11:30:00Z",
}));
function entry(id: string, name: string, over: Partial<NoteRead["students"][number]> = {}): NoteRead["students"][number] {
  return {
    student: { id, name, parentName: `${name}'s parent`, classLevel: "8", language: "en" },
    week: weekEnding(SUNDAY),
    record: { student: { id, name, classLevel: "8" }, chapters: [chapter], skills: [skill], checks: [], sessions: [], marks: [], items: [] },
    kept: false,
    ...over,
  };
}
function source(students: NoteRead["students"], users = [{ user: "u1", planReady: true, notesReady: true }]) {
  const kept: { student: string; key: string; kind: string; title: string; content: Record<string, unknown> }[] = [];
  const notified: { user: string; rows: NotificationRow[] }[] = [];
  const s: NoteSource & { kept: typeof kept; notified: typeof notified } = {
    kept,
    notified,
    async read() {
      return { centreName: "Bright Minds Tuition", students };
    },
    async keep(_centre, student, artefact, key) {
      kept.push({ student, key, kind: artefact.kind, title: artefact.title, content: artefact.content });
      return `art-${kept.length}`;
    },
    async pushUsers() {
      return users;
    },
    async notify(_centre, user, rows) {
      notified.push({ user, rows });
    },
  };
  return s;
}
const job = (input: Record<string, unknown> = { class_id: CLASS, date: SUNDAY }): Job => ({ id: "job-1", centreId: CENTRE, kind: "note_day", attempts: 1, step: {}, input, leaseUntil: "" });
const ctx = (db = fakeDb(), claude = fakeClaude((r) => ({ answer: SAMPLE[kindOf(r)] }))): StepContext & { claude: ReturnType<typeof fakeClaude> } => {
  const clock = fakeClock(Date.parse("2026-10-11T10:30:00Z"));
  return { db, jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" };
};
async function drainAll(handler: ReturnType<typeof noteDay>, start: Job, c: StepContext) {
  const seen: StepOutcome[] = [];
  let current = start;
  for (let i = 0; i < 40; i++) {
    const outcome = await handler.step(current, c);
    seen.push(outcome);
    if (outcome.kind !== "continue") break;
    current = { ...current, step: outcome.step };
  }
  return seen;
}

test("the week ends on the note day and starts on its Monday, never more than seven days", () => {
  expect(weekEnding("2026-10-11")).toEqual({ from: "2026-10-05", to: "2026-10-11" });
  expect(weekEnding("2026-10-07")).toEqual({ from: "2026-10-05", to: "2026-10-07" });
  expect(weekEnding("2026-10-05")).toEqual({ from: "2026-09-29", to: "2026-10-05" });
});

test("each consented student's note is made and kept; the job says the notes are ready", async () => {
  const s = source([entry(DEV, "Dev Kumar"), entry(RIYA, "Riya Shah", { student: { id: RIYA, name: "Riya Shah", classLevel: "8", language: "hi" } })]);
  const c = ctx();
  const out = await drainAll(noteDay(s), job(), c);
  expect(out.map((o) => o.name)).toEqual(["read", `note:${DEV}`, `note:${RIYA}`, "notify"]);
  expect(s.kept.map((k) => [k.student, k.kind, k.key, k.title])).toEqual([
    [DEV, "note", `note:${DEV}:2026-10-05`, "Dev's week"],
    [RIYA, "note", `note:${RIYA}:2026-10-05`, "Riya's week"],
  ]);
  expect(s.kept[0]?.content).toMatchObject({ language: "en", week_monday: { year: 2026, month: 10, day: 5 }, generation_id: "gen-1" });
  expect(s.kept[0]?.content).not.toHaveProperty("english");
  expect(s.kept[1]?.content).toMatchObject({ language: "hi", english: expect.any(String) });
  expect((s.kept[0]?.content.facts as { label: string }[]).map((f) => f.label)).toEqual(["Taught", "Got right", "To practise", "Coming"]);
  const body = (c.db as ReturnType<typeof fakeDb>).started[0] as { input: { week: { monday: string; taught: string[] }; studentId: string } };
  expect(body.input).toMatchObject({ studentId: DEV, week: { monday: "2026-10-05", taught: ["Balancing equations"] } });
  expect(s.notified).toEqual([
    {
      user: "u1",
      rows: [
        {
          kind: "notes_ready",
          key: `notes_ready:${CLASS}:${SUNDAY}`,
          due_at: "2026-10-11T10:30:00.000Z",
          title: "2 weekly notes are ready",
          body: "For the note day. Read each as the parent will, then send.",
          link: "tutorcentral://today?note-day",
        },
      ],
    },
  ]);
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { made: 2, held: 0, kept: 0 } });
});

test("a student withdrawn mid-job is held, not paid", async () => {
  const db = fakeDb({ studentConsent: { [RIYA]: false } });
  const c = ctx(db);
  const out = await drainAll(noteDay(source([entry(DEV, "Dev"), entry(RIYA, "Riya")])), job(), c);
  expect(out.find((o) => o.name === `note:${RIYA}`)).toMatchObject({ kind: "continue", step: expect.objectContaining({ held: [RIYA] }) });
  expect(c.claude.requests).toHaveLength(1);
  expect(db.finished).toHaveLength(1);
  expect(out.at(-1)).toMatchObject({ result: { made: 1, held: 1 } });
});

test("a note already kept for the week is not made again", async () => {
  const c = ctx();
  const out = await drainAll(noteDay(source([entry(DEV, "Dev", { kept: true }), entry(RIYA, "Riya")])), job(), c);
  expect(c.claude.requests).toHaveLength(1);
  expect(out.at(-1)).toMatchObject({ result: { made: 1, kept: 1 } });
});

test("a one-student request makes that note and notifies no one", async () => {
  const s = source([entry(DEV, "Dev")]);
  const out = await drainAll(noteDay(s), job({ student_id: DEV, week: "2026-10-05" }), ctx());
  expect(s.kept).toHaveLength(1);
  expect(s.notified).toEqual([]);
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { made: 1 } });
});

test("a young student on the ladder gets can-now-do, kept as can_do", async () => {
  const young = entry(SAHIL, "Sahil Verma", {
    student: { id: SAHIL, name: "Sahil Verma", classLevel: "ukg", language: "kn" },
    record: { student: { id: SAHIL, name: "Sahil Verma", classLevel: "ukg" }, chapters: [ladder], skills: steps, checks: [], sessions: [], marks: [], items: [] },
  });
  const c = ctx();
  const s = source([young]);
  await drainAll(noteDay(s), job(), c);
  expect(kindOf(c.claude.requests[0] as never)).toBe("can_do");
  expect(s.kept[0]).toMatchObject({ kind: "can_do", title: "Sahil can now do", content: { language: "kn" } });
  expect((s.kept[0]?.content.facts as { label: string }[]).map((f) => f.label)).toEqual(["Can now do", "At home", "Next"]);
});

test("no note made: no notification", async () => {
  const s = source([entry(DEV, "Dev")]);
  await drainAll(noteDay(s), job(), ctx(fakeDb({ studentConsent: false })));
  expect(s.notified).toEqual([]);
});
