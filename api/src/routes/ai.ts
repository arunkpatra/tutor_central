import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { type DecodedImage, decodeImage } from "../images.js";
import { schemeQuestions, schemeText } from "../prompts/check-paper.js";
import type { Kind } from "../agents/agent.js";
import { checkPaper, homework, paper, parseSchool, progressNote, scanRegister, worksheet } from "../agents/kinds/index.js";
import type { JobsDb } from "../jobs/types.js";
import { log } from "../log.js";
import { CheckPaperInput, GenerateInput, ParseSchoolInput, ScanRegisterInput } from "../schemas.js";
import { answer, isParsed, parse, run, safeJSON } from "./common.js";
import { v2Routes } from "./v2.js";

/** The three V1 AI routes, `/parse-school` and the other live V2 routes (routes/v2.ts). Each: validate the body, check any photo, start the record (consent, the day's limit), call
 *  Claude, finish the record, answer `{ id, result }` or an error in words (src/errors.ts). Photos are never stored:
 *  the record's input holds the page count and the bytes (docs/spec.md section 6). */
export function aiRoutes(deps: { claude: ClaudeClient; db: Db; worker?: { jobs: Pick<JobsDb, "enqueue"> } }) {
  const routes = new Hono<Vars>();

  routes.post("/generate", async (c) => {
    const body = await parse(c, GenerateInput);
    if (!isParsed(body)) return body;
    const v = body.value;
    // A progress note is about one student: its agent names them, so the gate asks their parent's consent (D62, 0027).
    if (v.kind === "progress_note") return run(c, deps, body.centre, progressNote, v);
    // A paper, homework or worksheet kept: its PDF is made on the server (Phase 21 decision 9), queued as the platform.
    const spec = ({ paper, homework, worksheet } as Record<string, Kind<unknown, unknown>>)[v.kind] as Kind<unknown, unknown>;
    return run(c, deps, body.centre, spec, v, v, (id) => queuePdf(deps.worker?.jobs, body.centre, id, c.get("requestId")));
  });

  routes.post("/scan-register", async (c) => {
    const body = await parse(c, ScanRegisterInput);
    if (!isParsed(body)) return body;
    const image = decodeImage(body.value);
    if (typeof image === "string") return answer(c, errors.badImage(image));
    // The photo is read and dropped: the record holds its size.
    return run(c, deps, body.centre, scanRegister, { image }, { kind: "scan_register", pages: 1, bytes: image.bytes });
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
    // A stored paper's or mock's questions and marks hold the marking's free check (Phase 21); a typed scheme has none.
    let questions: { number: number; marks: number }[] = [];
    if (scheme.kind === "paper") {
      const stored = await deps.db.generation(c.get("token"), scheme.generationId);
      text = stored?.output ? schemeText(safeJSON(stored.output), stored.kind) : null;
      if (!text) return answer(c, errors.badImage("That paper is no longer here. Type the scheme instead."));
      questions = stored?.output ? schemeQuestions(safeJSON(stored.output), stored.kind) : [];
    }
    if (scheme.kind === "mock") {
      // A mock's key is its generation's output, the one table the API reads (plan/phase-13-plan.md decision 13).
      const stored = await deps.db.generation(c.get("token"), scheme.generationId);
      text = stored?.kind === "mock" && stored.output ? schemeText(safeJSON(stored.output), "mock") : null;
      if (!text) return answer(c, errors.badImage("That mock is no longer here. Type the scheme instead."));
      questions = stored?.output ? schemeQuestions(safeJSON(stored.output), "mock") : [];
    }
    const input = {
      kind: "check_paper",
      pages: pages.length,
      bytes: pages.reduce((n, p) => n + p.bytes, 0),
      scheme: scheme.kind === "typed" ? { kind: "typed" } : { kind: scheme.kind, generationId: scheme.generationId },
      studentName,
    };
    // A paper marked for a named student (a mock) needs that student's consent (D62, migration 0021).
    return run(c, deps, body.centre, checkPaper, { pages, scheme: text ?? "", schemeQuestions: questions, studentName, studentId }, input);
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
    return run(c, deps, body.centre, parseSchool, { text: text ?? null, image, today, schools, classLevels }, input);
  });

  routes.route("/", v2Routes(deps));

  return routes;
}

/** A V1 result's PDF queued once by its generation (`pdf:gen:<id>`); a queue that fails is logged, and Share draws on the
 *  phone meanwhile (D93). */
async function queuePdf(jobs: Pick<JobsDb, "enqueue"> | undefined, centre: string, generation: string, requestId: string): Promise<void> {
  if (!jobs) return;
  try {
    await jobs.enqueue(centre, "pdf", `pdf:gen:${generation}`, { generation_id: generation });
  } catch (e) {
    log.error({ requestId, generation, message: "a result's PDF was not queued", error: e instanceof Error ? e : String(e) });
  }
}
