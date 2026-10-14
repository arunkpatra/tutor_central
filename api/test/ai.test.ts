import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude, localAnswer, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";
import { fakeObserve } from "../src/observe-fake.js";
import { applyModelOverrides, resetModelOverrides } from "../src/models.js";
import { makeVerify } from "../src/verify.js";

const centreId = "22222222-2222-2222-2222-222222222222";
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const verify = async (t: string) => (t === "good" ? { id: "u1" } : null);
const kindOf = (text: string) =>
  (text.includes("register") ? "scan_register" : text.includes("answer sheet") ? "check_paper" : text.includes("progress") ? "progress_note" : "paper") as keyof typeof SAMPLE;
const app = (claude = fakeClaude((r) => ({ answer: SAMPLE[kindOf(r.text)] })), db = fakeDb()) => makeApp({ observe: fakeObserve(), verify, claude, db, apple: fakeApple({}) });
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

const image = { imageBase64: jpeg, mediaType: "image/jpeg" };

test("check-paper marks against a mock's key read from its generation, names the student for the gate, and needs their consent", async () => {
  const generations = { "11111111-1111-1111-1111-111111111111": { kind: "mock" as const, output: JSON.stringify(SAMPLE.mock) } };
  const db = fakeDb({ generations });
  const body = { centreId, pages: [image], scheme: { kind: "mock", generationId: "11111111-1111-1111-1111-111111111111" }, studentName: "Dev Kumar", studentId: centreId };
  // The fake's marking fitted to the mock's scheme: on its agent (Phase 21) every scheme question is marked once.
  const claude = fakeClaude((r) => ({ answer: localAnswer(r) }));
  const r = await post(app(claude, db), "/ai/check-paper", body);
  expect(r.status).toBe(200);
  expect(claude.requests[0]?.text).toContain("Section A");
  expect(db.started[0]).toMatchObject({ kind: "check_paper", student: centreId, input: { scheme: { kind: "mock", generationId: "11111111-1111-1111-1111-111111111111" } } });
  const refused = await post(app(claude, fakeDb({ generations, studentConsent: false })), "/ai/check-paper", body);
  expect(refused.status).toBe(403);
  const gone = await post(app(claude, fakeDb()), "/ai/check-paper", body);
  expect(gone.status).toBe(400);
  expect(await gone.json()).toEqual({ error: "That mock is no longer here. Type the scheme instead." });
});

test("the verifier tells a 4xx (sign in again) from a network failure or a 5xx (unreachable) (D68)", async () => {
  const answering = (answer: unknown) => makeVerify(() => ({ auth: { getUser: async () => answer } }) as never);
  expect(await answering({ data: { user: null }, error: { status: 401, message: "expired" } })("t")).toBeNull();
  expect(await answering({ data: { user: null }, error: { status: 403, message: "bad jwt" } })("t")).toBeNull();
  expect(await answering({ data: { user: null }, error: { status: 502, message: "bad gateway" } })("t")).toBe("unreachable");
  expect(await answering({ data: { user: null }, error: { message: "fetch failed" } })("t")).toBe("unreachable");
  const failed = makeVerify(() => ({ auth: { getUser: async () => { throw new TypeError("fetch failed"); } } }) as never);
  expect(await failed("t")).toBe("unreachable");
  expect(await answering({ data: { user: { id: "u1" } }, error: null })("t")).toEqual({ id: "u1" });
});

test("a rate limit, a timeout or a proxy's page is not the token's fault: unreachable, never 'sign in again' (D68)", async () => {
  const answering = (answer: unknown) => makeVerify(() => ({ auth: { getUser: async () => answer } }) as never);
  expect(await answering({ data: { user: null }, error: { status: 429, message: "rate limited" } })("t")).toBe("unreachable");
  expect(await answering({ data: { user: null }, error: { status: 408, message: "timeout" } })("t")).toBe("unreachable");
  // supabase-js wraps a non-JSON body (a proxy's HTML 4xx) as AuthRetryableFetchError with that status.
  const proxy = { status: 404, message: "Not Found", name: "AuthRetryableFetchError" };
  expect(await answering({ data: { user: null }, error: proxy })("t")).toBe("unreachable");
});

test("a named student's missing consent answers in the student's words, the centre's missing consent in the centre's (D68)", async () => {
  const MOCK_ID = "11111111-1111-1111-1111-111111111111";
  const generations = { [MOCK_ID]: { kind: "mock" as const, output: JSON.stringify(SAMPLE.mock) } };
  const body = { centreId, pages: [image], scheme: { kind: "mock", generationId: MOCK_ID }, studentName: "Diya Pillai", studentId: "77777777-7777-7777-7777-777777777777" };
  const r = await post(app(undefined, fakeDb({ studentConsent: false, generations })), "/ai/check-paper", body);
  expect(r.status).toBe(403);
  expect(await r.json()).toEqual({ error: "Diya's parent hasn't agreed yet.", reason: "student_consent" });
  const centre = await post(app(undefined, fakeDb({ consent: false })), "/ai/scan-register", { centreId, ...image });
  expect(await centre.json()).toEqual({ error: "Agree to the notice before the first photo.", reason: "consent" });
});

test("check-paper's model comes from the table, not a constant (D67)", async () => {
  applyModelOverrides({ AI_MODEL_CHECK_PAPER: "claude-sonnet-5-5" });
  try {
    const claude = fakeClaude({ answer: SAMPLE.check_paper });
    const db = fakeDb();
    const r = await post(app(claude, db), "/ai/check-paper", { centreId, pages: [image], scheme: { kind: "typed", text: "Q1 2 marks" }, studentName: "Dev" });
    expect(r.status).toBe(200);
    expect(claude.requests[0]?.model).toBe("claude-sonnet-5-5");
    expect(db.started[0]).toMatchObject({ kind: "check_paper", model: "claude-sonnet-5-5" });
  } finally {
    resetModelOverrides();
  }
});

