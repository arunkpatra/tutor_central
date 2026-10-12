import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { makeApp } from "../src/make-app.js";
import { fakeObserve } from "../src/observe-fake.js";

function build() {
  const clock = fakeClock();
  const jobs = fakeJobsDb(clock);
  const observe = fakeObserve();
  const app = makeApp({
    verify: async () => null,
    claude: fakeClaude({}),
    db: fakeDb(),
    apple: fakeApple({}),
    observe,
    worker: { jobs, db: fakeDb(), secret: "s3cret", clock },
  });
  return { app, jobs, observe, clock };
}
const bearer = { authorization: "Bearer s3cret" };

test("the worker's routes need the worker's secret", async () => {
  const { app } = build();
  for (const [path, method] of [["/jobs/tick", "GET"], ["/jobs/wake", "POST"]] as const) {
    expect((await app.request(path, { method })).status).toBe(401);
    expect((await app.request(path, { method, headers: { authorization: "Bearer wrong" } })).status).toBe(401);
    expect(await (await app.request(path, { method })).json()).toEqual({ error: "sign in again" });
  }
});

test("tick with the secret enqueues the hour's sweep once and drains it", async () => {
  const { app, jobs } = build();
  jobs.setPendingClosed(2);
  const r = await app.request("/jobs/tick", { headers: bearer });
  expect(r.status).toBe(200);
  expect(await r.json()).toMatchObject({ claimed: 1, done: 1 });
  expect(jobs.jobs).toHaveLength(1);
  expect(jobs.jobs[0]).toMatchObject({ kind: "sweep", centreId: null, key: "sweep:2026-10-12-12", state: "done", result: { closed: 2 } });
  await app.request("/jobs/tick", { headers: bearer });
  expect(jobs.jobs).toHaveLength(1);
  expect(jobs.counts.closePending).toBe(1);
});

test("a tick while a sweep is live enqueues no other", async () => {
  const { app, jobs, clock } = build();
  await jobs.enqueue(null, "sweep", "sweep:earlier", {}, new Date(clock.now() + 3_600_000));
  await app.request("/jobs/tick", { headers: bearer });
  expect(jobs.jobs.filter((j) => j.kind === "sweep")).toHaveLength(1);
});

test("wake with the secret drains a queued job", async () => {
  const { app, jobs } = build();
  await jobs.enqueue(null, "sweep", "sweep:now");
  const r = await app.request("/jobs/wake", { method: "POST", headers: { ...bearer, "content-type": "application/json" }, body: JSON.stringify({ job: "job-1" }) });
  expect(r.status).toBe(200);
  expect(await r.json()).toMatchObject({ claimed: 1, done: 1 });
});

test("a worker's request leaves its row with no user", async () => {
  const { app, observe } = build();
  await app.request("/jobs/tick", { headers: bearer });
  expect(observe.rows[0]).toMatchObject({ route: "/jobs/tick", status: 200 });
  expect(observe.rows[0]?.userId).toBeUndefined();
});

test("the worker reaches the database only through its named functions", async () => {
  const source = await Bun.file(new URL("../src/jobs/db.ts", import.meta.url)).text();
  const reads = [...source.matchAll(/\.from\("(\w+)"\)/g)].map((m) => m[1]);
  // The one table read is the sweep guard's count of live jobs; every write is a function of 0028 or 0029.
  expect(reads).toEqual(["jobs"]);
  expect(source).not.toMatch(/\.(insert|update|upsert|delete)\(/);
});
