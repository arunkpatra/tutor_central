import { SQL } from "bun";
import { expect, test } from "bun:test";
import { local } from "./client";

/** The restore drill counts every public table there is, with its rows (tools/restore-count.sql). */
test("the restore drill's count names every public table once, with its rows", async () => {
  const sql = new SQL((await local()).db);
  try {
    const query = await Bun.file(new URL("../../tools/restore-count.sql", import.meta.url)).text();
    const counted = (await sql.unsafe(query)) as { name: string; n: string | number }[];
    const tables = (await sql`select tablename from pg_tables where schemaname = 'public' order by tablename`).map((r: { tablename: string }) => r.tablename);
    expect(counted.map((r) => r.name)).toEqual(tables);
    const classes = (await sql`select count(*)::int as n from public.classes`)[0].n;
    expect(Number(counted.find((r) => r.name === "classes")?.n)).toBe(classes);
  } finally {
    await sql.close();
  }
});
