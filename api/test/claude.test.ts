import { expect, test } from "bun:test";
import { z } from "zod";
import { CLAUDE_DEADLINE_MS, anthropicClaude } from "../src/claude.js";

const request = {
  model: "claude-sonnet-5-5" as const,
  effort: "medium" as const,
  system: "s",
  text: "t",
  schema: z.object({ a: z.string() }),
};

test("a call that does not answer is given up at one deadline across its tries, as a timeout", async () => {
  let calls = 0;
  const hang = ((_url: unknown, init?: RequestInit) => {
    calls += 1;
    return new Promise<Response>((_, reject) =>
      init?.signal?.addEventListener("abort", () => reject(new DOMException("aborted", "AbortError"))),
    );
  }) as typeof fetch;
  const started = Date.now();
  const answer = await anthropicClaude("sk-test", { fetch: hang, deadlineMs: 50 }).complete(request);
  expect(answer).toEqual({ kind: "failed", reason: "timeout" });
  expect(Date.now() - started).toBeLessThan(2000);
  expect(calls).toBe(1);
});

test("the deadline ends before the app stops waiting (APIClient.timeout, 125 s)", () => {
  expect(CLAUDE_DEADLINE_MS).toBeLessThan(125_000);
});
