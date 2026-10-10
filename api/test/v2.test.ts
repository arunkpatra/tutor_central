import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude, kindOf, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

const centreId = "22222222-2222-2222-2222-222222222222";
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const verify = async (t: string) => (t === "good" ? { id: "u1" } : null);
const app = (claude = fakeClaude((r) => ({ answer: SAMPLE[kindOf(r)] })), db = fakeDb()) => makeApp({ verify, claude, db, apple: fakeApple({}) });
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

test("a check and a placement need no student's consent; the other kinds still answer 501", async () => {
  const db = fakeDb({ consent: false });
  expect((await post(app(undefined, db), "/ai/make", check)).status).toBe(200);
  const sheet = await post(app(undefined, db), "/ai/make", { kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"] });
  expect(sheet.status).toBe(501);
  expect(db.started).toHaveLength(1);
});
