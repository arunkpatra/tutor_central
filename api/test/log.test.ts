import { expect, test } from "bun:test";
import { line } from "../src/log.js";

test("a log line is one JSON object with its time, level and fields", () => {
  const parsed = JSON.parse(line("info", { requestId: "r", route: "/x", status: 200 }));
  expect(parsed).toMatchObject({ level: "info", requestId: "r", route: "/x", status: 200 });
  expect(new Date(parsed.t).toISOString()).toBe(parsed.t);
});

test("an error in the fields becomes its name and message", () => {
  const parsed = JSON.parse(line("error", { requestId: "r", error: new TypeError("bad thing") }));
  expect(parsed.error).toEqual({ name: "TypeError", message: "bad thing" });
});

test("a line stays one line", () => {
  expect(line("warn", { message: "two\nlines" }).includes("\n")).toBe(false);
});
