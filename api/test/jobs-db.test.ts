import { expect, test } from "bun:test";
import { createClient } from "@supabase/supabase-js";
import { makeJobsDb } from "../src/jobs/db.js";
import { LeaseLost } from "../src/jobs/types.js";

// The real JobsDb over the local stack's service role. It needs `supabase start`; without it the file says so and skips.
const status = Bun.spawnSync(["supabase", "status", "-o", "env"], { cwd: `${import.meta.dir}/../../supabase`, stderr: "pipe" });
const out = status.stdout.toString();
const get = (k: string) => out.match(new RegExp(`^${k}="?([^"\\n]+)"?$`, "m"))?.[1];
const url = get("API_URL");
const service = get("SERVICE_ROLE_KEY");
const up = status.exitCode === 0 && !!url && !!service;
if (!up) console.log("jobs-db.test: local Supabase is not running; skipped (supabase start)");

test.skipIf(!up)("the real JobsDb enqueues, claims, records each outcome and sweeps", async () => {
  const admin = createClient(url as string, service as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const jobs = makeJobsDb(url as string, service as string);
  const stamp = Date.now();
  // A claim takes any due job: start from none.
  await admin.from("jobs").delete().not("id", "is", null);
  const id = await jobs.enqueue(null, "sweep", `sweep:db-test-${stamp}`);
  expect(await jobs.enqueue(null, "sweep", `sweep:db-test-${stamp}`)).toBe(id);
  expect(await jobs.live("sweep")).toBe(1);
  const [claimed] = await jobs.claim("w1", 5);
  expect(claimed).toMatchObject({ id, kind: "sweep", centreId: null, attempts: 1, step: {} });
  expect(await jobs.extend(id, "w1")).toBe(true);
  await jobs.record(id, "w1", { kind: "continue", name: "pending", step: { at: "more" }, costPaise: 3 });
  await jobs.record(id, "w1", { kind: "wait", name: "more", step: { at: "more" }, runAt: new Date() });
  const [again] = await jobs.claim("w2", 5);
  expect(again).toMatchObject({ id, step: { at: "more" }, attempts: 1 });
  await expect(jobs.record(id, "w1", { kind: "done", name: "more", result: {} })).rejects.toBeInstanceOf(LeaseLost);
  await jobs.record(id, "w2", { kind: "fail", name: "more", error: { reason: "error" }, retry: false });
  const row = await admin.from("jobs").select("state, cost_paise, error").eq("id", id).single();
  expect(row.data).toEqual({ state: "failed", cost_paise: 3, error: { reason: "error" } });
  const done = await jobs.enqueue(null, "sweep", `sweep:db-test-done-${stamp}`);
  await jobs.claim("w3", 5);
  await jobs.record(done, "w3", { kind: "done", name: "pending", result: { closed: 0 } });
  expect((await admin.from("jobs").select("state, result").eq("id", done).single()).data).toEqual({ state: "done", result: { closed: 0 } });
  expect(await jobs.closePending()).toBeNumber();
  await admin.from("jobs").delete().not("id", "is", null);
});
