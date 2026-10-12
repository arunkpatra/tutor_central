import { expect, test } from "bun:test";
import { pollSql, queueSql, tomorrowInIndia } from "./run-job";

test("the queue SQL finds the centre by the email and the batch by its name, and inserts the job once", () => {
  const sql = queueSql("owner+x@example.com", "Evening batch", "2026-10-13");
  expect(sql).toContain("lower(u.email) = lower('owner+x@example.com')");
  expect(sql).toContain("c.name = 'Evening batch'");
  expect(sql).toContain("'plan:' || v_class || ':2026-10-13'");
  expect(sql).toContain("on conflict do nothing");
  expect(sql).toContain("run_job: no centre for that email");
  expect(sql).toContain("run_job: no batch of that name");
});

test("a batch's name is quoted as SQL; a bad email or day is refused in words", () => {
  expect(queueSql("a@b.co", "Rao's batch", "2026-10-13")).toContain("'Rao''s batch'");
  expect(() => queueSql("not an email", "B", "2026-10-13")).toThrow("not an email address");
  expect(() => queueSql("a@b.co", "B", "13-10-2026")).toThrow("not a day");
  expect(() => queueSql("a@b.co", "", "2026-10-13")).toThrow("a batch's name");
});

test("the poll reads the job's state and plan id, never a name", () => {
  const sql = pollSql("a@b.co", "Evening batch", "2026-10-13");
  expect(sql).toContain("j.state");
  expect(sql).toContain("j.result");
  expect(sql).not.toContain("students");
});

test("tomorrow is India's tomorrow", () => {
  expect(tomorrowInIndia(new Date("2026-10-12T18:00:00Z"))).toBe("2026-10-13");
  expect(tomorrowInIndia(new Date("2026-10-12T19:00:00Z"))).toBe("2026-10-14");
});
