import { expect, test } from "bun:test";

/** The restore drill counts every public table on both sides: the SQL names each table supabase/types.ts knows. */
test("the restore drill's count names every public table, once", async () => {
  const types = await Bun.file(new URL("../supabase/types.ts", import.meta.url)).text();
  const tables = [...types.matchAll(/"(\w+)": \{\s*\n\s*Row: \{/g)].map((m) => m[1]).sort();
  const sql = await Bun.file(new URL("./restore-count.sql", import.meta.url)).text();
  const counted = [...sql.matchAll(/count\(\*\) as n from public\.(\w+)/g)].map((m) => m[1]).sort();
  expect(tables.length).toBeGreaterThan(25);
  expect(counted).toEqual(tables);
});
