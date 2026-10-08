import { expect, test } from "bun:test";
import { z } from "zod";
import { fakeClaude, SAMPLE } from "../src/claude-fake.js";
import { PaperOutput } from "../src/schemas.js";

const request = { model: "claude-sonnet-5-5" as const, effort: "medium" as const, system: "s", text: "t", schema: PaperOutput };

test("the fake answers what its script says and records the request", async () => {
  const ok = fakeClaude({ answer: SAMPLE.paper });
  const r = await ok.complete(request);
  expect(r.kind).toBe("ok");
  if (r.kind === "ok") expect(r.parsed.title).toBe("Quadratic equations");
  expect(ok.requests).toHaveLength(1);
  expect((await fakeClaude({ refuse: true }).complete(request)).kind).toBe("refused");
  const failed = await fakeClaude({ fail: "timeout" }).complete(request);
  expect(failed).toEqual({ kind: "failed", reason: "timeout" });
});

test("the fake's sample answers fit their schemas", () => {
  expect(PaperOutput.safeParse(SAMPLE.paper).success).toBe(true);
  expect(z.object({ note: z.string() }).safeParse(SAMPLE.progress_note).success).toBe(true);
});

test("a script can depend on the request", async () => {
  const byModel = fakeClaude((r) => (r.model === "claude-opus-5-5" ? { answer: SAMPLE.scan_register } : { refuse: true }));
  expect((await byModel.complete({ ...request, model: "claude-opus-5-5", schema: z.any() })).kind).toBe("ok");
  expect((await byModel.complete(request)).kind).toBe("refused");
});
