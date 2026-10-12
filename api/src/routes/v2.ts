import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { request as textbookRequest } from "../prompts/parse-textbook.js";
import { request as planRequest } from "../prompts/plan.js";
import { request as readMarksRequest } from "../prompts/read-marks.js";
import { type DecodedImage, decodeImage } from "../images.js";
import { makeRequest } from "../make.js";
import { MakeInput, ParseTextbookInput, PlanInput, ReadMarksInput } from "../schemas.js";
import { answer, isParsed, parse, run } from "./common.js";

/** The V2 routes (docs/spec-v2.md section 9): the textbook's contents page, `/plan` (a first topic for a group whose
 *  record names none), `/make` for the group material (sheet, worked example, figure, brief, check), the placement, the
 *  mock, the gap report and the parents' messages (Test tomorrow, the note, can-now-do, not on track), and
 *  `/read-marks` (a report card's marks, Phase 14). A photo is never stored: the record's input holds the page count
 *  and the bytes. */
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
    return run(c, deps, body.centre, { input: body.value, ...makeRequest(body.value) });
  });
  routes.post("/read-marks", async (c) => {
    const body = await parse(c, ReadMarksInput);
    if (!isParsed(body)) return body;
    const pages: DecodedImage[] = [];
    for (const page of body.value.pages) {
      const image = decodeImage(page);
      if (typeof image === "string") return answer(c, errors.badImage(image));
      pages.push(image);
    }
    const { studentId, studentName, subjects } = body.value;
    const input = { kind: "read_marks", pages: pages.length, bytes: pages.reduce((n, p) => n + p.bytes, 0), studentName };
    const request = readMarksRequest(pages, studentName, subjects ?? []);
    return run(c, deps, body.centre, { kind: "read_marks", input, request, student: studentId, studentName, empty: (read) => read.marks.length === 0 });
  });
  return routes;
}
