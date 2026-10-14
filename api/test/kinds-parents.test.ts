import { expect, test } from "bun:test";
import { runAgent } from "../src/agents/agent.js";
import { canDo, note, notOnTrack, testTomorrow } from "../src/agents/kinds/index.js";
import { messageFindings, scriptShare } from "../src/agents/kinds/message.js";
import { fakeClaude, localScript } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { request as noteRequest } from "../src/prompts/note.js";
import { request as testTomorrowRequest } from "../src/prompts/test-tomorrow.js";
import { systemText as systemTextOf } from "../src/claude-fake.js";
import { MakeInput, type WeeklyNoteInput } from "../src/schemas.js";

// Phase 21 (D107, D110): the parents' four kinds on their agents, with the message rules every one shares: the parent's
// script, the facts' numbers, no sign-off, the tutor's own words carried whole; the planted test of an invented fact.
const centreId = "22222222-2222-2222-2222-222222222222";
const studentId = "a0000000-0000-4000-8000-000000000001";
const quick = (script?: string) => fakeClaude((r) => ({ ...localScript(r, script), delayMs: 0 }));
const ctx = (db = fakeDb(), claude = quick()) => ({ db, claude, token: "t", requestId: "r", centre: centreId, key: "k", inputHash: "h" });
const facts = ["Taught: balancing equations, types of reactions", "Got right: 8 of 12 checks", "To practise: the numbers in front of a formula"];
const who = { language: "hi" as const, studentName: "Dev Kumar", parentName: "Ramesh Kumar", facts };
const noteInput = (over: Partial<WeeklyNoteInput> = {}) =>
  MakeInput.parse({
    centreId, kind: "note", studentId, studentName: "Dev Kumar", parentName: "Ramesh Kumar", centreName: "Bright Minds Tuition", language: "en", classLevel: "8",
    week: { monday: "2026-10-05", taught: ["Balancing equations"], right: "8 of 12 checks", practise: ["The numbers in front of a formula"], coming: [] },
    ...over,
  }) as WeeklyNoteInput;

test("a number the facts do not hold is a finding; a number written in words counts as the facts' number", () => {
  expect(messageFindings(who, { message: "देव ने 12 में से 8 सवाल सही किए।", english: "Dev got 8 of 12 right." })).toEqual([]);
  expect(messageFindings(who, { message: "देव ने 12 में से 9 सवाल सही किए।", english: "Dev got 9 of 12 right." }).map((f) => f.problem)).toEqual(["9 is not in the facts"]);
  expect(messageFindings({ ...who, language: "en" }, { message: "Dev got eight of twelve right.", english: "Dev got eight of twelve right." })).toEqual([]);
  // Devanagari and Kannada digits are the facts' numbers too.
  expect(messageFindings(who, { message: "देव ने १२ में से ८ सवाल सही किए।", english: "Dev got 8 of 12 right." })).toEqual([]);
  expect(messageFindings({ ...who, language: "kn" }, { message: "ದೇವ್ ೧೨ ರಲ್ಲಿ ೯ ಸರಿ ಮಾಡಿದ್ದಾನೆ.", english: "Dev got 9 of 12 right." }).map((f) => f.problem)).toEqual(["9 is not in the facts"]);
});

test("the message is in the parent's script; the English is English", () => {
  expect(messageFindings(who, { message: "Dev did well this week.", english: "Dev did well this week." }).map((f) => f.item)).toEqual(["script"]);
  expect(messageFindings({ ...who, language: "kn" }, { message: "ದೇವ್ ಈ ವಾರ ಚೆನ್ನಾಗಿ ಮಾಡಿದ್ದಾನೆ.", english: "Dev did well this week." })).toEqual([]);
  expect(messageFindings({ ...who, language: "hinglish" }, { message: "Dev ne is hafte accha kiya.", english: "Dev did well this week." })).toEqual([]);
  expect(messageFindings(who, { message: "देव ने अच्छा किया।", english: "देव ने अच्छा किया।" }).map((f) => f.item)).toEqual(["english"]);
  expect(scriptShare("देव ने Science में अच्छा किया।", "hi")).toBeGreaterThan(0.6);
});

test("a sign-off is a finding; the tutor's own words are carried whole", () => {
  expect(messageFindings({ ...who, language: "en" }, { message: "Dev did well. Regards, Meera", english: "Dev did well. Regards, Meera" }).map((f) => f.item)).toEqual(["sign-off"]);
  expect(messageFindings(who, { message: "देव ने अच्छा किया। सादर, मीरा", english: "Dev did well. Regards, Meera" }).map((f) => f.item)).toEqual(["sign-off"]);
  expect(messageFindings({ ...who, language: "en" }, { message: "Dev did well. Thank you.", english: "Dev did well. Thank you." })).toEqual([]);
  const says = "Please send the fee by Friday";
  expect(messageFindings({ ...who, language: "en", tutorSays: says }, { message: `Dev did well. ${says}.`, english: `Dev did well. ${says}.` })).toEqual([]);
  expect(messageFindings({ ...who, language: "en", tutorSays: says }, { message: "Dev did well. Send the fee.", english: "Dev did well. Send the fee." }).map((f) => f.item)).toEqual(["the tutor's words"]);
});

