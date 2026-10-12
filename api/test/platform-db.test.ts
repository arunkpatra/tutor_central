import { expect, test } from "bun:test";
import { createClient } from "@supabase/supabase-js";
import { makeRecordSource } from "../src/jobs/record.js";
import { makeObserve } from "../src/observe.js";

// The platform's reads and writes over the local stack's service role (the review's findings 3 and 8). It needs
// `supabase start`; without it the file says so and skips.
const status = Bun.spawnSync(["supabase", "status", "-o", "env"], { cwd: `${import.meta.dir}/../../supabase`, stderr: "pipe" });
const out = status.stdout.toString();
const get = (k: string) => out.match(new RegExp(`^${k}="?([^"\\n]+)"?$`, "m"))?.[1];
const url = get("API_URL");
const service = get("SERVICE_ROLE_KEY");
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
