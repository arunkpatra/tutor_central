// Named, not the default export: Vercel's build resolves the SDK's CommonJS types, where the default import is only
// the module's namespace (deploy run 37829835784).
import { Anthropic } from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import type { ZodType } from "zod";

export type ImageInput = { mediaType: "image/jpeg" | "image/png" | "image/webp"; base64: string };
export type ClaudeRequest<T> = {
  model: "claude-haiku-5-5" | "claude-sonnet-5-5" | "claude-opus-5-5";
  effort: "medium" | "high";
  system: string;
  /** The user turn's text, after the images. */
  text: string;
  /** Labelled "Page 1:" and so on, before the text. */
  images?: ImageInput[];
  /** The structured output Claude is held to. */
  schema: ZodType<T>;
};
export type ClaudeAnswer<T> =
  | { kind: "ok"; parsed: T; model: string; tokensIn: number; tokensOut: number }
  | { kind: "refused"; model: string; tokensIn: number | null; tokensOut: number | null }
  | { kind: "failed"; reason: string };
export type ClaudeClient = { complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> };

/** How long one request may take, its retry included: under the app's 125 s (`APIClient.timeout`), so the API
 *  answers 502 and marks the row failed before the app gives up on it. */
export const CLAUDE_DEADLINE_MS = 110_000;

/** One call per request: images first ("Page 1:" and so on), then the text; the answer parsed against the schema. A
 *  refusal (stop_reason), or an answer that did not fit the schema (the SDK throws before the stop reason can be read),
 *  is "refused"; anything else the SDK throws is "failed" in a word. No fallbacks: one model per route, a predictable
 *  cost (plan/phase-06-plan.md, the decisions table). */
export function anthropicClaude(
  apiKey: string,
  options: { deadlineMs?: number; fetch?: typeof fetch } = {},
): ClaudeClient {
  const deadline = options.deadlineMs ?? CLAUDE_DEADLINE_MS;
  // One try may last the whole deadline; the signal ends both tries together, so a retry only follows a quick failure.
  const client = new Anthropic({ apiKey, timeout: deadline + 1_000, maxRetries: 1, fetch: options.fetch });
  return {
    async complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> {
      const content: Anthropic.ContentBlockParam[] = [];
      (request.images ?? []).forEach((image, i) => {
        content.push({ type: "text", text: `Page ${i + 1}:` });
        content.push({ type: "image", source: { type: "base64", media_type: image.mediaType, data: image.base64 } });
      });
      content.push({ type: "text", text: request.text });
      try {
        const response = await client.messages.parse({
          model: request.model,
          max_tokens: 16000,
          system: request.system,
          output_config: { effort: request.effort, format: zodOutputFormat(request.schema) },
          messages: [{ role: "user", content }],
        }, { signal: AbortSignal.timeout(deadline) });
        const tokens = { tokensIn: response.usage.input_tokens, tokensOut: response.usage.output_tokens };
        if (response.stop_reason === "refusal" || response.parsed_output == null) {
          return { kind: "refused", model: response.model, ...tokens };
        }
        return { kind: "ok", parsed: response.parsed_output as T, model: response.model, ...tokens };
      } catch (e) {
        if (e instanceof Anthropic.APIConnectionTimeoutError || e instanceof Anthropic.APIUserAbortError) {
          return failed("timeout", e);
        }
        if (e instanceof Anthropic.APIError) return failed(`api ${e.status}`, e);
        if (e instanceof Anthropic.AnthropicError && e.message.startsWith("Failed to parse structured output")) {
          console.error("claude", "unfit answer", e.message);
          return { kind: "refused", model: request.model, tokensIn: null, tokensOut: null };
        }
        return failed("error", e);
      }
    },
  };
}

function failed(reason: string, e: unknown): { kind: "failed"; reason: string } {
  console.error("claude", reason, e instanceof Error ? e.message : String(e));
  return { kind: "failed", reason };
}
