import { afterEach, expect, test } from "bun:test";
import { fakeClaude, localAnswer } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { evalRun } from "../src/jobs/kinds/eval-run.js";
import type { Job, StepContext, StepOutcome } from "../src/jobs/types.js";
import { fakeModelSource } from "../src/models-db.js";
import { installModelTable } from "../src/models.js";
import { costPaise } from "../src/price.js";
import { EVAL_KINDS, loadCases, NIGHTLY_KINDS, TAP_KINDS } from "../src/evals/cases.js";

// The nightly evals (D101, plan decision 12): every case of every kind on, as Message Batches at half price, its calls
// recorded under the Smoke centre with their steps; the result on the job.
const SMOKE = "c0000000-0000-4000-8000-00000000aaaa";
const job = (input: Record<string, unknown> = { day: "2026-10-20" }, step: Record<string, unknown> = {}): Job => ({ id: "eval-1", centreId: null, kind: "eval_run", attempts: 1, step, input, leaseUntil: "" });
const ctx = (claude = fakeClaude((r) => ({ answer: localAnswer(r) })), db = fakeDb({ limit: 1000 })) => {
  const clock = fakeClock();
  return { db, jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" } as StepContext & { db: ReturnType<typeof fakeDb>; claude: ReturnType<typeof fakeClaude> };
};
/** The job's steps to its end, each wait taken again at once. */
async function drain(handler: ReturnType<typeof evalRun>, c: StepContext, input?: Record<string, unknown>) {
  const out: StepOutcome[] = [];
  let current = job(input);
  for (let i = 0; i < 20; i++) {
    const o = await handler.step(current, c);
    out.push(o);
    if (o.kind === "done" || o.kind === "fail") break;
    current = { ...current, step: o.step };
  }
  return out;
}
let stop: (() => void) | null = null;
afterEach(() => {
  stop?.();
  stop = null;
});

test("a run submits one draft per case of the kinds asked and skips a paused kind", async () => {
  const t = installModelTable(fakeModelSource([{ kind: "check", step: "draft", model: "claude-haiku-5-5", effort: "medium", fallbackModel: null, enabled: false }]));
  stop = t.stop;
  await t.refresh();
  const c = ctx();
  const out = await drain(evalRun({ smokeCentre: SMOKE }), c, { day: "2026-10-20", kinds: ["sheet", "check"] });
  expect(c.claude.batches[0]?.map((i) => i.customId)).toEqual(["sheet-8-linear", "sheet-4-fractions", "sheet-8-reactions", "sheet-10-quadratic", "sheet-6-past-tense"]);
  const done = out.at(-1) as unknown as { kind: string; result: { paused: string[]; kinds: Record<string, unknown> } };
  expect(done.kind).toBe("done");
  expect(done.result.paused).toEqual(["check"]);
  expect(Object.keys(done.result.kinds)).toEqual(["sheet"]);
});

test("the job waits while a batch runs and scores when it ends", async () => {
  const c = ctx(fakeClaude((r) => ({ answer: localAnswer(r) }), { batchPolls: 2 }));
  const out = await drain(evalRun({ smokeCentre: SMOKE }), c, { day: "2026-10-20", kinds: ["placement"] });
  expect(out.map((o) => `${o.name}:${o.kind}`)).toEqual(["submit:wait", "drafts:wait", "drafts:wait", "drafts:wait", "checks:wait", "checks:wait", "checks:done"]);
  const waits = out.filter((o) => o.kind === "wait") as { runAt: Date }[];
  expect(waits.every((w) => w.runAt.getTime() - c.clock.now() === 60_000)).toBe(true);
});

test("the result names each kind's passes, the rubric's rate and the gate's verdict", async () => {
  const c = ctx();
  const out = await drain(evalRun({ smokeCentre: SMOKE }), c, { day: "2026-10-20", kinds: ["check", "plan"] });
  const done = out.at(-1) as unknown as { result: { day: string; gate: boolean; kinds: Record<string, { cases: number; schema: number; verify: number; check_pass: number; grade_pass: number; grade_rate: number; cost_paise: number; gate: boolean }> } };
  expect(done.result.day).toBe("2026-10-20");
  expect(done.result.kinds.check).toMatchObject({ cases: 5, schema: 5, verify: 5, check_pass: 5, grade_pass: 5, grade_rate: 1, gate: true });
  expect(done.result.gate).toBe(true);
  expect(done.result.kinds.check!.cost_paise).toBeGreaterThan(0);
});

test("every row is the Smoke centre's, keyed by the run's day and case, with its agent step; a batch is half price", async () => {
  const c = ctx();
  const out = await drain(evalRun({ smokeCentre: SMOKE }), c, { day: "2026-10-20", kinds: ["check"] });
  const rows = c.db.rows;
  expect(new Set(rows.map((r) => r.agentStep))).toEqual(new Set(["draft", "check", "grade"]));
  expect(rows.filter((r) => r.agentStep === "draft").map((r) => r.key)).toEqual(["check-8-maths", "check-4-fractions", "check-8-science", "check-10-maths", "check-6-english"].map((id) => `evals:2026-10-20:${id}`));
  expect(rows.filter((r) => r.agentStep === "grade").every((r) => r.model === "claude-opus-5-5" && r.key?.endsWith(":grade"))).toBe(true);
  expect((c.db.started as { centre: string }[]).every((s) => s.centre === SMOKE)).toBe(true);
  // A batch is priced at half (812 in and 1,460 out on Haiku: 6.9 paise live, 3 in a batch).
  const draft = rows.find((r) => r.agentStep === "draft")!;
  expect(draft.finish?.costPaise).toBe(costPaise("claude-haiku-5-5", 812, 1460, 0, 0, 0.5));
  expect(draft.finish?.costPaise).toBe(3);
  const total = rows.reduce((n, r) => n + (r.finish?.costPaise ?? 0), 0);
  const recorded = out.reduce((n, o) => n + ((o as { costPaise?: number }).costPaise ?? 0), 0);
  expect(recorded).toBe(total);
});

test("a run with no smoke centre fails without a retry", async () => {
  const out = await evalRun({ smokeCentre: "" }).step(job(), ctx());
  expect(out).toMatchObject({ kind: "fail", retry: false, error: { reason: "no_smoke_centre" } });
});

test("a night that started no case ends with the gate false and says why, never green on nothing (the review's finding 3)", async () => {
  const c = ctx(undefined, fakeDb({ limit: 0 }));
  const out = await drain(evalRun({ smokeCentre: SMOKE }), c, { day: "2026-10-20", kinds: ["placement"] });
  const done = out.at(-1) as unknown as { kind: string; result: { gate: boolean; reason?: string; not_started: number } };
  expect(done.kind).toBe("done");
  expect(done.result).toMatchObject({ gate: false, reason: "no_cases", not_started: 5 });
});

test("a sheet band switched off skips its own cases; a kind switched off mid-run is skipped, not a crash (finding 7)", async () => {
  const t = installModelTable(fakeModelSource([{ kind: "sheet_to_5", step: "draft", model: "claude-haiku-5-5", effort: "medium", fallbackModel: null, enabled: false }]));
  stop = t.stop;
  await t.refresh();
  const c = ctx();
  await drain(evalRun({ smokeCentre: SMOKE }), c, { day: "2026-10-20", kinds: ["sheet"] });
  expect(c.claude.batches[0]?.map((i) => i.customId)).toEqual(["sheet-8-linear", "sheet-8-reactions", "sheet-10-quadratic", "sheet-6-past-tense"]);
  t.stop();
  const later = installModelTable(fakeModelSource([]));
  stop = later.stop;
  await later.refresh();
  const c2 = ctx();
  const handler = evalRun({ smokeCentre: SMOKE });
  let current = job({ day: "2026-10-20", kinds: ["placement"] });
  let o = await handler.step(current, c2);
  current = { ...current, step: (o as { step: Record<string, unknown> }).step };
  o = await handler.step(current, c2);
  current = { ...current, step: (o as { step: Record<string, unknown> }).step };
  later.stop();
  const off = installModelTable(fakeModelSource([{ kind: "placement", step: "draft", model: "claude-haiku-5-5", effort: "medium", fallbackModel: null, enabled: false }]));
  stop = off.stop;
  await off.refresh();
  const last = await handler.step(current, c2);
  expect(last.kind).toBe("done");
});

test("a weekday's set runs the nightly kinds; every kind is in one set or the other (Phase 21 decision 8)", async () => {
  expect([...NIGHTLY_KINDS, ...TAP_KINDS].sort()).toEqual([...EVAL_KINDS].sort());
  expect(NIGHTLY_KINDS.filter((k) => (TAP_KINDS as readonly string[]).includes(k))).toEqual([]);
  const c = ctx();
  await evalRun({ smokeCentre: SMOKE }).step(job({ day: "2026-10-20", set: "nightly" }), c);
  const asked = new Set((c.claude.batches[0] ?? []).map((i) => i.customId.split("__")[0]));
  const kinds = new Set(loadCases(NIGHTLY_KINDS).filter((x) => asked.has(x.id)).map((x) => x.kind));
  expect([...kinds].sort()).toEqual([...NIGHTLY_KINDS].sort());
  expect(loadCases(TAP_KINDS).some((x) => asked.has(x.id))).toBe(false);
});
