import { expect, test } from "bun:test";
import { createClient } from "@supabase/supabase-js";
import { makeDb } from "../src/db.js";
import { makeRecordSource } from "../src/jobs/record.js";
import { fakeClock } from "../src/jobs/db-fake.js";
import { makeObserve } from "../src/observe.js";
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
