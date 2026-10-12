import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude, kindOf, localScript, SAMPLE } from "../src/claude-fake.js";
import { request as noteRequestForFake } from "../src/prompts/note.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";
import { fakeObserve } from "../src/observe-fake.js";
import { MessageOutput } from "../src/schemas.js";
import { applyModelOverrides, resetModelOverrides } from "../src/models.js";

const centreId = "22222222-2222-2222-2222-222222222222";
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const verify = async (t: string) => (t === "good" ? { id: "u1" } : null);
const app = (claude = fakeClaude((r) => ({ answer: SAMPLE[kindOf(r)] })), db = fakeDb()) => makeApp({ observe: fakeObserve(), verify, claude, db, apple: fakeApple({}) });
const post = (a: ReturnType<typeof makeApp>, path: string, body: unknown) => a.request(path, { method: "POST", headers: auth, body: JSON.stringify(body) });
const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString("base64");
const image = { imageBase64: jpeg, mediaType: "image/jpeg" };

test("parse-textbook reads a contents page into chapters and skills, records the class and subject, never the image", async () => {
  const claude = fakeClaude({ answer: SAMPLE.parse_textbook });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/parse-textbook", { centreId, image, classLevel: "5", subject: "Mathematics" });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { id: string; result: { title: string | null; chapters: { name: string; skills: string[] }[] } };
  expect(body.result.chapters[0]).toEqual({ name: "The Fish Tale", skills: ["Compare lengths and weights", "Read large numbers", "Use units of measure"] });
  expect(db.started[0]).toMatchObject({ kind: "parse_textbook", model: "claude-sonnet-5-5", input: { pages: 1, bytes: 8, classLevel: "5", subject: "Mathematics" } });
  expect(JSON.stringify(db.started[0])).not.toContain(jpeg);
  expect(claude.requests[0]?.images).toHaveLength(1);
  expect(claude.requests[0]?.text).toContain("contents page");
});

test("parse-textbook checks the photo first and says so when the chapters cannot be read", async () => {
  const db = fakeDb();
  const bad = await post(app(undefined, db), "/ai/parse-textbook", { centreId, image: { imageBase64: "AAAA", mediaType: "image/jpeg" }, classLevel: "5", subject: "Mathematics" });
  expect(bad.status).toBe(400);
  expect(db.started).toHaveLength(0);
  const refused = await post(app(fakeClaude({ refuse: true }), db), "/ai/parse-textbook", { centreId, image, classLevel: "5", subject: "Mathematics" });
  expect(refused.status).toBe(422);
  expect(await refused.json()).toEqual({ error: "Couldn't read the chapters from this photo. Try a flatter, brighter one." });
});

test("a page with no chapters on it is refused in words, never answered with an empty list", async () => {
  const db = fakeDb();
  const r = await post(app(fakeClaude({ answer: { title: null, chapters: [] } }), db), "/ai/parse-textbook", { centreId, image, classLevel: "5", subject: "Mathematics" });
  expect(r.status).toBe(422);
  expect(await r.json()).toEqual({ error: "Couldn't read the chapters from this photo. Try a flatter, brighter one." });
  expect(db.finished[0]).toMatchObject({ status: "failed" });
});

test("the monthly allowance is worded for the month on a V2 kind", async () => {
  const r = await post(app(undefined, fakeDb({ limit: 0 })), "/ai/parse-textbook", { centreId, image, classLevel: "5", subject: "Mathematics" });
  expect(r.status).toBe(429);
  expect(await r.json()).toEqual({ error: "You've made this month's 0. More next month.", limit: 0, kind: "parse_textbook" });
});

const check = { kind: "check", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation", "Name the reactants", "Tell a physical from a chemical change"] };

test("make check asks three questions, one per skill, on Haiku, with no student in the record", async () => {
  const claude = fakeClaude({ answer: SAMPLE.check });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", check);
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { questions: { skill: string; question: string; answer: string }[] } };
  expect(body.result.questions).toHaveLength(3);
  expect(body.result.questions.map((q) => q.skill)).toEqual(check.skills);
  expect(db.started[0]).toMatchObject({ kind: "check", model: "claude-haiku-5-5", input: { skills: check.skills, classLevel: "8" } });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
});

