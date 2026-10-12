import { expect, test } from "bun:test";
import { createClient } from "@supabase/supabase-js";
import { makeDb } from "../src/db.js";
import { makeRecordSource } from "../src/jobs/record.js";
import { fakeClock } from "../src/jobs/db-fake.js";
import { makeObserve } from "../src/observe.js";
import { planJob } from "../src/jobs/kinds/plan.js";
import { noteDay } from "../src/jobs/kinds/note-day.js";
import { makeNoteSource } from "../src/notes/record.js";
import { exportJob } from "../src/jobs/kinds/export.js";
import { makeExportSource } from "../src/export/record.js";
import { makeSweep } from "../src/jobs/kinds/sweep.js";
import { makeSweepSource } from "../src/jobs/sweep-db.js";
import { makePlatformDb } from "../src/db.js";
import { kindOf, SAMPLE } from "../src/claude-fake.js";
import { fakePusher } from "../src/push/apns-fake.js";
import { reminderSweep } from "../src/jobs/kinds/reminder-sweep.js";
import { fakeJobsDb } from "../src/jobs/db-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeOutboxDb } from "../src/push/db.js";
import { makeReminderSource } from "../src/reminders/source.js";
import { sendDue } from "../src/push/send-due.js";

// The platform's reads and writes over the local stack's service role (the review's findings 3 and 8). It needs
// `supabase start`; without it the file says so and skips.
const status = Bun.spawnSync(["supabase", "status", "-o", "env"], { cwd: `${import.meta.dir}/../../supabase`, stderr: "pipe" });
const out = status.stdout.toString();
const get = (k: string) => out.match(new RegExp(`^${k}="?([^"\\n]+)"?$`, "m"))?.[1];
const url = get("API_URL");
const service = get("SERVICE_ROLE_KEY");
const anon = get("ANON_KEY");
const up = status.exitCode === 0 && !!url && !!service;
if (!up) console.log("platform-db.test: local Supabase is not running; skipped (supabase start)");
const CENTRE = "22222222-2222-2222-2222-222222222222";
const admin = () => createClient(url as string, service as string, { auth: { persistSession: false, autoRefreshToken: false } });

test.skipIf(!up)("a name step retaken after its writes finds the chapter and the skill it wrote, and writes no second", async () => {
  const db = admin();
  const student = (await db.from("students").select("id").eq("centre_id", CENTRE).limit(1).single()).data?.id as string;
  const source = makeRecordSource(url as string, service as string);
  const chapter = `Review chapter ${Date.now()}`;
  try {
    const first = await source.addChapter(CENTRE, student, "Mathematics", chapter, "The first idea");
    const again = await source.addChapter(CENTRE, student, "Mathematics", chapter.toUpperCase(), "The first idea");
    expect(again).toBe(first);
    const chapters = await db.from("chapters").select("id").eq("centre_id", CENTRE).eq("student_id", student).ilike("name", chapter);
    expect(chapters.data).toHaveLength(1);
    const chapterId = chapters.data?.[0]?.id as string;
    const second = await source.addSkill(CENTRE, chapterId, student, "The next idea");
    expect(await source.addSkill(CENTRE, chapterId, student, "The next idea")).toBe(second);
    const skills = await db.from("skills").select("name").eq("chapter_id", chapterId);
    expect(skills.data?.map((s) => s.name).sort()).toEqual(["The first idea", "The next idea"]);
  } finally {
    await db.from("chapters").delete().eq("centre_id", CENTRE).eq("student_id", student).ilike("name", chapter);
  }
});

test.skipIf(!up)("the user's rate counts their answered calls, not the refusals the limit wrote", async () => {
  const db = admin();
  const user = crypto.randomUUID();
  const row = (status: number) => ({ request_id: crypto.randomUUID(), route: "/ai/make", method: "POST", status, latency_ms: 1, user_id: user });
  try {
    await db.from("api_requests").insert([...Array.from({ length: 19 }, () => row(200)), row(400), row(429), row(429), row(429)]);
    expect(await makeObserve(url as string, service as string).recentCount(user, 60)).toBe(20);
  } finally {
    await db.from("api_requests").delete().eq("user_id", user);
  }
});

