import { expect, test } from "bun:test";
import { fakeDb } from "../src/db-fake.js";
import { DbFailure } from "../src/db.js";

test("the fake db starts, finishes and refuses as the function would", async () => {
  const db = fakeDb({ consent: false });
  const { id } = await db.startCall("tok", { centre: "c", kind: "paper", input: {}, model: "m" });
  expect(db.started).toHaveLength(1);
  await db.finish("tok", id, { status: "ok", output: "{}", model: "m", tokensIn: 1, tokensOut: 2, costPaise: 0, latencyMs: 5, promptHash: "h", promptVersion: "sheet@2", fallbackModel: null, tokensCached: null, stopReason: "end_turn", errorReason: null, finishedAt: "2026-10-12T00:00:00Z" });
  expect(db.finished[0]).toMatchObject({ id, status: "ok" });
  await expect(db.startCall("tok", { centre: "c", kind: "scan_register", input: {}, model: "m" })).rejects.toBeInstanceOf(DbFailure);
  const limited = fakeDb({ limit: 0 });
  const err = await limited.startCall("tok", { centre: "c", kind: "paper", input: {}, model: "m" }).catch((e) => e as DbFailure);
  expect(err).toMatchObject({ reason: "limit", limit: 0 });
  const withPaper = fakeDb({ generations: { g1: { kind: "paper", output: '{"title":"x"}' } } });
  expect(await withPaper.generation("tok", "g1")).toEqual({ id: "g1", kind: "paper", output: '{"title":"x"}' });
  expect(await withPaper.generation("tok", "nope")).toBeNull();
});
