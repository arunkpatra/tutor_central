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
  expect(answer).toMatchObject({ kind: "failed", reason: "timeout" });
  expect(Date.now() - started).toBeLessThan(2000);
  expect(calls).toBe(1);
});

test("the deadline ends before the app stops waiting (APIClient.timeout, 125 s)", () => {
  expect(CLAUDE_DEADLINE_MS).toBeLessThan(125_000);
});

/** A Messages API answer, as the SDK reads it from the wire. */
const reply = (text: string, stop: string, usage = { input_tokens: 120, output_tokens: 45 }) =>
  (async () =>
    Response.json({
      id: "msg_1",
      type: "message",
      role: "assistant",
      model: "claude-sonnet-5-5",
      content: text ? [{ type: "text", text }] : [],
      stop_reason: stop,
      stop_sequence: null,
      usage,
    })) as unknown as typeof fetch;

test("an answer carries its tokens, stop reason and latency", async () => {
  const answer = await anthropicClaude("sk-test", { fetch: reply('{"a":"x"}', "end_turn") }).complete(request);
  expect(answer).toMatchObject({ kind: "ok", parsed: { a: "x" }, model: "claude-sonnet-5-5", tokensIn: 120, tokensOut: 45, stopReason: "end_turn" });
  expect(answer.latencyMs).toBeGreaterThanOrEqual(0);
});

test("a refusal carries its tokens", async () => {
  const answer = await anthropicClaude("sk-test", { fetch: reply("", "refusal", { input_tokens: 90, output_tokens: 3 }) }).complete(request);
  expect(answer).toMatchObject({ kind: "refused", reason: "refused", tokensIn: 90, tokensOut: 3, stopReason: "refusal" });
});

test("an answer that does not fit the schema is refused as unfit, with its tokens", async () => {
  const answer = await anthropicClaude("sk-test", { fetch: reply('{"b":1}', "end_turn") }).complete(request);
  expect(answer).toMatchObject({ kind: "refused", reason: "unfit", tokensIn: 120, tokensOut: 45 });
  const notJson = await anthropicClaude("sk-test", { fetch: reply("not json", "end_turn") }).complete(request);
  expect(notJson).toMatchObject({ kind: "refused", reason: "unfit", tokensIn: 120 });
});

test("max_tokens is truncated, with its tokens, never a refusal", async () => {
  const answer = await anthropicClaude("sk-test", { fetch: reply('{"a":"cut', "max_tokens", { input_tokens: 100, output_tokens: 16000 }) }).complete(request);
  expect(answer).toMatchObject({ kind: "truncated", tokensIn: 100, tokensOut: 16000, stopReason: "max_tokens" });
});

test("an API error is failed with its status and no tokens", async () => {
  const down = (async () => Response.json({ type: "error", error: { type: "invalid_request_error", message: "no" } }, { status: 400 })) as unknown as typeof fetch;
  const answer = await anthropicClaude("sk-test", { fetch: down }).complete(request);
  expect(answer).toMatchObject({ kind: "failed", reason: "api 400" });
});
