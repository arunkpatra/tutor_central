import { expect, test } from "bun:test";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { makeSweep, type SweepSource } from "../src/jobs/kinds/sweep.js";
import type { Job, StepContext, StepOutcome } from "../src/jobs/types.js";

// The sweep (plan decisions 20, 27): calls left pending closed, then Storage's deleted files removed (a path, or a
// prefix listed page by page), then the retention: exports past seven days, old outbox rows and the platform's old jobs.
function files(over: { deletions?: { bucket: string; path: string; prefix: boolean }[]; objects?: Record<string, string[]>; old?: string[]; failRemove?: string } = {}) {
  const objects: Record<string, string[]> = { photos: [], exports: [], pdfs: [], ...(over.objects ?? {}) };
  // As 0044 keeps them: a taken row stays until done, and is not handed out again (the fake has no ten minutes).
  const deletions = (over.deletions ?? []).map((d, i) => ({ ...d, id: `d${i}`, taken: false }));
  const removed: { bucket: string; paths: string[] }[] = [];
  const s: SweepSource & { removed: typeof removed; objects: Record<string, string[]>; trimmedAt: string[]; left: () => string[] } = {
    removed,
    objects,
    trimmedAt: [],
    left: () => deletions.map((d) => d.path),
    async takeDeletions(limit) {
      const taken = deletions.filter((d) => !d.taken).slice(0, limit);
      for (const d of taken) d.taken = true;
      return taken.map(({ id, bucket, path, prefix }) => ({ id, bucket, path, prefix }));
    },
    async doneDeletion(id) {
      deletions.splice(deletions.findIndex((d) => d.id === id), 1);
    },
    async list(bucket, prefix) {
      return (objects[bucket] ?? []).filter((name) => name.startsWith(prefix));
    },
    async remove(bucket, paths) {
      if (over.failRemove && paths.some((p) => p.startsWith(over.failRemove!))) throw new Error(`${bucket} remove: 503`);
      removed.push({ bucket, paths });
      objects[bucket] = (objects[bucket] ?? []).filter((name) => !paths.includes(name));
    },
    async oldExports() {
      return over.old ?? [];
    },
    async trim(now) {
      s.trimmedAt.push(now);
      return { notifications: 2, jobs: 3 };
    },
  };
  return s;
}
const ctx = (): StepContext => {
  const clock = fakeClock();
  return { db: fakeDb(), jobs: fakeJobsDb(clock), claude: fakeClaude({}), clock, requestId: "r1", worker: "w1" };
};
async function run(handler: ReturnType<typeof makeSweep>, c: StepContext) {
  const seen: StepOutcome[] = [];
  let current: Job = { id: "job-1", centreId: null, kind: "sweep", attempts: 1, step: {}, input: {}, leaseUntil: "" };
  for (let i = 0; i < 10; i++) {
    const outcome = await handler.step(current, c);
    seen.push(outcome);
    if (outcome.kind !== "continue") break;
    current = { ...current, step: outcome.step };
  }
  return seen;
}

test("a photo path and a student's exports prefix are taken and removed", async () => {
  const s = files({
    deletions: [{ bucket: "photos", path: "c1/mark/x.jpg", prefix: false }, { bucket: "exports", path: "c1/s1/", prefix: true }],
    objects: { photos: ["c1/mark/x.jpg", "c1/mark/y.jpg"], exports: ["c1/s1/j1.pdf", "c1/s1/j2.pdf", "c1/s2/j3.pdf"] },
  });
  const out = await run(makeSweep(s), ctx());
  expect(out.map((o) => o.name)).toEqual(["pending", "storage", "retention"]);
  expect(s.objects.photos).toEqual(["c1/mark/y.jpg"]);
  expect(s.objects.exports).toEqual(["c1/s2/j3.pdf"]);
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { closed: 0, removed: 3, trimmed: { notifications: 2, jobs: 3, exports: 0 } } });
});

test("an object already gone counts as removed and its row is gone", async () => {
  const s = files({ deletions: [{ bucket: "pdfs", path: "c1/a1.pdf", prefix: false }] });
  const out = await run(makeSweep(s), ctx());
  expect(out.at(-1)).toMatchObject({ result: { removed: 1 } });
  expect(await s.takeDeletions(10)).toEqual([]);
});

test("a remove Storage refuses keeps its row for a later sweep; the other rows are done (the review's R-db-2)", async () => {
  const s = files({
    deletions: [{ bucket: "pdfs", path: "c1/", prefix: true }, { bucket: "exports", path: "c1/", prefix: true }],
    objects: { pdfs: ["c1/a.pdf"], exports: ["c1/s1/j.pdf"] },
    failRemove: "c1/a",
  });
  const out = await run(makeSweep(s), ctx());
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { removed: 1, left: 1 } });
  expect(s.left()).toEqual(["c1/"]);
  expect(s.objects.exports).toEqual([]);
  expect(s.objects.pdfs).toEqual(["c1/a.pdf"]);
});

test("exports past seven days are removed; the trim asks for its time", async () => {
  const s = files({ objects: { exports: ["c1/s1/old.pdf", "c1/s1/new.pdf"] }, old: ["c1/s1/old.pdf"] });
  const out = await run(makeSweep(s), ctx());
  expect(s.objects.exports).toEqual(["c1/s1/new.pdf"]);
  expect(out.at(-1)).toMatchObject({ result: { trimmed: { exports: 1 } } });
  expect(s.trimmedAt).toEqual(["2026-10-12T12:00:00.000Z"]);
});

test("without Storage the sweep closes pending calls alone, as before", async () => {
  const out = await run(makeSweep(), ctx());
  expect(out).toEqual([{ kind: "done", name: "pending", result: { closed: 0 } }]);
});
