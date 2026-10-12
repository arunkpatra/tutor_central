import { SQL } from "bun";
import { afterAll, beforeAll, beforeEach, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, serviceClient, userClient } from "./client";

// Phase 18: the server's files (plan decision 20). Two private buckets, `exports` and `pdfs`, read by the centre's
// members and written by the platform; a deleted row's files are queued in `storage_deletions` for the sweep; a kept
// sheet, mock or brief queues its PDF's job.
let l: Local;
let sql: SQL;
let svc: SupabaseClient;
let a: SupabaseClient;
let b: SupabaseClient;
let centreA: string;
let centreB: string;
const stamp = Date.now();

async function student(c: SupabaseClient, centre: string): Promise<string> {
  const { data, error } = await c.from("students").insert({ centre_id: centre, name: "Stored" }).select("id").single();
  if (error) throw error;
  return data.id as string;
}
const deletions = (centre: string) =>
  sql`select bucket, path, prefix, why from public.storage_deletions where path like ${`${centre}/%`} order by bucket, path`;

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  svc = serviceClient(l);
  a = await userClient(l, `storage-a-${stamp}@example.com`);
  b = await userClient(l, `storage-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Storage A" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Storage B" })).data as string;
});
beforeEach(async () => {
  await sql`delete from public.storage_deletions`;
});
afterAll(async () => {
  await sql`delete from public.storage_deletions`;
  // Storage refuses a direct delete of its rows: through its API, as the sweep does.
  await svc.storage.from("pdfs").remove([`${centreA}/probe-${stamp}.pdf`]);
  await svc.storage.from("exports").remove([`${centreA}/s/probe-${stamp}.pdf`]);
  await sql.close();
});

test("the two buckets are private PDFs with their limits", async () => {
  const rows = await sql`select id, public, file_size_limit::int as file_size_limit, allowed_mime_types from storage.buckets where id in ('exports', 'pdfs') order by id`;
  expect([...rows]).toEqual([
    { id: "exports", public: false, file_size_limit: 10485760, allowed_mime_types: ["application/pdf"] },
    { id: "pdfs", public: false, file_size_limit: 5242880, allowed_mime_types: ["application/pdf"] },
  ]);
});

test("a deleted student's marks photo and exports are queued for deletion", async () => {
  const s = await student(a, centreA);
  await sql`insert into public.marks (centre_id, student_id, subject, test, date, score, max, photo_path)
            values (${centreA}, ${s}, 'Maths', 'Unit test 1', '2026-10-01', 19, 25, ${`${centreA}/mark/x.jpg`})`;
  expect((await a.from("students").delete().eq("id", s)).error).toBeNull();
  expect([...(await deletions(centreA))]).toEqual([
    { bucket: "exports", path: `${centreA}/${s}/`, prefix: true, why: "student" },
    { bucket: "photos", path: `${centreA}/mark/x.jpg`, prefix: false, why: "marks" },
  ]);
});

test("a deleted artefact queues its photo and its PDF; a deleted textbook or school item its photo", async () => {
  const art = (await a.from("artefacts").insert({ centre_id: centreA, kind: "sheet", source: "own", title: "Own", photo_path: `${centreA}/sheet/p.jpg` }).select("id").single()).data!.id;
  const school = (await a.from("schools").insert({ centre_id: centreA, name: "S" }).select("id").single()).data!.id;
  const book = (await a.from("textbooks").insert({ centre_id: centreA, school_id: school, class_level: "3", subject: "English", title: "E3", photo_path: `${centreA}/textbook/t.jpg` }).select("id").single()).data!.id;
  const item = (await a.from("school_items").insert({ centre_id: centreA, kind: "notice", date: "2026-10-20", photo_path: `${centreA}/item/i.jpg` }).select("id").single()).data!.id;
  await a.from("artefacts").delete().eq("id", art);
  await a.from("textbooks").delete().eq("id", book);
  await a.from("school_items").delete().eq("id", item);
  expect([...(await deletions(centreA))]).toEqual([
    { bucket: "pdfs", path: `${centreA}/${art}-key.pdf`, prefix: false, why: "artefact" },
    { bucket: "pdfs", path: `${centreA}/${art}.pdf`, prefix: false, why: "artefact" },
    { bucket: "photos", path: `${centreA}/item/i.jpg`, prefix: false, why: "school_items" },
    { bucket: "photos", path: `${centreA}/sheet/p.jpg`, prefix: false, why: "artefacts" },
    { bucket: "photos", path: `${centreA}/textbook/t.jpg`, prefix: false, why: "textbooks" },
  ]);
});

test("a deleted account queues its centre's three prefixes and nothing row by row", async () => {
  const gone = await userClient(l, `storage-gone-${stamp}@example.com`);
  const centre = (await gone.rpc("create_centre", { p_name: "Gone" })).data as string;
  const s = await student(gone, centre);
  await gone.from("marks").insert({ centre_id: centre, student_id: s, subject: "Maths", test: "T", date: "2026-10-01", score: 1, max: 2, photo_path: `${centre}/mark/m.jpg` });
  expect((await gone.rpc("delete_account")).error).toBeNull();
  expect([...(await deletions(centre))]).toEqual([
    { bucket: "exports", path: `${centre}/`, prefix: true, why: "centre" },
    { bucket: "pdfs", path: `${centre}/`, prefix: true, why: "centre" },
    { bucket: "photos", path: `${centre}/`, prefix: true, why: "centre" },
  ]);
});

test("a kept sheet queues its PDF job once; a check does not", async () => {
  await sql`delete from public.jobs where centre_id = ${centreA} and kind = 'pdf'`;
  const keep = (kind: string, key: string) =>
    a.rpc("keep_artefact", { p_centre: centreA, p_artefact: { kind, title: "Made", content: {} }, p_plan: null, p_group_no: 0, p_student: null, p_item_kind: kind === "check" ? "check" : "practise", p_key: key });
  const sheet = (await keep("sheet", `pdf-test-${stamp}`)).data as string;
  expect((await keep("sheet", `pdf-test-${stamp}`)).data).toBe(sheet);
  await keep("check", `pdf-check-${stamp}`);
  const jobs = await sql`select idempotency_key, input from public.jobs where centre_id = ${centreA} and kind = 'pdf'`;
  expect([...jobs]).toEqual([{ idempotency_key: `pdf:${sheet}`, input: { artefact_id: sheet } }]);
});

test("a member reads their centre's exports and pdfs objects, never another's, and writes none", async () => {
  const pdf = new Blob(["%PDF-1.7\n"], { type: "application/pdf" });
  expect((await svc.storage.from("pdfs").upload(`${centreA}/probe-${stamp}.pdf`, pdf)).error).toBeNull();
  expect((await svc.storage.from("exports").upload(`${centreA}/s/probe-${stamp}.pdf`, pdf)).error).toBeNull();
  expect((await a.storage.from("pdfs").download(`${centreA}/probe-${stamp}.pdf`)).error).toBeNull();
  expect((await a.storage.from("exports").download(`${centreA}/s/probe-${stamp}.pdf`)).error).toBeNull();
  expect((await b.storage.from("pdfs").download(`${centreA}/probe-${stamp}.pdf`)).error).not.toBeNull();
  expect((await b.storage.from("exports").download(`${centreA}/s/probe-${stamp}.pdf`)).error).not.toBeNull();
  expect((await a.storage.from("pdfs").upload(`${centreA}/mine-${stamp}.pdf`, pdf)).error).not.toBeNull();
  expect((await b.storage.from("pdfs").upload(`${centreB}/mine-${stamp}.pdf`, pdf)).error).not.toBeNull();
  await a.storage.from("pdfs").remove([`${centreA}/probe-${stamp}.pdf`]);
  expect((await svc.storage.from("pdfs").download(`${centreA}/probe-${stamp}.pdf`)).error).toBeNull();
});

test("a member reads no storage deletion and writes none", async () => {
  const s = await student(a, centreA);
  await a.from("students").delete().eq("id", s);
  expect((await a.from("storage_deletions").select("id")).data).toEqual([]);
  expect((await a.from("storage_deletions").insert({ bucket: "photos", path: `${centreB}/x.jpg`, why: "forged" })).error).not.toBeNull();
});

test("taken_storage_deletions hands each row out once and removes it", async () => {
  await sql`insert into public.storage_deletions (bucket, path, why) select 'photos', ${centreA} || '/t/' || g || '.jpg', 'test' from generate_series(1, 6) g`;
  const [x, y] = await Promise.all([svc.rpc("taken_storage_deletions", { p_limit: 4 }), svc.rpc("taken_storage_deletions", { p_limit: 4 })]);
  const taken = [...(x.data ?? []), ...(y.data ?? [])].map((r: { path: string }) => r.path);
  expect(taken).toHaveLength(6);
  expect(new Set(taken).size).toBe(6);
  expect((await sql`select count(*)::int as n from public.storage_deletions`)[0].n).toBe(0);
  expect((await a.rpc("taken_storage_deletions", { p_limit: 1 })).error?.code).toBe("42501");
});