test("make check takes one to three skills", async () => {
  const one = await post(app(fakeClaude({ answer: { questions: [SAMPLE.check.questions[0]] } })), "/ai/make", { ...check, skills: ["Balance a chemical equation"] });
  expect(one.status).toBe(200);
  const four = await post(app(), "/ai/make", { ...check, skills: [...check.skills, "One more"] });
  expect(four.status).toBe(400);
});

test("make placement asks one question per chapter in the book's order", async () => {
  const claude = fakeClaude({ answer: SAMPLE.placement });
  const r = await post(app(claude), "/ai/make", { kind: "placement", centreId, classLevel: "5", subject: "Mathematics", chapters: ["The Fish Tale", "Shapes and Angles", "How Many Squares?"] });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { questions: { chapter: string; question: string; answer: string }[] } };
  expect(body.result.questions.map((q) => q.chapter)).toEqual(["The Fish Tale", "Shapes and Angles", "How Many Squares?"]);
  expect(claude.requests[0]?.model).toBe("claude-haiku-5-5");
});

test("a check, a placement and the mock need no student's consent", async () => {
  const db = fakeDb({ consent: false });
  expect((await post(app(undefined, db), "/ai/make", check)).status).toBe(200);
  const mock = await post(app(undefined, db), "/ai/make", { kind: "mock", centreId, classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"], pattern: { marks: 25, durationMinutes: 40 } });
  expect(mock.status).toBe(200);
  expect(db.started).toHaveLength(2);
});

// ---- Phase 12: /ai/plan and the four artefacts ----
const sheet = { kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation", "Name the reactants"], questions: 8 };

test("make sheet answers a question set on Sonnet for class 8 and Haiku for class 5, recording the skills and no student", async () => {
  const claude = fakeClaude({ answer: SAMPLE.sheet });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", sheet);
  expect(r.status).toBe(200);
  const body = (await r.json()) as { id: string; result: { title: string; questions: { number: number; text: string; answer: string }[] } };
  expect(body.result.questions).toHaveLength(8);
  expect(db.started[0]).toMatchObject({ kind: "sheet", model: "claude-sonnet-5-5", input: { skills: sheet.skills, forHomework: false } });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
  const young = await post(app(fakeClaude({ answer: SAMPLE.sheet }), db), "/ai/make", { ...sheet, classLevel: "5", forHomework: true, questions: 5 });
  expect(young.status).toBe(200);
  expect(db.started[1]).toMatchObject({ model: "claude-haiku-5-5" });
});

test("make sheet with a reason passes it to the prompt and records it", async () => {
  const claude = fakeClaude({ answer: SAMPLE.sheet });
  const db = fakeDb();
  await post(app(claude, db), "/ai/make", { ...sheet, reason: "easier" });
  expect(claude.requests[0]?.text).toContain("Make it easier");
  expect(db.started[0]).toMatchObject({ input: { reason: "easier" } });
});

test("make worked_example, figure and brief answer their shapes on Sonnet", async () => {
  const db = fakeDb();
  const example = await post(app(fakeClaude({ answer: SAMPLE.worked_example }), db), "/ai/make", { kind: "worked_example", centreId, classLevel: "8", subject: "Science", skill: "Balance a chemical equation" });
  expect(example.status).toBe(200);
  expect(((await example.json()) as { result: { steps: unknown[] } }).result.steps).toHaveLength(4);
  const figure = await post(app(fakeClaude({ answer: SAMPLE.figure }), db), "/ai/make", { kind: "figure", centreId, figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "Compare simple fractions" });
  expect(figure.status).toBe(200);
  expect(((await figure.json()) as { result: { figure: { kind: string } } }).result.figure.kind).toBe("fraction_bar");
  const brief = await post(app(fakeClaude({ answer: SAMPLE.brief }), db), "/ai/make", { kind: "brief", centreId, classLevel: "8", subject: "Science", chapter: "Chemical reactions" });
  expect(brief.status).toBe(200);
  expect(((await brief.json()) as { result: { mistakes: unknown[] } }).result.mistakes).toHaveLength(3);
  expect(db.started.map((s) => (s as { model: string }).model)).toEqual(["claude-sonnet-5-5", "claude-sonnet-5-5", "claude-sonnet-5-5"]);
});

test("a figure that fails its rule is refused in words and recorded as failed", async () => {
  const db = fakeDb();
  const r = await post(app(fakeClaude({ answer: { figure: { kind: "fraction_bar", parts: 4, shaded: 5, label: "5/4" }, caption: "x" } }), db), "/ai/make", { kind: "figure", centreId, figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "Compare simple fractions" });
  expect(r.status).toBe(422);
  expect(await r.json()).toEqual({ error: "Couldn't draw a figure for this skill. The plan goes on without it." });
  expect(db.finished[0]).toMatchObject({ status: "failed" });
});

test("plan names a first topic per group on Sonnet, with no student in the record", async () => {
  const claude = fakeClaude({ answer: SAMPLE.plan });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/plan", { centreId, classId: null, date: "2026-10-07", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] });
  expect(r.status).toBe(200);
  expect(((await r.json()) as { result: { groups: { groupNo: number; chapter: string; skill: string }[] } }).result.groups[0]?.groupNo).toBe(1);
  expect(db.started[0]).toMatchObject({ kind: "plan", model: "claude-sonnet-5-5" });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
});

test("no group make kind takes a student; the mock answers; a note in Phase 10's skeleton shape is a 400", async () => {
  const db = fakeDb({ consent: false });
  expect((await post(app(undefined, db), "/ai/make", sheet)).status).toBe(200);
  expect((await post(app(undefined, db), "/ai/make", { ...sheet, studentId: "11111111-1111-1111-1111-111111111111" })).status).toBe(400);
  expect((await post(app(undefined, db), "/ai/make", { kind: "mock", centreId, classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"], pattern: { marks: 25, durationMinutes: 40 } })).status).toBe(200);
  expect((await post(app(undefined, db), "/ai/make", { kind: "note", centreId, studentId: "11111111-1111-1111-1111-111111111111", studentName: "Dev", tutorName: "Meera", language: "en", week: { taught: [], right: [], practise: [], coming: [] } })).status).toBe(400);
});

const today = "2026-10-07";

test("parse-school reads a message into items on Sonnet, records no text of the message and no student, and never the image", async () => {
  const claude = fakeClaude({ answer: SAMPLE.parse_school });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/parse-school", { centreId, text: "Dear Parents, Science Unit Test 3 for Class 8 will be held on Friday 16th Oct.", today, schools: ["Vidya Niketan"], classLevels: ["8"] });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { items: { kind: string; date: string | null }[] } };
  expect(body.result.items.map((i) => i.kind)).toEqual(["exam", "homework", "holiday"]);
  expect(db.started[0]).toMatchObject({ kind: "parse_school", model: "claude-sonnet-5-5", input: { kind: "parse_school", source: "text", characters: 78, pages: 0 } });
  expect(JSON.stringify(db.started[0])).not.toContain("Dear Parents");
  const photo = await post(app(claude, db), "/ai/parse-school", { centreId, image, today });
  expect(photo.status).toBe(200);
  expect(db.started[1]).toMatchObject({ input: { source: "photo", pages: 1, bytes: 8 } });
  expect(JSON.stringify(db.started[1])).not.toContain(jpeg);
});

test("parse-school answers a null date when the message gives none, and refuses a message with nothing in it", async () => {
  const undated = await post(app(fakeClaude({ answer: { items: [{ kind: "exam", title: "Unit test", subject: "Science", date: null, endDate: null, classLevel: null, school: null, studentName: null, portions: null }] } })), "/ai/parse-school", { centreId, text: "Unit test next week", today });
  expect(((await undated.json()) as { result: { items: { date: null }[] } }).result.items[0]?.date).toBeNull();
  const db = fakeDb();
  const none = await post(app(fakeClaude({ answer: { items: [] } }), db), "/ai/parse-school", { centreId, text: "Good morning", today });
  expect(none.status).toBe(422);
  expect(await none.json()).toEqual({ error: "Couldn't find a test, homework, notice or holiday in this. Add it by hand." });
  expect(db.finished[0]).toMatchObject({ status: "failed" });
});

const mock = { kind: "mock", centreId, classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions", "Acids, bases and salts"], pattern: { marks: 25, durationMinutes: 40 } };

test("make mock answers the paper on Sonnet with no student, and refuses one whose marks do not sum to the pattern", async () => {
  const db = fakeDb();
  const ok = await post(app(fakeClaude({ answer: SAMPLE.mock }), db), "/ai/make", mock);
  expect(ok.status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "mock", model: "claude-sonnet-5-5", input: { title: "Science unit test 3" } });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
  const short = { ...SAMPLE.mock, sections: [SAMPLE.mock.sections[0]] };
  const unfit = await post(app(fakeClaude({ answer: short }), db), "/ai/make", mock);
  expect(unfit.status).toBe(422);
  expect(await unfit.json()).toEqual({ error: "Couldn't set a mock for these portions. The plan goes on without it." });
  expect(db.finished[1]).toMatchObject({ status: "failed" });
});

test("make gap_report and test_tomorrow are personal: the student's consent is asked and recorded, and a refusal is 403", async () => {
  const report = { kind: "gap_report", centreId, studentId: centreId, classLevel: "8", subject: "Science", daysLeft: 2, bySkill: [{ skill: "Balancing equations", right: 3, of: 10 }] };
  const db = fakeDb();
  expect((await post(app(fakeClaude({ answer: SAMPLE.gap_report }), db), "/ai/make", report)).status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "gap_report", student: centreId, model: "claude-sonnet-5-5" });
  const refused = await post(app(undefined, fakeDb({ studentConsent: false })), "/ai/make", report);
  expect(refused.status).toBe(403);
  expect(((await refused.json()) as { reason: string }).reason).toBe("student_consent");
  const message = { kind: "test_tomorrow", centreId, studentId: centreId, studentName: "Dev Kumar", tutorName: "Meera Nair", centreName: "Bright Minds Tuition", parentName: "Ramesh Kumar", language: "hi", subject: "Science", title: "Science unit test", date: "2026-10-08", portions: "chapters 1 and 2" };
  const sent = await post(app(fakeClaude({ answer: SAMPLE.test_tomorrow }), db), "/ai/make", message);
  expect(sent.status).toBe(200);
  expect(((await sent.json()) as { result: { english: string } }).result.english).toContain("Dev");
  expect(db.started[1]).toMatchObject({ kind: "test_tomorrow", student: centreId, model: "claude-haiku-5-5" });
});

test("AI_MODEL_TEST_TOMORROW reaches the next call and its record (D67)", async () => {
  applyModelOverrides({ AI_MODEL_TEST_TOMORROW: "claude-opus-5-5" });
  try {
    const claude = fakeClaude({ answer: SAMPLE.test_tomorrow });
    const db = fakeDb();
    const message = { kind: "test_tomorrow", centreId, studentId: centreId, studentName: "Dev Kumar", tutorName: "Meera Nair", centreName: "Bright Minds Tuition", parentName: "Ramesh Kumar", language: "hi", subject: "Science", title: "Science unit test", date: "2026-10-08", portions: "chapters 1 and 2" };
    const r = await post(app(claude, db), "/ai/make", message);
    expect(r.status).toBe(200);
    expect(claude.requests[0]?.model).toBe("claude-opus-5-5");
    expect(db.started[0]).toMatchObject({ kind: "test_tomorrow", model: "claude-opus-5-5" });
  } finally {
    resetModelOverrides();
  }
});

// ---- Phase 14: the parents' messages and marks from a photo ----
const student = { studentId: "77777777-7777-7777-7777-777777777777", studentName: "Dev Kumar", tutorName: "Meera Nair", parentName: "Ramesh Kumar", centreName: "Bright Minds Tuition", classLevel: "8" };
const week = { monday: "2026-10-05", taught: ["Balancing equations", "Types of reactions"], right: "8 of 12 checks · all of Section A on the mock", practise: ["The numbers in front of a formula"], coming: ["Acids, bases and salts", "the unit test on Fri 16 Oct"], attendance: "absent 2 of 3 classes" };
const testTomorrowBody = { kind: "test_tomorrow", centreId, studentId: centreId, studentName: "Dev Kumar", tutorName: "Meera Nair", centreName: "Bright Minds Tuition", parentName: "Ramesh Kumar", language: "hi", subject: "Science", title: "Science unit test", date: "2026-10-08", portions: "chapters 1 and 2" };

test("make note writes the week's note in the parent's language with the English beside it, on Haiku, with the student's consent", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { message: string; english: string } };
  expect(body.result.message).toMatch(/^नमस्ते/);
  expect(body.result.english).toContain("Dev learnt to balance chemical equations");
  expect(db.started[0]).toMatchObject({ kind: "note", model: "claude-haiku-5-5", student: student.studentId });
  expect(claude.requests[0]?.text).toContain("Taught: Balancing equations, Types of reactions.");
  expect(claude.requests[0]?.text).toContain("Attendance: absent 2 of 3 classes.");
  expect(claude.requests[0]?.system).not.toContain("signed");
});

test("a note for a student whose parent has not agreed is refused before any call, in the student's words", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  const r = await post(app(claude, fakeDb({ studentConsent: false })), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week });
  expect(r.status).toBe(403);
  expect(await r.json()).toEqual({ error: "Dev's parent hasn't agreed yet.", reason: "student_consent" });
  expect(claude.requests).toHaveLength(0);
});

test("a note with no taught skills says nothing new (decision 2), asks for no taught line and keeps the attendance", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  await post(app(claude, fakeDb()), "/ai/make", { kind: "note", centreId, ...student, language: "en", week: { ...week, taught: [], right: undefined, attendance: "absent all week (3 classes)" } });
  const text = claude.requests[0]?.text ?? "";
  expect(text).toContain("Taught: nothing new this week.");
  expect(text).not.toContain("what was taught");
  expect(text).not.toContain("Got right:");
  expect(text).toContain("Attendance: absent all week (3 classes).");
  expect(claude.requests[0]?.system).toContain("leave out");
});

test("make can_do writes from the ladder, naming what moved up, what the student can do, what to do at home and what is next", async () => {
  const claude = fakeClaude({ answer: SAMPLE.can_do });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", {
    kind: "can_do", centreId, ...student, studentName: "Sahil Verma", parentName: "Deepak Verma", classLevel: "2", language: "kn",
    ladder: { movedUp: [{ area: "reading", step: "Sentences" }], canDo: ["Read short sentences", "Count to 99"], atHome: "One page a day from the picture book", next: ["Writing words", "Adding to 20"] },
  });
  expect(r.status).toBe(200);
  expect(((await r.json()) as { result: { message: string } }).result.message).toMatch(/^ನಮಸ್ಕಾರ/);
  expect(db.started[0]).toMatchObject({ kind: "can_do", model: "claude-haiku-5-5" });
  expect(claude.requests[0]?.text).toContain("Moved up this week: reading to Sentences.");
});

