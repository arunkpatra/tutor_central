import { expect, test } from "bun:test";
import { fakeAlertsSource } from "../src/alerts/db.js";
import { fakeSender } from "../src/alerts/resend.js";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { makeHandlers } from "../src/jobs/kinds/index.js";
import { makeApp } from "../src/make-app.js";
import { fakeObserve } from "../src/observe-fake.js";
import { fakePusher } from "../src/push/apns-fake.js";
import { fakeOutbox } from "../src/push/db.js";

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

test("a sweep runs each ten minutes, so a call left pending blocks its key for ten minutes, not an hour", async () => {
  const { app, jobs, clock } = build();
  await app.request("/jobs/tick", { headers: bearer });
  clock.advance(60_000);
  await app.request("/jobs/tick", { headers: bearer });
  expect(jobs.counts.closePending).toBe(1);
  clock.advance(600_000);
  await app.request("/jobs/tick", { headers: bearer });
  expect(jobs.counts.closePending).toBe(2);
  expect(jobs.jobs.map((j) => j.key)).toEqual(["sweep:2026-10-12-12:00", "sweep:2026-10-12-12:10"]);
});

test("tick with the secret enqueues the ten minutes' sweep once and drains it", async () => {
  const { app, jobs } = build();
  jobs.setPendingClosed(2);
  const r = await app.request("/jobs/tick", { headers: bearer });
  expect(r.status).toBe(200);
  expect(await r.json()).toMatchObject({ claimed: 1, done: 1 });
  expect(jobs.jobs).toHaveLength(1);
  expect(jobs.jobs[0]).toMatchObject({ kind: "sweep", centreId: null, key: "sweep:2026-10-12-12:00", state: "done", result: { closed: 2 } });
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
  // The sweep's reach is 0040's and 0041's functions and the Storage API, no table.
  const sweep = await Bun.file(new URL("../src/jobs/sweep-db.ts", import.meta.url)).text();
  expect([...sweep.matchAll(/\.from\("(\w+)"\)/g)]).toEqual([]);
  expect(sweep).not.toMatch(/\.(insert|update|upsert|delete)\(/);
});

test("the tick sends what is due before it drains, and answers both", async () => {
  const clock = fakeClock();
  const jobs = fakeJobsDb(clock);
  const outbox = fakeOutbox([{ id: "n1", user_id: "u1", kind: "class", title: "t", body: "b", link: "tutorcentral://today", background: false }], {
    u1: [{ id: "t1", token: "tok", environment: "sandbox" }],
  });
  const pusher = fakePusher({});
  const app = makeApp({
    verify: async () => null,
    claude: fakeClaude({}),
    db: fakeDb(),
    apple: fakeApple({}),
    observe: fakeObserve(),
    worker: { jobs, db: fakeDb(), secret: "s3cret", clock, push: { outbox, pusher: () => pusher } },
  });
  const r = await app.request("/jobs/tick", { headers: bearer });
  expect(await r.json()).toMatchObject({ claimed: 1, done: 1, push: { sent: 1, failed: 0, retired: 0 } });
  expect(outbox.marks).toEqual([{ id: "n1", state: "sent", apns: [{ token: "t1", apnsId: "a-tok" }] }]);
  expect(pusher.closed).toBe(1);
  // The wake drains only: a push is the minute's work.
  expect(await (await app.request("/jobs/wake", { method: "POST", headers: bearer })).json()).not.toHaveProperty("push");
});

test("/jobs/health renders one page and answers apns true behind the bearer", async () => {
  const clock = fakeClock();
  const pusher = fakePusher({ ["0".repeat(64)]: { ok: false, status: 400, reason: "BadDeviceToken", retire: true } });
  const app = makeApp({
    verify: async () => null,
    claude: fakeClaude({}),
    db: fakeDb(),
    apple: fakeApple({}),
    observe: fakeObserve(),
    worker: { jobs: fakeJobsDb(clock), db: fakeDb(), secret: "s3cret", clock, push: { outbox: fakeOutbox([], {}), pusher: () => pusher } },
  });
  expect((await app.request("/jobs/health")).status).toBe(401);
  const r = await app.request("/jobs/health", { headers: bearer });
  expect(await r.json()).toEqual({ pdf: 1, apns: true });
  expect(pusher.sent.map((p) => p.environment)).toEqual(["production"]);
  expect(pusher.closed).toBe(1);
});

test("the tick queues alerts:<ten minutes> beside the sweep when the alerts' source is given", async () => {
  const clock = fakeClock();
  const jobs = fakeJobsDb(clock);
  const source = fakeAlertsSource({ failedJobs: [], costToday: [], requestsHour: { total: 0, errors: 0 }, stuckJobs: [] }, []);
  const app = makeApp({
    verify: async () => null,
    claude: fakeClaude({}),
    db: fakeDb(),
    apple: fakeApple({}),
    observe: fakeObserve(),
    worker: { jobs, db: fakeDb(), secret: "s3cret", clock, handlers: makeHandlers({ alerts: { source, sender: fakeSender(), email: "you@example.com" } }) },
  });
  await app.request("/jobs/tick", { headers: bearer });
  clock.advance(60_000);
  await app.request("/jobs/tick", { headers: bearer });
  expect(jobs.jobs.map((j) => j.key).sort()).toEqual(["alerts:2026-10-12-12:00", "sweep:2026-10-12-12:00"]);
  expect(jobs.jobs.find((j) => j.kind === "alerts")).toMatchObject({ centreId: null, state: "done", result: { checked: 0, raised: 0 } });
  clock.advance(600_000);
  await app.request("/jobs/tick", { headers: bearer });
  expect(jobs.jobs.filter((j) => j.kind === "alerts").map((j) => j.key)).toEqual(["alerts:2026-10-12-12:00", "alerts:2026-10-12-12:10"]);
});
