import type { Context } from "hono";
import type { ZodType } from "zod";
import type { Vars } from "../auth.js";
import { type AgentOutcome, fromRequest, type Kind, runAgent } from "../agents/agent.js";
import type { ClaudeClient, ClaudeRequest } from "../claude.js";
import { type AIKind, type Db, DbFailure } from "../db.js";
import { type ApiError, errors } from "../errors.js";
import { log } from "../log.js";
import { sha256 } from "../price.js";
import { CentreInput } from "../schemas.js";

export type C = Context<Vars>;

// What every AI route shares (moved from routes/ai.ts for routes/v2.ts): the kind run by its agent (src/agents/agent.ts:
// the consent and the limit at the gate, the draft, the checks, the repair), answered `{ id, result }` or an error in
// words (src/errors.ts); the body's validation.

/** The Idempotency-Key the app sent (D84), when it is one a row can keep. A request without one gets a fresh key: its
 *  agent's steps hang off it (0052) and it replays nothing. */
function keyOf(c: C): string {
  const key = c.req.header("idempotency-key")?.trim();
  return key && key.length <= 160 ? key : `call:${crypto.randomUUID()}`;
}

export async function run<I, T>(c: C, deps: { claude: ClaudeClient; db: Db }, centre: string, spec: Kind<I, T>, input: I, recorded: unknown = input) {
  const token = c.get("token");
  const requestId = c.get("requestId");
  let outcome: AgentOutcome<T>;
  try {
    outcome = await runAgent({ db: deps.db, claude: deps.claude, token, requestId, centre, key: keyOf(c), inputHash: c.get("bodyHash") ?? "" }, spec, input, recorded);
  } catch (e) {
    if (!(e instanceof DbFailure)) throw e;
    if (e.reason === "consent") return answer(c, errors.consent());
    if (e.reason === "student_consent") return answer(c, errors.studentConsent(spec.student?.(input)?.name));
    if (e.reason === "limit") return answer(c, errors.limit(spec.kind, e.limit ?? 0));
    if (e.reason === "not_a_member") return answer(c, errors.member());
    if (e.reason === "key_reused") return answer(c, errors.keyReused());
    return answer(c, errors.service());
  }
  if (outcome.kind === "paused") return answer(c, errors.paused(spec.kind));
  // A repeat of a call made within a day: its answer again, nothing paid; still running, the timed-out words.
  if (outcome.kind === "pending") return answer(c, errors.inProgress());
  if (outcome.kind === "failed") return answer(c, outcome.words === "service" ? errors.service() : errors.refused(spec.kind));
  if (outcome.replay) {
    log.info({ requestId, route: c.req.path, generation: outcome.id, replay: true });
    return c.json({ id: outcome.id, result: outcome.parsed }, 200, { "Idempotent-Replayed": "true" });
  }
  return c.json({ id: outcome.id, result: outcome.parsed }, 200);
}

/** A call of a kind not moved onto its own agent (V1's, the readers until Task 6): the request drafted alone. */
export type Call<T> = {
  kind: AIKind;
  input: unknown;
  request: ClaudeRequest<T>;
  keep?: (parsed: T) => T;
  /** An answer that holds nothing to use (a page with no chapters): recorded as failed and refused in words. */
  empty?: (parsed: T) => boolean;
  /** The student a personal call names: the gate asks their consent (D62); the name words a refusal. */
  student?: string;
  studentName?: string;
};

export function runCall<T>(c: C, deps: { claude: ClaudeClient; db: Db }, centre: string, call: Call<T>) {
  const spec = fromRequest(call.kind, call.request, { student: call.student, studentName: call.studentName, empty: call.empty, keep: call.keep });
  return run(c, deps, centre, spec, undefined, call.input);
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
