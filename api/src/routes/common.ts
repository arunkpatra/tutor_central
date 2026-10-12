import type { Context } from "hono";
import type { ZodType } from "zod";
import type { Vars } from "../auth.js";
import type { ClaudeAnswer, ClaudeClient, ClaudeRequest } from "../claude.js";
import { type AIKind, type Db, DbFailure, type Finish, type Started } from "../db.js";
import { type ApiError, errors } from "../errors.js";
import { log } from "../log.js";
import { costPaise, promptHash as hashOf, sha256 } from "../price.js";
import { CentreInput } from "../schemas.js";

export type C = Context<Vars>;
/** One call, as a route hands it to `run`: what is recorded, what Claude is asked, and how its answer is kept. */
export type Call<T> = {
  kind: AIKind;
  input: unknown;
  request: ClaudeRequest<T>;
  keep?: (parsed: T) => T;
  /** An answer that holds nothing to use (a page with no chapters): recorded as failed and refused in words. */
  empty?: (parsed: T) => boolean;
  /** The student a personal call names: start_ai_generation asks their consent (D62); the name words a refusal. */
  student?: string;
  studentName?: string;
};

// What every AI route shares (moved from routes/ai.ts for routes/v2.ts): start the record (consent, the limit), call
// Claude, finish the record, answer `{ id, result }` or an error in words (src/errors.ts); the body's validation.

/** The Idempotency-Key the app sent (D84), when it is one a row can keep; build 26 sends none and replays nothing. */
function keyOf(c: C): string | undefined {
  const key = c.req.header("idempotency-key")?.trim();
  return key && key.length <= 200 ? key : undefined;
}

export async function run<T>(c: C, deps: { claude: ClaudeClient; db: Db }, centre: string, call: Call<T>) {
  const token = c.get("token");
  const requestId = c.get("requestId");
  let started: Started;
  try {
    started = await deps.db.startCall(token, {
      centre,
      kind: call.kind,
      input: call.input,
      model: call.request.model,
      student: call.student,
      key: keyOf(c),
      inputHash: c.get("bodyHash"),
      requestId,
    });
  } catch (e) {
    if (!(e instanceof DbFailure)) throw e;
    if (e.reason === "consent") return answer(c, errors.consent());
    if (e.reason === "student_consent") return answer(c, errors.studentConsent(call.studentName));
    if (e.reason === "limit") return answer(c, errors.limit(call.kind, e.limit ?? 0));
    if (e.reason === "not_a_member") return answer(c, errors.member());
    if (e.reason === "key_reused") return answer(c, errors.keyReused());
    return answer(c, errors.service());
  }
  const { id } = started;
  // A repeat of a call made within a day: its answer again, nothing paid; still running, the timed-out words.
  if (started.replay) {
    if (started.status === "ok" && started.output !== null) {
      log.info({ requestId, route: c.req.path, generation: id, replay: true });
      return c.json({ id, result: JSON.parse(started.output) }, 200, { "Idempotent-Replayed": "true" });
    }
    return answer(c, errors.inProgress());
  }
  const result = await deps.claude.complete(call.request);
  const outcome = finishOf(call, result);
  await deps.db.finish(token, id, outcome.finish);
  if (outcome.kept !== undefined) return c.json({ id, result: outcome.kept }, 200);
  return answer(c, result.kind === "truncated" || result.kind === "failed" ? errors.service() : errors.refused(call.kind));
}

/** How a call's answer finishes its row (D76), for a route and a job alike: an answer kept (`kept`), or the row failed
 *  with its reason, with the billed tokens of every answer that came back and the cost they priced. */
export function finishOf<T>(
  call: Pick<Call<T>, "request" | "keep" | "empty">,
  result: ClaudeAnswer<T>,
): { finish: Finish; kept?: T } {
  const finishedAt = new Date().toISOString();
  const promptHash = hashOf(call.request.system);
  if (result.kind === "failed") {
    return {
      finish: {
        status: "failed",
        output: null,
        model: call.request.model,
        tokensIn: null,
        tokensOut: null,
        costPaise: null,
        latencyMs: result.latencyMs,
        promptHash,
        stopReason: null,
        errorReason: result.reason,
        finishedAt,
      },
    };
  }
  const billed = {
    model: result.model,
    tokensIn: result.tokensIn,
    tokensOut: result.tokensOut,
    costPaise: costPaise(result.model, result.tokensIn, result.tokensOut),
    latencyMs: result.latencyMs,
    promptHash,
    stopReason: result.stopReason,
    finishedAt,
  };
  if (result.kind === "ok" && !call.empty?.(result.parsed)) {
    const kept = call.keep ? call.keep(result.parsed) : result.parsed;
    return { finish: { status: "ok", output: JSON.stringify(kept), ...billed, errorReason: null }, kept };
  }
  // Cut at max_tokens: a service failure, never a refusal of the topic (decision 11; the repair comes in Phase 20).
  const errorReason = result.kind === "truncated" ? "truncated" : result.kind === "refused" ? result.reason : "refused";
  return { finish: { status: "failed", output: null, ...billed, errorReason } };
}

export type Parsed<T> = { value: T; centre: string };

/** The body validated: the route's schema and the centre; 400 with the issues otherwise. */
export async function parse<T>(c: C, schema: ZodType<T>): Promise<Parsed<T> | Response> {
  // The raw body is read once: its hash is the key's check (a key reused with another body, D84).
  const raw = await c.req.text().catch(() => "");
  c.set("bodyHash", sha256(raw));
  const body: unknown = safeJSON(raw) ?? undefined;
  const parsed = schema.safeParse(body);
  const centre = CentreInput.safeParse(body);
  const issues = [...(parsed.success ? [] : parsed.error.issues), ...(centre.success ? [] : centre.error.issues)];
  if (!parsed.success || !centre.success) {
    const words = issues.map((i) => (i.path.length ? `${i.path.join(".")}: ${i.message}` : i.message));
    return c.json({ error: words.join("; "), reason: "invalid" }, 400);
  }
  c.set("centreId", centre.data.centreId);
  return { value: parsed.data, centre: centre.data.centreId };
}

export function isParsed<T>(body: Parsed<T> | Response): body is Parsed<T> {
  return !(body instanceof Response);
}

export function answer(c: C, e: ApiError) {
  return c.json(e.body, e.status);
}

export function safeJSON(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}