test("a V1 progress note names its student for the gate and waits for their parent's consent (D62, the review's R-web-3)", async () => {
  const studentId = "aaaaaaaa-0000-0000-0000-000000000005";
  const note = {
    kind: "progress_note", centreId, subject: "Mathematics", classLevel: "Class 10 Maths", studentId,
    studentName: "Hemanth Reddy", observations: "Improving", tutorName: "Meera Nair", centreName: "Bright Minds Tuition",
  };
  const db = fakeDb();
  const r = await post(app(fakeClaude({ answer: SAMPLE.progress_note }), db), "/ai/generate", note);
  expect(r.status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "progress_note", student: studentId });
  const claude = fakeClaude({ answer: SAMPLE.progress_note });
  const refused = await post(app(claude, fakeDb({ studentConsent: false })), "/ai/generate", note);
  expect(refused.status).toBe(403);
  expect(claude.requests).toHaveLength(0);
});

const keyed = (a: ReturnType<typeof makeApp>, key: string | null, body: unknown = paper, requestId?: string) =>
  a.request("/ai/generate", {
    method: "POST",
    headers: { ...auth, ...(key ? { "idempotency-key": key } : {}), ...(requestId ? { "x-request-id": requestId } : {}) },
    body: JSON.stringify(body),
  });

test("the key and request id reach start, and the row is finished with cost, latency, hash and stop reason", async () => {
  const db = fakeDb();
  const requestId = "0f9a1b2c-3d4e-4f5a-8b6c-7d8e9f0a1b2c";
  const r = await keyed(app(fakeClaude({ answer: SAMPLE.paper }), db), "k", paper, requestId);
  expect(r.status).toBe(200);
  expect(r.headers.get("idempotent-replayed")).toBeNull();
  expect(db.started[0]).toMatchObject({ key: "k", requestId });
  expect((db.started[0] as { inputHash: string }).inputHash).toMatch(/^[0-9a-f]{64}$/);
  expect(db.finished[0]).toMatchObject({ status: "ok", costPaise: 138, stopReason: "end_turn", errorReason: null });
  expect((db.finished[0] as { promptHash: string }).promptHash).toMatch(/^[0-9a-f]{64}$/);
  expect((db.finished[0] as { latencyMs: number }).latencyMs).toBeGreaterThanOrEqual(0);
  expect((db.finished[0] as { finishedAt: string }).finishedAt).toBeString();
});

test("a replayed key answers the stored result with the header and no call", async () => {
  const claude = fakeClaude({ answer: SAMPLE.paper });
  const db = fakeDb({ replays: { k: { id: "gen-old", status: "ok", output: JSON.stringify(SAMPLE.paper) } } });
  const r = await keyed(app(claude, db), "k");
  expect(r.status).toBe(200);
  expect(r.headers.get("idempotent-replayed")).toBe("true");
  expect(await r.json()).toEqual({ id: "gen-old", result: SAMPLE.paper });
  expect(claude.requests).toHaveLength(0);
  expect(db.finished).toHaveLength(0);
});

test("a pending key answers 409 in_progress, in the app's timed-out words", async () => {
  const claude = fakeClaude({ answer: SAMPLE.paper });
  const r = await keyed(app(claude, fakeDb({ replays: { k: { id: "gen-old", status: "pending", output: null } } })), "k");
  expect(r.status).toBe(409);
  expect(await r.json()).toEqual({ error: "That took too long to come back. Try again in a minute.", reason: "in_progress" });
  expect(claude.requests).toHaveLength(0);
});

test("a reused key with another body is 409 key_reused, nothing paid", async () => {
  const claude = fakeClaude({ answer: SAMPLE.paper });
  const r = await keyed(app(claude, fakeDb({ keyReused: ["k"] })), "k");
  expect(r.status).toBe(409);
  expect(await r.json()).toEqual({ error: "The AI service didn't answer. Try again.", reason: "key_reused" });
  expect(claude.requests).toHaveLength(0);
});

test("a call without a key gets a fresh one and is never replayed; a key past 160 characters is not used", async () => {
  const db = fakeDb();
  const a = app(fakeClaude({ answer: SAMPLE.paper }), db);
  expect((await keyed(a, null)).status).toBe(200);
  expect((await keyed(a, "x".repeat(161))).status).toBe(200);
  const keys = db.started.map((s) => (s as { key: string }).key);
  expect(keys.every((k) => /^call:[0-9a-f-]{36}$/.test(k))).toBe(true);
  expect(new Set(keys).size).toBe(2);
  expect(db.finished).toHaveLength(2);
});

test("a truncated answer is 502 in the service's words and the row says truncated with its tokens", async () => {
  const db = fakeDb();
  const r = await keyed(app(fakeClaude({ truncate: true }), db), "k");
  expect(r.status).toBe(502);
  expect(await r.json()).toEqual({ error: "The AI service didn't answer. Try again." });
  expect(db.finished[0]).toMatchObject({ status: "failed", errorReason: "truncated", tokensIn: 812, tokensOut: 16000, stopReason: "max_tokens" });
});

test("a refused answer records its tokens and its reason; a failed one its reason with no tokens", async () => {
  const db = fakeDb();
  await keyed(app(fakeClaude({ refuse: true }), db), "k");
  expect(db.finished[0]).toMatchObject({ status: "failed", errorReason: "refused", tokensIn: 100, tokensOut: 0 });
  await keyed(app(fakeClaude({ fail: "timeout" }), db), "k2");
  expect(db.finished[1]).toMatchObject({ status: "failed", errorReason: "timeout", tokensIn: null, costPaise: null });
});
