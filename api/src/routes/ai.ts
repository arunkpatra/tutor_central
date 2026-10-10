import { Hono } from "hono";
import type { ZodType } from "zod";
import type { Vars } from "../auth.js";
import type { ClaudeClient, ClaudeRequest } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { type DecodedImage, decodeImage } from "../images.js";
import { request as checkRequest, schemeText } from "../prompts/check-paper.js";
import { request as homeworkRequest } from "../prompts/homework.js";
import { request as paperRequest } from "../prompts/paper.js";
import { request as noteRequest } from "../prompts/progress-note.js";
import { normalisePhone, request as scanRequest } from "../prompts/scan-register.js";
import { request as worksheetRequest } from "../prompts/worksheet.js";
import { CheckPaperInput, GenerateInput, ParseSchoolInput, type ScanOutput, ScanRegisterInput } from "../schemas.js";
import { answer, isParsed, notYet, parse, run, safeJSON } from "./common.js";
import { v2Routes } from "./v2.js";

/** The three V1 AI routes, the V2 skeletons left and the live V2 routes (routes/v2.ts). Each: validate the body, check any photo, start the record (consent, the day's limit), call
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

  // V2 (docs/spec-v2.md section 9): the contract is validated now; each route is built in its phase (13 and 14). The live
  // ones are routes/v2.ts's.
  const skeleton = <T>(path: string, schema: ZodType<T>) =>
    routes.post(path, async (c) => {
      const body = await parse(c, schema);
      if (!isParsed(body)) return body;
      return notYet(c, `/ai${path}`);
    });
  skeleton("/parse-school", ParseSchoolInput);
  routes.route("/", v2Routes(deps));

  return routes;
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
