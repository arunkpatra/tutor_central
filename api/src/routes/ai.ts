import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient, ClaudeRequest } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { type DecodedImage, decodeImage } from "../images.js";
import { request as checkRequest, schemeText } from "../prompts/check-paper.js";
import { request as homeworkRequest } from "../prompts/homework.js";
import { request as paperRequest } from "../prompts/paper.js";
import { request as parseSchoolRequest } from "../prompts/parse-school.js";
import { request as noteRequest } from "../prompts/progress-note.js";
import { normalisePhone, request as scanRequest } from "../prompts/scan-register.js";
import { request as worksheetRequest } from "../prompts/worksheet.js";
import { CheckPaperInput, GenerateInput, ParseSchoolInput, type ScanOutput, ScanRegisterInput } from "../schemas.js";
import { answer, isParsed, parse, run, safeJSON } from "./common.js";
import { v2Routes } from "./v2.js";

/** The three V1 AI routes, `/parse-school` and the other live V2 routes (routes/v2.ts). Each: validate the body, check any photo, start the record (consent, the day's limit), call
 *  Claude, finish the record, answer `{ id, result }` or an error in words (src/errors.ts). Photos are never stored:
 *  the record's input holds the page count and the bytes (docs/spec.md section 6). */
export function aiRoutes(deps: { claude: ClaudeClient; db: Db }) {
  const routes = new Hono<Vars>();

  routes.post("/generate", async (c) => {
    const body = await parse(c, GenerateInput);
    if (!isParsed(body)) return body;
    const request = generateRequest(body.value);
    // A progress note is about one student: the gate asks their parent's consent (D62, migration 0027).
    const student = body.value.kind === "progress_note" ? body.value.studentId : undefined;
    const studentName = body.value.kind === "progress_note" ? body.value.studentName : undefined;
    return run(c, deps, body.centre, { kind: body.value.kind, input: body.value, request, student, studentName });
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
    const { scheme, studentName, studentId } = body.value;
    let text: string | null = scheme.kind === "typed" ? scheme.text : null;
    if (scheme.kind === "paper") {
      const stored = await deps.db.generation(c.get("token"), scheme.generationId);
      text = stored?.output ? schemeText(safeJSON(stored.output), stored.kind) : null;
      if (!text) return answer(c, errors.badImage("That paper is no longer here. Type the scheme instead."));
    }
    if (scheme.kind === "mock") {
      // A mock's key is its generation's output, the one table the API reads (plan/phase-13-plan.md decision 13).
      const stored = await deps.db.generation(c.get("token"), scheme.generationId);
      text = stored?.kind === "mock" && stored.output ? schemeText(safeJSON(stored.output), "mock") : null;
      if (!text) return answer(c, errors.badImage("That mock is no longer here. Type the scheme instead."));
    }
    const input = {
      kind: "check_paper",
      pages: pages.length,
      bytes: pages.reduce((n, p) => n + p.bytes, 0),
      scheme: scheme.kind === "typed" ? { kind: "typed" } : { kind: scheme.kind, generationId: scheme.generationId },
      studentName,
    };
    // A paper marked for a named student (a mock) needs that student's consent (D62, migration 0021).
    const request = checkRequest(pages, text ?? "", studentName);
    return run(c, deps, body.centre, { kind: "check_paper", input, request, student: studentId, studentName });
  });

  routes.post("/parse-school", async (c) => {
    const body = await parse(c, ParseSchoolInput);
    if (!isParsed(body)) return body;
    let image: DecodedImage | null = null;
    if (body.value.image) {
      const decoded = decodeImage(body.value.image);
      if (typeof decoded === "string") return answer(c, errors.badImage(decoded));
      image = decoded;
    }
    const { text, today, schools = [], classLevels = [] } = body.value;
    // The message's words are not recorded: the record holds how much came and how.
    const input = image
      ? { kind: "parse_school", source: "photo", pages: 1, bytes: image.bytes, characters: 0 }
      : { kind: "parse_school", source: "text", pages: 0, characters: [...(text ?? "")].length };
    const request = parseSchoolRequest({ text: text ?? null, image, today, schools, classLevels });
    return run(c, deps, body.centre, { kind: "parse_school", input, request, empty: (read) => read.items.length === 0 });
  });

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
