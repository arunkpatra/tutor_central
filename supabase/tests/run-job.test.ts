import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pollSql, queueSql } from "../../tools/run-job";
import { sh } from "../../tools/lib/sh";
import { type Local, local, userClient } from "./client";

// The run-job workflow's SQL, run as the workflow runs it (`supabase db query`), here on the local database.
let l: Local;
let sql: SQL;
let centre: string;
let batch: string;
const stamp = Date.now();
const email = `run-job-${stamp}@example.com`;

async function query(text: string) {
  const file = join(mkdtempSync(join(tmpdir(), "run-job-")), "job.sql");
  writeFileSync(file, text);
  return sh(["supabase", "db", "query", "--local", "-f", file], { cwd: `${import.meta.dir}/..` });
}

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  const owner = await userClient(l, email);
  centre = (await owner.rpc("create_centre", { p_name: "Run Job Centre" })).data as string;
  batch = (await owner.from("classes").insert({ centre_id: centre, name: "Evening batch" }).select("id").single()).data!.id;
});
afterAll(async () => {
  await sql`delete from public.jobs where centre_id = ${centre}`;
  await sql.close();
});

test("the queue SQL inserts one plan job for the batch and day, and a second run adds none", async () => {
  expect((await query(queueSql(email.toUpperCase(), "Evening batch", "2026-10-13"))).code).toBe(0);
  expect((await query(queueSql(email, "Evening batch", "2026-10-13"))).code).toBe(0);
  const rows = await sql`select kind, idempotency_key, input from public.jobs where centre_id = ${centre}`;
  expect(rows).toEqual([{ kind: "plan", idempotency_key: `plan:${batch}:2026-10-13`, input: { class_id: batch, date: "2026-10-13" } }]);
  const poll = await query(pollSql(email, "Evening batch", "2026-10-13"));
  expect(poll.stdout).toContain("queued");
});

test("an unknown email or batch is refused in words and queues nothing", async () => {
  const noCentre = await query(queueSql(`nobody-${stamp}@example.com`, "Evening batch", "2026-10-14"));
  expect(noCentre.code).not.toBe(0);
  expect(noCentre.stdout + noCentre.stderr).toContain("no centre for that email");
  const noBatch = await query(queueSql(email, "Morning batch", "2026-10-14"));
  expect(noBatch.stdout + noBatch.stderr).toContain("no batch of that name");
  expect((await sql`select count(*)::int as n from public.jobs where centre_id = ${centre}`)[0].n).toBe(1);
});
