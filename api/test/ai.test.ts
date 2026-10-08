import { expect, test } from "bun:test";
import { fakeClaude, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

const centreId = "22222222-2222-2222-2222-222222222222";
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const verify = async (t: string) => (t === "good" ? { id: "u1" } : null);
const kindOf = (text: string) =>
  (text.includes("register") ? "scan_register" : text.includes("answer sheet") ? "check_paper" : text.includes("progress") ? "progress_note" : "paper") as keyof typeof SAMPLE;
const app = (claude = fakeClaude((r) => ({ answer: SAMPLE[kindOf(r.text)] })), db = fakeDb()) => makeApp({ verify, claude, db });
const post = (a: ReturnType<typeof makeApp>, path: string, body: unknown) =>
  a.request(path, { method: "POST", headers: auth, body: JSON.stringify(body) });
const paper = { kind: "paper", centreId, subject: "Mathematics", classLevel: "Class 10 Maths", topic: "Quadratic equations" };
const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString("base64");

test("generate starts the record, calls Claude with the paper prompt, finishes the row and answers the result", async () => {
  const claude = fakeClaude({ answer: SAMPLE.paper });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/generate", paper);
  expect(r.status).toBe(200);
  const body = (await r.json()) as { id: string; result: { title: string } };
  expect(body.id).toBe("gen-1");
  expect(body.result.title).toBe("Quadratic equations");
  expect(db.started[0]).toMatchObject({ token: "good", centre: centreId, kind: "paper", model: "claude-sonnet-5-5", input: { topic: "Quadratic equations" } });
  expect(db.finished[0]).toMatchObject({ id: "gen-1", status: "ok", tokensIn: 812, tokensOut: 1460 });
  expect(JSON.parse((db.finished[0] as { output: string }).output).title).toBe("Quadratic equations");
  expect(claude.requests[0]?.model).toBe("claude-sonnet-5-5");
});

test("a missing consent answers 403 in words, and the limit 429 with the limit", async () => {
  const noConsent = await post(app(undefined, fakeDb({ consent: false })), "/ai/scan-register", { centreId, imageBase64: jpeg, mediaType: "image/jpeg" });
  expect(noConsent.status).toBe(403);
  expect(await noConsent.json()).toEqual({ error: "Agree to the notice before the first photo.", reason: "consent" });
  const limited = await post(app(undefined, fakeDb({ limit: 0 })), "/ai/generate", paper);
  expect(limited.status).toBe(429);
  expect(await limited.json()).toEqual({ error: "You've made today's 0. Try again tomorrow.", limit: 0, kind: "paper" });
});

test("a refusal is 422, a failed service 502, and both finish the row as failed", async () => {
  const db = fakeDb();
  const refused = await post(app(fakeClaude({ refuse: true }), db), "/ai/generate", paper);
  expect(refused.status).toBe(422);
  expect(db.finished[0]).toMatchObject({ status: "failed", output: null });
  const down = await post(app(fakeClaude({ fail: "timeout" }), fakeDb()), "/ai/generate", paper);
  expect(down.status).toBe(502);
  expect(await down.json()).toEqual({ error: "The AI service didn't answer. Try again." });
});

test("scan-register checks the photo before any call and normalises the phones", async () => {
  const db = fakeDb();
  const bad = await post(app(undefined, db), "/ai/scan-register", { centreId, imageBase64: "AAAA", mediaType: "image/jpeg" });
  expect(bad.status).toBe(400);
  expect(db.started).toHaveLength(0);
  const r = await post(app(fakeClaude({ answer: SAMPLE.scan_register }), db), "/ai/scan-register", { centreId, imageBase64: jpeg, mediaType: "image/jpeg" });
  expect(r.status).toBe(200);
  const rows = ((await r.json()) as { result: { rows: { name: string; phone: string | null; fee: number | null }[] } }).result.rows;
  expect(rows[0]).toEqual({ name: "Aarav Mehta", phone: "+919876543210", fee: 1200 });
  expect(rows.find((x) => x.name === "Kavya Nair")?.phone).toBeNull();
  expect(db.started[0]).toMatchObject({ kind: "scan_register", input: { pages: 1, bytes: 8 } });
});

test("check-paper takes the scheme from a paper the centre made, or typed, and refuses a seventh page", async () => {
  const db = fakeDb({ generations: { "fbc6ae19-2769-4934-bf10-c830207fd6a3": { kind: "paper", output: JSON.stringify(SAMPLE.paper) } } });
  const claude = fakeClaude({ answer: SAMPLE.check_paper });
  const page = { imageBase64: jpeg, mediaType: "image/jpeg" };
  const scheme = { kind: "paper", generationId: "fbc6ae19-2769-4934-bf10-c830207fd6a3" };
  const r = await post(app(claude, db), "/ai/check-paper", { centreId, pages: [page, page], scheme, studentName: "Hemanth Reddy" });
  expect(r.status).toBe(200);
  expect(claude.requests[0]?.text).toContain("Quadratic equations");
  expect(claude.requests[0]?.images).toHaveLength(2);
  const gone = { kind: "paper", generationId: "00000000-0000-0000-0000-000000000000" };
  const unknown = await post(app(claude, db), "/ai/check-paper", { centreId, pages: [page], scheme: gone, studentName: "H" });
  expect(unknown.status).toBe(400);
  expect(await unknown.json()).toEqual({ error: "That paper is no longer here. Type the scheme instead." });
  const seven = await post(app(claude, db), "/ai/check-paper", { centreId, pages: Array(7).fill(page), scheme: { kind: "typed", text: "Q1 (1) b" }, studentName: "H" });
  expect(seven.status).toBe(400);
});

test("a body without a centre is refused before anything runs", async () => {
  const db = fakeDb();
  const r = await post(app(undefined, db), "/ai/generate", { ...paper, centreId: undefined });
  expect(r.status).toBe(400);
  expect(db.started).toHaveLength(0);
});

test("the record keeps the class's and the student's ids, so a result read back names them again", async () => {
  const db = fakeDb();
  const classId = "33333333-3333-3333-3333-333333333331";
  await post(app(fakeClaude({ answer: SAMPLE.paper }), db), "/ai/generate", { ...paper, classId });
  expect(db.started[0]).toMatchObject({ input: { classId } });
  const studentId = "aaaaaaaa-0000-0000-0000-000000000005";
  const note = {
    kind: "progress_note",
    centreId,
    subject: "Mathematics",
    classLevel: "Class 10 Maths",
    studentId,
    studentName: "Hemanth Reddy",
    observations: "Improving",
    tutorName: "Meera Nair",
    centreName: "Bright Minds Tuition",
  };
  await post(app(fakeClaude({ answer: SAMPLE.progress_note }), db), "/ai/generate", note);
  expect(db.started[1]).toMatchObject({ input: { studentId } });
});