test("make not_on_track writes what is hard, what we are doing and what helps at home, and asks for a talk", async () => {
  const claude = fakeClaude({ answer: SAMPLE.not_on_track });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", {
    kind: "not_on_track", centreId, ...student, language: "hi",
    hard: ["Balancing equations"], reasons: ["3 of 10 on the mock", "absent twice in four weeks"], doing: "the worked example in the next class", atHome: "ten minutes of practice each evening",
  });
  expect(r.status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "not_on_track", model: "claude-haiku-5-5", student: student.studentId });
  expect(claude.requests[0]?.system).toContain("five minutes");
});

test("the three message kinds hold the model to 500 characters and the schema to 600, with no signature", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  await post(app(claude, fakeDb()), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week });
  expect(claude.requests[0]?.system).toContain("at most 500 characters");
  expect(claude.requests[0]?.system).toContain("no signature");
  expect(MessageOutput.safeParse({ message: "x".repeat(601), english: "y" }).success).toBe(false);
});

test("read-marks reads a report card into rows the tutor checks, records the pages and never the image, with the student's consent", async () => {
  const claude = fakeClaude({ answer: SAMPLE.read_marks });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth Reddy", pages: [image], subjects: ["Mathematics", "Science"] });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { marks: { subject: string; test: string; date: string | null; score: number; max: number }[] } };
  expect(body.result.marks[0]).toEqual({ subject: "Mathematics", test: "Unit test 2", date: "2026-09-28", score: 14, max: 25 });
  expect(body.result.marks[2]?.date).toBeNull();
  expect(db.started[0]).toMatchObject({ kind: "read_marks", model: "claude-sonnet-5-5", student: student.studentId, input: { pages: 1, bytes: 8 } });
  expect(JSON.stringify(db.started[0])).not.toContain(jpeg);
  expect(claude.requests[0]?.system).toContain("report card");
  expect(claude.requests[0]?.text).toContain("Subjects the student takes here: Mathematics, Science.");
});

