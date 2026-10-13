// Named, not the default export: Vercel's build resolves the SDK's CommonJS types, where the default import is only
// the module's namespace (deploy run 37829835784).
import { Anthropic } from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import type { ZodType } from "zod";
import { log } from "./log.js";

export type ImageInput = { mediaType: "image/jpeg" | "image/png" | "image/webp"; base64: string };
export type ClaudeRequest<T> = {
  model: "claude-haiku-5-5" | "claude-sonnet-5-5" | "claude-opus-5-5";
  effort: "low" | "medium" | "high";
  system: string;
  /** The user turn's text, after the images. */
  text: string;
  /** Labelled "Page 1:" and so on, before the text. */
  images?: ImageInput[];
  /** The structured output Claude is held to. */
  schema: ZodType<T>;
};
/** What came back, with what the row records (D76): billed tokens on every answer that came back, a refusal and an unfit
 *  one included; `truncated` is an answer cut at max_tokens, a service failure and never a refusal of the topic. */
type Answered = { model: string; tokensIn: number; tokensOut: number; stopReason: string | null; latencyMs: number };
export type ClaudeAnswer<T> =
  | ({ kind: "ok"; parsed: T } & Answered)
  | ({ kind: "refused"; reason: "refused" | "unfit" } & Answered)
  | ({ kind: "truncated" } & Answered)
  | { kind: "failed"; reason: string; latencyMs: number };
export type ClaudeClient = { complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> };

/** How long one request may take, its retry included: under the app's 125 s (`APIClient.timeout`), so the API
 *  answers 502 and marks the row failed before the app gives up on it. */
export const CLAUDE_DEADLINE_MS = 110_000;

/** One call per request: images first ("Page 1:" and so on), then the text. The answer's text is parsed against the
 *  schema here (not by the SDK's `parse`), so the usage and the stop reason are known for every answer that came back
 *  (plan decision 11): a refusal or an answer that does not fit is "refused" with its tokens; max_tokens is
 *  "truncated"; anything the SDK throws is "failed" in a word, with no tokens. No fallbacks: one model per route. */
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
      const started = performance.now();
      const elapsed = () => Math.round(performance.now() - started);
      try {
        const response = await client.messages.create(
          {
            model: request.model,
            max_tokens: 16000,
            system: request.system,
            output_config: { effort: request.effort, format: zodOutputFormat(request.schema) },
            messages: [{ role: "user", content }],
          },
          { signal: AbortSignal.timeout(deadline) },
        );
        const answered: Answered = {
          model: response.model,
          tokensIn: response.usage.input_tokens,
          tokensOut: response.usage.output_tokens,
          stopReason: response.stop_reason,
          latencyMs: elapsed(),
        };
        if (response.stop_reason === "refusal") return { kind: "refused", reason: "refused", ...answered };
        if (response.stop_reason === "max_tokens") return { kind: "truncated", ...answered };
        const text = response.content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("");
        const parsed = request.schema.safeParse(json(text));
        if (!parsed.success) {
          log.error({ at: "claude", reason: "unfit", message: parsed.error.message.slice(0, 500) });
          return { kind: "refused", reason: "unfit", ...answered };
        }
        return { kind: "ok", parsed: parsed.data, ...answered };
      } catch (e) {
        if (e instanceof Anthropic.APIConnectionTimeoutError || e instanceof Anthropic.APIUserAbortError) {
          return failed("timeout", e, elapsed());
        }
        if (e instanceof Anthropic.APIError) return failed(`api ${e.status}`, e, elapsed());
        return failed("error", e, elapsed());
      }
    },
  };
}

function json(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
}

function failed(reason: string, e: unknown, latencyMs: number): { kind: "failed"; reason: string; latencyMs: number } {
  log.error({ at: "claude", reason, error: e instanceof Error ? e : String(e) });
  return { kind: "failed", reason, latencyMs };
}
