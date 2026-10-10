import { type Context, Hono } from "hono";
import type { ZodType } from "zod";
import type { Vars } from "../auth.js";
import type { ClaudeClient, ClaudeRequest } from "../claude.js";
import { type AIKind, type Db, DbFailure } from "../db.js";
import { type ApiError, errors } from "../errors.js";
import { type DecodedImage, decodeImage } from "../images.js";
import { request as checkRequest, schemeText } from "../prompts/check-paper.js";
import { request as homeworkRequest } from "../prompts/homework.js";
import { request as paperRequest } from "../prompts/paper.js";
import { request as noteRequest } from "../prompts/progress-note.js";
import { normalisePhone, request as scanRequest } from "../prompts/scan-register.js";
import { request as worksheetRequest } from "../prompts/worksheet.js";
import {
  CentreInput,
  CheckPaperInput,
  GenerateInput,
  MakeInput,
  ParseSchoolInput,
  ParseTextbookInput,
  PlanInput,
  type ScanOutput,
  ScanRegisterInput,
} from "../schemas.js";

type C = Context<Vars>;
/** One call, as a route hands it to `run`: what is recorded, what Claude is asked, and how its answer is kept. */
type Call<T> = { kind: AIKind; input: unknown; request: ClaudeRequest<T>; keep?: (parsed: T) => T };

/** The three V1 AI routes and the V2 skeletons. Each: validate the body, check any photo, start the record (consent, the day's limit), call
 *  Claude, finish the record, answer `{ id, result }` or an error in words (src/errors.ts). Photos are never stored:
 *  the record's input holds the page count and the bytes (docs/spec.md section 6). */
export function aiRoutes(deps: { claude: ClaudeClient; db: Db }) {
  const routes = new Hono<Vars>();

  routes.post("/generate", async (c) => {
    const body = await parse(c, GenerateInput);
    if (!isParsed(body)) return body;
    const request = generateRequest(body.value);
    return run(c, deps, body.centre, { kind: body.value.kind, input: body.value, request });
  });

  routes.post("/scan-register", async (c) => {
    const body = await parse(c, ScanRegisterInput);
    if (!isParsed(body)) return body;
    const image = decodeImage(body.value);
    if (typeof image === "string") return answer(c, errors.badImage(image));
    const keep = (parsed: ScanOutput): ScanOutput => ({
      rows: parsed.rows.map((row) => ({ ...row, phone: normalisePhone(row.phone) })),
    });
    const input = { kind: "scan_register", pages: 1, bytes: image.bytes };
    return run(c, deps, body.centre, { kind: "scan_register", input, request: scanRequest(image), keep });
  });

  routes.post("/check-paper", async (c) => {
    const body = await parse(c, CheckPaperInput);
    if (!isParsed(body)) return body;
    const pages: DecodedImage[] = [];
    for (const page of body.value.pages) {
      const image = decodeImage(page);
      if (typeof image === "string") return answer(c, errors.badImage(image));
      pages.push(image);
    }
    const { scheme, studentName } = body.value;
    if (scheme.kind === "mock") return notYet(c, "/ai/check-paper");
    let text: string | null = scheme.kind === "typed" ? scheme.text : null;
    if (scheme.kind === "paper") {
      const stored = await deps.db.generation(c.get("token"), scheme.generationId);
      text = stored?.output ? schemeText(safeJSON(stored.output), stored.kind) : null;
      if (!text) return answer(c, errors.badImage("That paper is no longer here. Type the scheme instead."));
    }
    const input = {
      kind: "check_paper",
      pages: pages.length,
      bytes: pages.reduce((n, p) => n + p.bytes, 0),
      scheme: scheme.kind === "paper" ? { kind: "paper", generationId: scheme.generationId } : { kind: "typed" },
      studentName,
    };
    return run(c, deps, body.centre, { kind: "check_paper", input, request: checkRequest(pages, text ?? "", studentName) });
  });

  // V2 (docs/spec-v2.md section 9): the contract is validated now; each route is built in its phase (11 to 14).
  const skeleton = <T>(path: string, schema: ZodType<T>) =>
    routes.post(path, async (c) => {
      const body = await parse(c, schema);
      if (!isParsed(body)) return body;
      return notYet(c, `/ai${path}`);
    });
  skeleton("/plan", PlanInput);
  skeleton("/make", MakeInput);
  skeleton("/parse-school", ParseSchoolInput);
  skeleton("/parse-textbook", ParseTextbookInput);

  return routes;
}

function notYet(c: C, route: string) {
  return c.json({ error: "not yet", route }, 501);
}

function generateRequest(input: GenerateInput): ClaudeRequest<unknown> {
  switch (input.kind) {
    case "paper":
      return paperRequest(input) as ClaudeRequest<unknown>;
    case "homework":
      return homeworkRequest(input) as ClaudeRequest<unknown>;
    case "worksheet":
      return worksheetRequest(input) as ClaudeRequest<unknown>;
    case "progress_note":
      return noteRequest(input) as ClaudeRequest<unknown>;
  }
}

async function run<T>(c: C, deps: { claude: ClaudeClient; db: Db }, centre: string, call: Call<T>) {
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

type Parsed<T> = { value: T; centre: string };

/** The body validated: the route's schema and the centre; 400 with the issues otherwise. */
async function parse<T>(c: C, schema: ZodType<T>): Promise<Parsed<T> | Response> {
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

function isParsed<T>(body: Parsed<T> | Response): body is Parsed<T> {
  return !(body instanceof Response);
}

function answer(c: C, e: ApiError) {
  return c.json(e.body, e.status);
}

function safeJSON(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}
