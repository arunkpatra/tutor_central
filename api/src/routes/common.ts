import type { Context } from "hono";
import type { ZodType } from "zod";
import type { Vars } from "../auth.js";
import type { ClaudeClient, ClaudeRequest } from "../claude.js";
import { type AIKind, type Db, DbFailure } from "../db.js";
import { type ApiError, errors } from "../errors.js";
import { CentreInput } from "../schemas.js";

export type C = Context<Vars>;
/** One call, as a route hands it to `run`: what is recorded, what Claude is asked, and how its answer is kept. */
export type Call<T> = { kind: AIKind; input: unknown; request: ClaudeRequest<T>; keep?: (parsed: T) => T };

// What every AI route shares (moved from routes/ai.ts for routes/v2.ts): start the record (consent, the limit), call
// Claude, finish the record, answer `{ id, result }` or an error in words (src/errors.ts); the body's validation.

/** A route whose phase has not come. */
export function notYet(c: C, route: string) {
  return c.json({ error: "not yet", route }, 501);
}

export async function run<T>(c: C, deps: { claude: ClaudeClient; db: Db }, centre: string, call: Call<T>) {
  const token = c.get("token");
  let id: string;
  try {
    id = await deps.db.start(token, { centre, kind: call.kind, input: call.input, model: call.request.model });
  } catch (e) {
    if (!(e instanceof DbFailure)) throw e;
    if (e.reason === "consent") return answer(c, errors.consent());
    if (e.reason === "limit") return answer(c, errors.limit(call.kind, e.limit ?? 0));
    if (e.reason === "not_a_member") return answer(c, errors.member());
    return answer(c, errors.service());
  }
  const result = await deps.claude.complete(call.request);
  if (result.kind === "ok") {
    const kept = call.keep ? call.keep(result.parsed) : result.parsed;
    const tokens = { tokensIn: result.tokensIn, tokensOut: result.tokensOut };
    await deps.db.finish(token, id, { status: "ok", output: JSON.stringify(kept), model: result.model, ...tokens });
    return c.json({ id, result: kept }, 200);
  }
  if (result.kind === "refused") {
    const tokens = { tokensIn: result.tokensIn, tokensOut: result.tokensOut };
    await deps.db.finish(token, id, { status: "failed", output: null, model: result.model, ...tokens });
    return answer(c, errors.refused(call.kind));
  }
  const failed = { status: "failed" as const, output: null, model: call.request.model, tokensIn: null, tokensOut: null };
  await deps.db.finish(token, id, failed);
  return answer(c, errors.service());
}

export type Parsed<T> = { value: T; centre: string };

/** The body validated: the route's schema and the centre; 400 with the issues otherwise. */
export async function parse<T>(c: C, schema: ZodType<T>): Promise<Parsed<T> | Response> {
  const body: unknown = await c.req.json().catch(() => undefined);
  const parsed = schema.safeParse(body);
  const centre = CentreInput.safeParse(body);
  const issues = [...(parsed.success ? [] : parsed.error.issues), ...(centre.success ? [] : centre.error.issues)];
  if (!parsed.success || !centre.success) {
    const words = issues.map((i) => (i.path.length ? `${i.path.join(".")}: ${i.message}` : i.message));
    return c.json({ error: words.join("; ") }, 400);
  }
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
