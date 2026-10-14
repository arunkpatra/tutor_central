import { expect, test } from "bun:test";
import { fakeClaude } from "../src/claude-fake.js";
import type { ClaudeAnswer, ClaudeRequest } from "../src/claude.js";
import { batchDeadline, halfPriced, readBatch, sendBatch } from "../src/jobs/batch.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { costPaise } from "../src/price.js";
import { z } from "zod";

const request: ClaudeRequest<unknown> = { model: "claude-sonnet-5-5", effort: "medium", system: { shared: "rules", own: "" }, version: "1", text: "x", schema: z.object({ a: z.string() }) };
const ctx = (claude = fakeClaude({ answer: { a: "y" } })) => {
  const clock = fakeClock();
  return { db: fakeDb(), jobs: fakeJobsDb(clock), claude, clock, requestId: "r1", worker: "w1" };
};

test("a batch is sent once and read back by its ids; nothing to send sends nothing", async () => {
  const c = ctx(fakeClaude({ answer: { a: "y" } }, { batchPolls: 1 }));
  const items = [{ customId: "make_0", request }, { customId: "make_1", request }];
  const id = await sendBatch(c, items);
  expect(await readBatch(c, id, items)).toBe("running");
  const answers = await readBatch(c, id, items);
  expect(answers === "running" ? [] : [...answers.keys()]).toEqual(["make_0", "make_1"]);
  expect(await sendBatch(c, [])).toBe("");
  expect(await readBatch(c, "", [])).toEqual(new Map());
});

test("a batch's answer is priced at half and marked batched; a failed one is marked with no price", () => {
  const ok: ClaudeAnswer<unknown> = { kind: "ok", parsed: { a: "y" }, model: "claude-sonnet-5-5", tokensIn: 1000, tokensOut: 500, tokensCached: 0, tokensWritten: 0, stopReason: "end_turn", latencyMs: 0 };
  const finish = halfPriced(ok, request, "sheet@1", { a: "y" });
  expect(finish).toMatchObject({ status: "ok", batched: true, costPaise: costPaise("claude-sonnet-5-5", 1000, 500, 0, 0, 0.5) });
  const failed = halfPriced({ kind: "failed", reason: "batch errored", latencyMs: 0 }, request, "sheet@1", null);
  expect(failed).toMatchObject({ status: "failed", batched: true, costPaise: null });
});

test("the deadline is four hours after the batch was sent, and never past 90 minutes before the batch's start", () => {
  // Sent at 00:05 IST on 7 October; the batch starts at 17:00: four hours on, 04:05 IST.
  expect(batchDeadline(Date.parse("2026-10-06T18:35:00Z"), "2026-10-07", "17:00:00").toISOString()).toBe("2026-10-06T22:35:00.000Z");
  // A batch at 05:00 IST: 03:30 IST at the latest.
  expect(batchDeadline(Date.parse("2026-10-06T18:35:00Z"), "2026-10-07", "05:00:00").toISOString()).toBe("2026-10-06T22:00:00.000Z");
  // No start time: four hours.
  expect(batchDeadline(Date.parse("2026-10-06T18:35:00Z"), "2026-10-07", null).toISOString()).toBe("2026-10-06T22:35:00.000Z");
});
