import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { parseTextbook, plan, readMarks } from "../agents/kinds/index.js";
import { type DecodedImage, decodeImage } from "../images.js";
import { makeAgent } from "../make.js";
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
    return run(c, deps, body.centre, parseTextbook, { image, classLevel, subject }, input);
  });
  routes.post("/plan", async (c) => {
    const body = await parse(c, PlanInput);
    if (!isParsed(body)) return body;
    return run(c, deps, body.centre, plan, body.value);
  });
  routes.post("/make", async (c) => {
    const body = await parse(c, MakeInput);
    if (!isParsed(body)) return body;
    return run(c, deps, body.centre, makeAgent(body.value), body.value);
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
    return run(c, deps, body.centre, readMarks, { pages, studentName, studentId, subjects: subjects ?? [] }, input);
  });
  return routes;
}