test.skipIf(!up)("a route's call is started as the tutor and finished as the platform (0035: a member writes no row)", async () => {
  const tutor = createClient(url as string, anon as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const signed = await tutor.auth.signInWithPassword({ email: "meera@example.com", password: "tutor-local-1" });
  const token = signed.data.session?.access_token as string;
  const db = makeDb(url as string, anon as string, service as string);
  const key = `platform-finish-${Date.now()}`;
  const started = await db.startCall(token, { centre: CENTRE, kind: "sheet", input: {}, model: "claude-haiku-5-5", key, inputHash: "h" });
  try {
    await db.finish(token, started.id, { status: "ok", output: "{}", model: "claude-haiku-5-5", tokensIn: 1, tokensOut: 1, costPaise: 1, latencyMs: 5, promptHash: "p", stopReason: "end_turn", errorReason: null, finishedAt: new Date().toISOString() });
    const row = await admin().from("ai_generations").select("status, cost_paise, user_id").eq("id", started.id).single();
    expect(row.data).toMatchObject({ status: "ok", cost_paise: 1 });
    expect(row.data?.user_id).not.toBeNull();
  } finally {
    await admin().from("ai_generations").delete().eq("id", started.id);
  }
});

test.skipIf(!up)("a row due in the outbox is sent to the user's live token and marked sent with Apple's answer", async () => {
  const db = admin();
  const user = (await db.from("centre_members").select("user_id").eq("centre_id", CENTRE).limit(1).single()).data?.user_id as string;
  const outbox = makeOutboxDb(url as string, service as string);
  const key = `class:platform-db:${Date.now()}`;
  const device = `platform-db-${Date.now()}`;
  try {
    await db.from("device_tokens").insert({ user_id: user, device_id: device, token: "tok-platform", environment: "sandbox" });
    expect(await outbox.replace(CENTRE, user, ["class"], new Date(Date.now() - 60_000).toISOString(), [{ kind: "class", key, due_at: new Date(Date.now() - 1000).toISOString(), title: "t", body: "b", link: "tutorcentral://today" }])).toBe(1);
    const pusher = fakePusher({});
    const counts = await sendDue({ outbox, pusher, clock: { ...fakeClock(), now: () => Date.now() } });
    expect(counts.sent).toBeGreaterThanOrEqual(1);
    expect(pusher.sent.some((p) => p.token === "tok-platform")).toBe(true);
    const row = (await db.from("notifications").select("state, apns").eq("key", key).single()).data;
    expect(row?.state).toBe("sent");
    expect(JSON.stringify(row?.apns)).toContain("a-tok-platform");
  } finally {
    await db.from("notifications").delete().eq("key", key);
    await db.from("device_tokens").delete().eq("device_id", device);
  }
});

test.skipIf(!up)("a centre with a live token and a batch in two hours gets its class reminder in the outbox", async () => {
  const db = admin();
  const user = (await db.from("centre_members").select("user_id").eq("centre_id", CENTRE).limit(1).single()).data?.user_id as string;
  const outbox = makeOutboxDb(url as string, service as string);
  const device = `platform-db-reminder-${Date.now()}`;
  const start = new Date(Date.now() + 5.5 * 3_600_000 + 2 * 3_600_000).toISOString().slice(11, 16);
  const room = (await db.from("classes").insert({ centre_id: CENTRE, name: "Reminder probe", meeting_days: [1, 2, 3, 4, 5, 6, 7], start_time: start }).select("id").single()).data?.id as string;
  try {
    await db.from("device_tokens").insert({ user_id: user, device_id: device, token: "tok-reminder", environment: "sandbox" });
    const now = Date.now();
    const clock = { now: () => now, sleep: async () => {} };
    const job = { id: "job-r", centreId: CENTRE, kind: "reminder_sweep" as const, attempts: 1, step: {}, input: { centre_id: CENTRE }, leaseUntil: "" };
    const out = await reminderSweep(makeReminderSource(url as string, service as string, outbox)).step(job, { db: fakeDb(), jobs: fakeJobsDb(clock as never), claude: fakeClaude({}), clock, requestId: "r", worker: "w" });
    expect(out).toMatchObject({ kind: "done", name: "plan" });
    const rows = (await db.from("notifications").select("key, title, state").eq("user_id", user).like("key", `class:${room}:%`)).data ?? [];
    expect(rows.length).toBeGreaterThanOrEqual(1);
    expect(rows[0]).toMatchObject({ title: `Reminder probe at ${start}`, state: "due" });
  } finally {
    await db.from("notifications").delete().eq("user_id", user).like("key", `class:${room}:%`);
    await db.from("device_tokens").delete().eq("device_id", device);
    await db.from("classes").delete().eq("id", room);
  }
});

test.skipIf(!up)("a plan job on the seed's Evening batch writes the plan, keeps its material by its keys and queues Plan ready", async () => {
  const db = admin();
  const batch = "33333333-3333-3333-3333-333333333333";
  const user = (await db.from("centre_members").select("user_id").eq("centre_id", CENTRE).limit(1).single()).data?.user_id as string;
  // A weekday three weeks on: no plan of the seed's, no exam week.
  const day = new Date(Date.now() + 5.5 * 3_600_000 + 21 * 86_400_000);
  while ([0, 6].includes(day.getUTCDay())) day.setUTCDate(day.getUTCDate() + 1);
  const date = day.toISOString().slice(0, 10);
  const device = `platform-db-plan-${Date.now()}`;
  const job = (await db.from("jobs").insert({ centre_id: CENTRE, kind: "plan", idempotency_key: `platform-db-plan-${Date.now()}`, input: { class_id: batch, date }, state: "running" }).select("id").single()).data?.id as string;
  const outbox = makeOutboxDb(url as string, service as string);
  try {
    await db.from("device_tokens").insert({ user_id: user, device_id: device, token: "tok-plan", environment: "sandbox" });
    const handler = planJob(makeRecordSource(url as string, service as string, outbox));
    const clock = { now: () => Date.now(), sleep: async () => {} };
    const ctx = { db: makePlatformDb(url as string, service as string), jobs: fakeJobsDb(clock as never), claude: fakeClaude((r) => ({ answer: SAMPLE[kindOf(r)] })), clock, requestId: crypto.randomUUID(), worker: "w" };
    let current = { id: job, centreId: CENTRE, kind: "plan" as const, attempts: 1, step: {} as Record<string, unknown>, input: { class_id: batch, date }, leaseUntil: "" };
    const names: string[] = [];
    for (let i = 0; i < 60; i++) {
      const out = await handler.step(current, ctx);
      names.push(`${out.name}:${out.kind}`);
      if (out.kind !== "continue") break;
      current = { ...current, step: out.step };
    }
    expect(names.at(-1)).toBe("notify:done");
    const plan = (await db.from("plans").select("id").eq("centre_id", CENTRE).eq("class_id", batch).eq("date", date).single()).data?.id as string;
    const kept = (await db.from("artefacts").select("kind, idempotency_key").eq("centre_id", CENTRE).like("idempotency_key", `${job}:make:%`)).data ?? [];
    expect(kept.length).toBeGreaterThanOrEqual(4);
    const linked = (await db.from("plan_items").select("artefact_id").eq("plan_id", plan).not("artefact_id", "is", null)).data ?? [];
    expect(linked.length).toBeGreaterThanOrEqual(4);
    const queued = (await db.from("notifications").select("kind").eq("user_id", user).like("key", `%:${batch}:${date}`)).data ?? [];
    expect(queued.map((n) => n.kind).sort()).toEqual(["plan_fetch", "plan_ready"]);
  } finally {
    await db.from("notifications").delete().eq("user_id", user).like("key", `%:${batch}:${date}`);
    await db.from("device_tokens").delete().eq("device_id", device);
    await db.from("plans").delete().eq("centre_id", CENTRE).eq("class_id", batch).eq("date", date);
    await db.from("artefacts").delete().eq("centre_id", CENTRE).like("idempotency_key", `${job}:make:%`);
    await db.from("jobs").delete().eq("id", job);
  }
});

test.skipIf(!up)("a note asked for the seed's Diya (her parent agreed) is made by the job and kept by its week's key, in Hindi with its English", async () => {
  const db = admin();
  const aarav = (await db.from("students").select("id").eq("centre_id", CENTRE).eq("name", "Diya Pillai").single()).data?.id as string;
  const today = new Date(Date.now() + 5.5 * 3_600_000);
  today.setUTCDate(today.getUTCDate() - ((today.getUTCDay() + 6) % 7));
  const monday = today.toISOString().slice(0, 10);
  const job = (await db.from("jobs").insert({ centre_id: CENTRE, kind: "note_day", idempotency_key: `platform-db-note-${Date.now()}`, input: { student_id: aarav, week: monday }, state: "running" }).select("id").single()).data?.id as string;
  const key = `note:${aarav}:`;
  try {
    const handler = noteDay(makeNoteSource(url as string, service as string, makeRecordSource(url as string, service as string, makeOutboxDb(url as string, service as string))));
    const clock = { now: () => Date.now(), sleep: async () => {} };
    const ctx = { db: makePlatformDb(url as string, service as string), jobs: fakeJobsDb(clock as never), claude: fakeClaude((r) => ({ answer: SAMPLE[kindOf(r)] })), clock, requestId: crypto.randomUUID(), worker: "w" };
    let current = { id: job, centreId: CENTRE, kind: "note_day" as const, attempts: 1, step: {} as Record<string, unknown>, input: { student_id: aarav, week: monday }, leaseUntil: "" };
    let last = "";
    for (let i = 0; i < 10; i++) {
      const out = await handler.step(current, ctx);
      last = `${out.name}:${out.kind}:${JSON.stringify((out as { result?: unknown }).result ?? "")}`;
      if (out.kind !== "continue") break;
      current = { ...current, step: out.step };
    }
    expect(last).toStartWith("notify:done:");
    const kept = (await db.from("artefacts").select("kind, idempotency_key, content").eq("centre_id", CENTRE).eq("student_id", aarav).like("idempotency_key", `${key}%`)).data ?? [];
    expect(kept).toHaveLength(1);
    expect(kept[0]).toMatchObject({ kind: "note" });
    expect(kept[0]?.content).toMatchObject({ language: "hi", english: expect.any(String), week_monday: monday });
  } finally {
    await db.from("artefacts").delete().eq("centre_id", CENTRE).eq("student_id", aarav).like("idempotency_key", `${key}%`);
    await db.from("jobs").delete().eq("id", job);
  }
});

test.skipIf(!up)("a note the phone kept for the week (its Monday an ISO day, under the phone's key) is read as kept, so the job writes no second", async () => {
  const db = admin();
  const diya = (await db.from("students").select("id").eq("centre_id", CENTRE).eq("name", "Diya Pillai").single()).data?.id as string;
  const today = new Date(Date.now() + 5.5 * 3_600_000);
  today.setUTCDate(today.getUTCDate() - ((today.getUTCDay() + 6) % 7));
  const monday = today.toISOString().slice(0, 10);
  const key = `platform-db-phone-note-${Date.now()}`;
  try {
    const phone = { message: "m", language: "en", week_monday: monday, facts: [] };
    expect((await db.from("artefacts").insert({ centre_id: CENTRE, kind: "note", source: "made", student_id: diya, title: "Diya's week", content: phone, idempotency_key: key })).error).toBeNull();
    const source = makeNoteSource(url as string, service as string, makeRecordSource(url as string, service as string, makeOutboxDb(url as string, service as string)));
    const read = await source.read(CENTRE, { studentId: diya, week: monday });
    expect(read.students.map((s) => s.kept)).toEqual([true]);
  } finally {
    await db.from("artefacts").delete().eq("centre_id", CENTRE).eq("idempotency_key", key);
  }
});

test.skipIf(!up)("an export asked for the seed's Hemanth is a PDF in exports under the centre and the student", async () => {
  const db = admin();
  const hemanth = (await db.from("students").select("id").eq("centre_id", CENTRE).eq("name", "Hemanth Reddy").single()).data?.id as string;
  const member = createClient(url as string, anon as string, { auth: { persistSession: false } });
  // The seed's tutor (supabase/CLAUDE.md) asks, as the app does.
  await member.auth.signInWithPassword({ email: "meera@example.com", password: "tutor-local-1" });
  const asked = await member.rpc("request_export", { p_centre: CENTRE, p_student: hemanth });
  expect(asked.error).toBeNull();
  const job = asked.data as string;
  let path = "";
  try {
    const clock = { now: () => Date.now(), sleep: async () => {} };
    const ctx = { db: makePlatformDb(url as string, service as string), jobs: fakeJobsDb(clock as never), claude: fakeClaude({}), clock, requestId: crypto.randomUUID(), worker: "w" };
    const out = await exportJob(makeExportSource(url as string, service as string)).step({ id: job, centreId: CENTRE, kind: "export", attempts: 1, step: {}, input: { student_id: hemanth }, leaseUntil: "" }, ctx);
    expect(out).toMatchObject({ kind: "done", result: { path: `${CENTRE}/${hemanth}/${job}.pdf` } });
    path = (out as unknown as { result: { path: string } }).result.path;
    const file = await db.storage.from("exports").download(path);
    expect(file.error).toBeNull();
    expect(new TextDecoder("latin1").decode(new Uint8Array(await file.data!.arrayBuffer()).slice(0, 5))).toBe("%PDF-");
  } finally {
    if (path) await db.storage.from("exports").remove([path]);
    await db.from("jobs").delete().eq("id", job);
  }
});

test.skipIf(!up)("a deleted student's marks photo leaves Storage at the next sweep", async () => {
  const db = admin();
  const student = (await db.from("students").insert({ centre_id: CENTRE, name: "Sweep probe" }).select("id").single()).data?.id as string;
  const photo = `${CENTRE}/mark/sweep-${Date.now()}.jpg`;
  const jpeg = new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0])], { type: "image/jpeg" });
  expect((await db.storage.from("photos").upload(photo, jpeg)).error).toBeNull();
  await db.from("marks").insert({ centre_id: CENTRE, student_id: student, subject: "Maths", test: "Probe", date: "2026-10-01", score: 1, max: 2, photo_path: photo });
  await db.from("students").delete().eq("id", student);
  const clock = { now: () => Date.now(), sleep: async () => {} };
  const ctx = { db: makePlatformDb(url as string, service as string), jobs: fakeJobsDb(clock as never), claude: fakeClaude({}), clock, requestId: crypto.randomUUID(), worker: "w" };
  const sweep = makeSweep(makeSweepSource(url as string, service as string));
  let current = { id: "sweep-probe", centreId: null, kind: "sweep" as const, attempts: 1, step: {} as Record<string, unknown>, input: {}, leaseUntil: "" };
  let removed = 0;
  for (let i = 0; i < 5; i++) {
    const out = await sweep.step(current, ctx);
    if (out.kind === "done") removed = (out.result as { removed: number }).removed;
    if (out.kind !== "continue") break;
    current = { ...current, step: out.step };
  }
  expect(removed).toBeGreaterThanOrEqual(1);
  const left = (await db.storage.from("photos").list(`${CENTRE}/mark`, { search: photo.split("/").at(-1) })).data ?? [];
  expect(left).toEqual([]);
});
