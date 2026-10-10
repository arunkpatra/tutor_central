import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { decodeImage } from "../images.js";
import { request as briefRequest } from "../prompts/brief.js";
import { request as checkRequest } from "../prompts/check.js";
import { request as figureRequest } from "../prompts/figure.js";
import { request as textbookRequest } from "../prompts/parse-textbook.js";
import { request as placementRequest } from "../prompts/placement.js";
import { request as planRequest } from "../prompts/plan.js";
import { request as sheetRequest } from "../prompts/sheet.js";
import { request as workedExampleRequest } from "../prompts/worked-example.js";
import { MakeInput, ParseTextbookInput, PlanInput } from "../schemas.js";
import { answer, isParsed, notYet, parse, run } from "./common.js";

/** The V2 routes that are live (docs/spec-v2.md section 9): the textbook's contents page, `/plan` (a first topic for a
 *  group whose record names none), and `/make` for the group material (sheet, worked example, figure, brief, check) and
 *  the placement; the mock and the personal kinds answer 501 until their phase. The photo is never stored: the record's
 *  input holds the page count, the bytes, the class and the subject. */
export function v2Routes(deps: { claude: ClaudeClient; db: Db }) {
  const routes = new Hono<Vars>();
  routes.post("/parse-textbook", async (c) => {
    const body = await parse(c, ParseTextbookInput);
    if (!isParsed(body)) return body;
    const image = decodeImage(body.value.image);
    if (typeof image === "string") return answer(c, errors.badImage(image));
    const { classLevel, subject } = body.value;
    const input = { kind: "parse_textbook", pages: 1, bytes: image.bytes, classLevel, subject };
    const request = textbookRequest(image, classLevel, subject);
    return run(c, deps, body.centre, { kind: "parse_textbook", input, request, empty: (read) => read.chapters.length === 0 });
  });
  routes.post("/plan", async (c) => {
    const body = await parse(c, PlanInput);
    if (!isParsed(body)) return body;
    return run(c, deps, body.centre, { kind: "plan", input: body.value, request: planRequest(body.value) });
  });
  routes.post("/make", async (c) => {
    const body = await parse(c, MakeInput);
    if (!isParsed(body)) return body;
    const v = body.value;
    switch (v.kind) {
      case "sheet":
        return run(c, deps, body.centre, { kind: "sheet", input: v, request: sheetRequest(v) });
      case "worked_example":
        return run(c, deps, body.centre, { kind: "worked_example", input: v, request: workedExampleRequest(v.classLevel, v.subject, v.skill) });
      case "figure":
        return run(c, deps, body.centre, {
          kind: "figure",
          input: v,
          request: figureRequest(v.figure, v.classLevel, v.subject, v.skill),
          // The template asked for is the template answered; another is an unfit answer.
          empty: (made) => made.figure.kind !== v.figure,
        });
      case "brief":
        return run(c, deps, body.centre, { kind: "brief", input: v, request: briefRequest(v.classLevel, v.subject, v.chapter) });
      case "check":
        return run(c, deps, body.centre, { kind: "check", input: v, request: checkRequest(v.classLevel, v.subject, v.skills) });
      case "placement":
        return run(c, deps, body.centre, { kind: "placement", input: v, request: placementRequest(v.classLevel, v.subject, v.chapters) });
      default:
        return notYet(c, "/ai/make");
    }
  });
  return routes;
}