test("read-marks refuses a photo with no marks in words, and a student without consent before any call", async () => {
  const none = await post(app(fakeClaude({ answer: { marks: [] } }), fakeDb()), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth", pages: [image] });
  expect(none.status).toBe(422);
  expect(await none.json()).toEqual({ error: "Couldn't read any marks from this photo. Try a flatter, brighter one." });
  const claude = fakeClaude({ answer: SAMPLE.read_marks });
  const refused = await post(app(claude, fakeDb({ studentConsent: false })), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth", pages: [image] });
  expect(refused.status).toBe(403);
  expect(claude.requests).toHaveLength(0);
  const three = await post(app(undefined, fakeDb()), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth", pages: [image, image, image] });
  expect(three.status).toBe(400);
});

test("test tomorrow no longer asks the model to sign (the app signs each message once)", async () => {
  const claude = fakeClaude({ answer: SAMPLE.test_tomorrow });
  await post(app(claude, fakeDb()), "/ai/make", testTomorrowBody);
  expect(claude.requests[0]?.system).toContain("no signature");
  expect(claude.requests[0]?.text).not.toContain("Signed:");
});

test("an unfit message is refused in words about the message, never about a topic, and the English's limit is asked", async () => {
  const long = { message: "नमस्ते", english: "a".repeat(1001) };
  for (const kind of ["note", "can_do", "not_on_track"] as const) {
    const claude = fakeClaude({ answer: long });
    const body =
      kind === "note"
        ? { kind, centreId, ...student, language: "hi", week }
        : kind === "can_do"
          ? { kind, centreId, ...student, classLevel: "2", language: "kn", ladder: { movedUp: [], canDo: ["Read short sentences"], atHome: "One page a day", next: ["Paragraphs"] } }
          : { kind, centreId, ...student, language: "hi", hard: ["Balancing equations"], reasons: ["3 of 10 on the mock"], doing: "the worked example in the next class", atHome: "five equations a day" };
    const r = await post(app(claude, fakeDb()), "/ai/make", body);
    expect({ kind, status: r.status }).toEqual({ kind, status: 422 });
    expect(await r.json()).toEqual({ error: "Couldn't write this message. Try again." });
    expect(claude.requests[0]?.system).toContain("the English at most 700 characters");
  }
});

test("a body the schema refuses is a 400 marked invalid, so the app never shows the schema's words", async () => {
  const r = await post(app(), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week: { ...week, right: "x".repeat(121) } });
  expect(r.status).toBe(400);
  expect(((await r.json()) as { reason?: string }).reason).toBe("invalid");
});

// ---- Phase 15: the note from Make with the tutor's own words ----
test("a note with tutorSays reaches the model and is recorded with it", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week, tutorSays: "Ask him to read aloud." });
  expect(r.status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "note", input: { tutorSays: "Ask him to read aloud." } });
  expect(claude.requests[0]?.text).toContain('The tutor adds: "Ask him to read aloud."');
});

test("the local fake ends its note with the tutor's words, so a hand run shows them", () => {
  const r = noteRequestForFake({ kind: "note", centreId, ...student, classLevel: "8", language: "hi", week, tutorSays: "Ask him to read aloud." });
  const made = localScript(r).answer as { message: string; english: string };
  expect(made.english.endsWith("Ask him to read aloud.")).toBe(true);
});