test("a note naming a fact not in the record is refused after a repair (the planted test)", async () => {
  const db = fakeDb();
  const out = await runAgent(ctx(db, quick("invented-fact")), note, noteInput());
  expect(out).toMatchObject({ kind: "failed", words: "refused" });
  expect(out.kind === "failed" && out.reason).toBe("check:numbers");
  expect(db.rows.map((r) => r.agentStep)).toEqual(["draft", "check", "repair", "check"]);
});

test("the four kinds keep the fake's known-good answer without a repair, and name the student for consent", async () => {
  const bodies = [
    [note, noteInput()],
    [note, noteInput({ language: "hi" })],
    [canDo, MakeInput.parse({ centreId, kind: "can_do", studentId, studentName: "Riya Sharma", parentName: "Neha Sharma", centreName: "Bright Minds Tuition", language: "kn", classLevel: "1", ladder: { movedUp: [{ area: "reading", step: "Words" }], canDo: ["Read three-letter words"], atHome: "Read one short word card a day", next: ["Read short sentences"] } })],
    [testTomorrow, MakeInput.parse({ centreId, kind: "test_tomorrow", studentId, studentName: "Dev Kumar", parentName: "Ramesh Kumar", centreName: "Bright Minds Tuition", language: "hinglish", classLevel: "8", subject: "Science", title: "Science unit test 3", date: "2026-10-16", portions: "Chapters 1 and 2" })],
    [notOnTrack, MakeInput.parse({ centreId, kind: "not_on_track", studentId, studentName: "Ishaan Bose", parentName: "Rina Bose", centreName: "Bright Minds Tuition", language: "hi", classLevel: "6", hard: ["Fractions"], reasons: ["Half the checks wrong in two weeks"], doing: "One step at a time with a worked example", atHome: "Five minutes of fractions each evening" })],
  ] as const;
  for (const [spec, input] of bodies) {
    const db = fakeDb();
    // biome-ignore lint/suspicious/noExplicitAny: each kind takes its own input.
    const out = await runAgent(ctx(db), spec as any, input);
    expect({ kind: spec.kind, language: (input as { language: string }).language, outcome: out.kind, steps: db.rows.map((r) => r.agentStep) }).toEqual({ kind: spec.kind, language: (input as { language: string }).language, outcome: "ok", steps: ["draft", "check"] });
    expect(spec.student?.(input as never)?.id).toBe(studentId);
  }
});

test("the reason of a Write again is in the request and never in the message's rubric as a fact", () => {
  const r = noteRequest(noteInput({ reason: "Less about marks" }));
  expect(r.system.own).toContain("The tutor asked for a change: Less about marks. Do that and keep the facts.");
  expect(note.rubric).toContain("A change the tutor asked for with Write again is an instruction to the writer, never a sentence of the message");
  expect(note.rubric).toContain("Every number in the message is one the request gives");
  // The not-on-track message's facts ("Why: …") are not Write again's reason (the evals' not-kn-home): the line is the note's alone.
  expect(notOnTrack.rubric).not.toContain("Write again");
  // Warm words are no fact (the evals' not-hinglish-home): the rubric names facts, not promises.
  expect(notOnTrack.rubric).not.toContain("promise");
});

test("the English beside a message is its translation; Hindi and Kannada write the topics and the names in their own script (the evals)", () => {
  const words = systemTextOf(noteRequest(noteInput({ language: "hi" })));
  expect(words).toContain("The English is the message translated sentence for sentence: it adds nothing and leaves nothing out.");
  expect(words).toContain("In Hindi or Kannada, write everything in that script");
  expect(words).toContain("every person's name, the student's and the parent's alike");
});

test("test tomorrow asks for one thing to go over only when the facts give one (Phase 14's rule; the evals' tt-kn-no-portions)", () => {
  const base = { centreId, kind: "test_tomorrow", studentId, studentName: "Riya Sharma", centreName: "Bright Minds Tuition", language: "kn", classLevel: "5", subject: "Mathematics", title: "Maths class test", date: "2026-10-21" } as const;
  expect(systemTextOf(testTomorrowRequest(MakeInput.parse(base) as never))).not.toContain("one thing to go over");
  expect(systemTextOf(testTomorrowRequest(MakeInput.parse({ ...base, revise: "Fractions" }) as never))).toContain("one thing to go over this evening");
});
