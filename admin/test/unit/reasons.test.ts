import { expect, test } from "bun:test";
import { reasonShort, reasonWords } from "../../content/reasons";

test("an answer's reason in the board's words", () => {
  expect(reasonWords("timeout", 502)).toBe("timeout · the model did not answer in 110 s");
  expect(reasonWords("student_consent", 403)).toBe("student_consent · a note asked without consent");
  expect(reasonWords("in_progress", 409)).toBe("in_progress · the same key still running");
  expect(reasonWords(null, 401)).toBe("sign in again · a stale token");
  expect(reasonWords(null, 413)).toBe("too large · a photo over the limit");
  expect(reasonWords("unknown_thing", 500)).toBe("unknown_thing");
  expect(reasonWords(null, 500)).toBe("—");
});

test("the short reason, for the latest", () => {
  expect(reasonShort("timeout", 502)).toBe("timeout");
  expect(reasonShort(null, 401)).toBe("sign in again");
});
