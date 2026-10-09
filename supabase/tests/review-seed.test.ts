import { beforeAll, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createClient } from "@supabase/supabase-js";
import { reviewSeedSql } from "../../tools/review-seed";
import { sh } from "../../tools/lib/sh";
import { type Local, local, userClient } from "./client";

const PHONE = "+919000000001";
let l: Local;
let reviewCentre: string;
let otherCentre: string;

/** Runs the seed the way the workflow does, through `supabase db query`, here on the local database. */
async function seed(email: string, phone = PHONE) {
  const file = join(mkdtempSync(join(tmpdir(), "review-seed-")), "seed.sql");
  writeFileSync(file, reviewSeedSql(email, phone));
  return sh(["supabase", "db", "query", "--local", "-f", file], { cwd: `${import.meta.dir}/..` });
}

const admin = () => createClient(l.url, l.service, { auth: { persistSession: false, autoRefreshToken: false } });
async function count(table: string, centre: string, filter: Record<string, unknown> = {}) {
  let q = admin().from(table).select("*", { count: "exact", head: true }).eq("centre_id", centre);
  for (const [k, v] of Object.entries(filter)) q = q.eq(k, v);
  const { count: n, error } = await q;
  if (error) throw error;
  return n ?? 0;
}

beforeAll(async () => {
  l = await local();
  const stamp = Date.now();
  const review = await userClient(l, `review-${stamp}@example.com`);
  const r = await review.rpc("create_centre", { p_name: "Bright Minds Tuition", p_display_name: "Meera Nair" });
  if (r.error) throw r.error;
  reviewCentre = r.data as string;
  const other = await userClient(l, `other-${stamp}@example.com`);
  const o = await other.rpc("create_centre", { p_name: "A real centre" });
  if (o.error) throw o.error;
  otherCentre = o.data as string;
  const done = await seed(`Review-${stamp}@Example.com`);
  if (done.code !== 0) throw new Error(done.stderr || done.stdout);
});

test("the review centre gets two classes, ten students, a month of fees, four weeks of attendance, an event, tasks", async () => {
  expect(await count("classes", reviewCentre)).toBe(2);
  expect(await count("students", reviewCentre)).toBe(10);
  expect(await count("fee_invoices", reviewCentre)).toBe(10);
  expect(await count("fee_invoices", reviewCentre, { status: "paid" })).toBe(6);
  expect(await count("attendance_sessions", reviewCentre)).toBeGreaterThan(8);
  expect(await count("attendance_marks", reviewCentre, { status: "absent" })).toBeGreaterThan(0);
  expect(await count("calendar_events", reviewCentre)).toBe(1);
  expect(await count("tasks", reviewCentre)).toBe(2);
});

test("every parent has the one number given, so a reviewer's message can reach no stranger", async () => {
  const { data, error } = await admin().from("students").select("parent_phone").eq("centre_id", reviewCentre);
  if (error) throw error;
  expect(new Set(data.map((s) => s.parent_phone))).toEqual(new Set([PHONE]));
});

test("another centre is untouched", async () => {
  expect(await count("students", otherCentre)).toBe(0);
  expect(await count("classes", otherCentre)).toBe(0);
});

test("a centre that already has students is refused, and nothing is added", async () => {
  const again = await seed(`review-${reviewCentre}@example.com`.replace(reviewCentre, "x")); // no such account
  expect(again.code).not.toBe(0);
  expect(`${again.stdout}${again.stderr}`).toContain("No account");
  const { data } = await admin().from("centre_members").select("user_id").eq("centre_id", reviewCentre).single();
  const { data: user } = await admin().auth.admin.getUserById(data?.user_id as string);
  const twice = await seed(user.user?.email as string);
  expect(twice.code).not.toBe(0);
  expect(`${twice.stdout}${twice.stderr}`).toContain("already has students");
  expect(await count("students", reviewCentre)).toBe(10);
});

test("the email and the number are checked before any SQL is written", () => {
  expect(() => reviewSeedSql("x'); drop table students; --@a.in", PHONE)).toThrow("email");
  expect(() => reviewSeedSql("review@tutorcentral.in", "98765 43210")).toThrow("number");
  expect(reviewSeedSql("review@tutorcentral.in", PHONE)).toContain("'review@tutorcentral.in'");
});
