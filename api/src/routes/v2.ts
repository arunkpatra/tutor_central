import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { decodeImage } from "../images.js";
import { request as checkRequest } from "../prompts/check.js";
import { request as textbookRequest } from "../prompts/parse-textbook.js";
import { request as placementRequest } from "../prompts/placement.js";
import { MakeInput, ParseTextbookInput } from "../schemas.js";
import { answer, isParsed, notYet, parse, run } from "./common.js";

/** The V2 routes that are live (docs/spec-v2.md section 9): the textbook's contents page, and `/make` for the kinds this
 *  phase makes (check, placement); every other kind answers 501 until its phase. The photo is never stored: the
 *  record's input holds the page count, the bytes, the class and the subject. */
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
  routes.post("/make", async (c) => {
    const body = await parse(c, MakeInput);
    if (!isParsed(body)) return body;
    const v = body.value;
    switch (v.kind) {
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
