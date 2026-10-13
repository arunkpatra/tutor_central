import { expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const APP = join(import.meta.dir, "..", "..", "app");
/** The door and the pages that need no admin: they never read a centre. */
const OPEN = ["sign-in/", "mfa/", "refused/", "not-found.tsx", "page.tsx"];

function pages(dir: string): string[] {
  return readdirSync(dir).flatMap((f) => {
    const p = join(dir, f);
    return statSync(p).isDirectory() ? pages(p) : f === "page.tsx" || f === "not-found.tsx" ? [p] : [];
  });
}

test("every page outside the door calls requireAdmin first", () => {
  const guarded = pages(APP).filter((p) => !OPEN.some((o) => relative(APP, p) === o || relative(APP, p).startsWith(o)));
  for (const p of guarded)
    expect({ page: relative(APP, p), gate: readFileSync(p, "utf8").includes("requireAdmin(") }).toEqual({
      page: relative(APP, p),
      gate: true,
    });
});

test("every server action calls requireAdmin, except the door's own", () => {
  const actions = pages(APP)
    .map((p) => join(p, "..", "actions.ts"))
    .filter((p) => {
      try {
        return statSync(p).isFile();
      } catch {
        return false;
      }
    });
  for (const a of actions.filter((p) => !/sign-in|mfa/.test(p)))
    expect({ action: relative(APP, a), gate: readFileSync(a, "utf8").includes("requireAdmin(") }).toEqual({
      action: relative(APP, a),
      gate: true,
    });
});

test("the service key is read in one module, which is server-only", () => {
  const files = (dir: string): string[] =>
    readdirSync(dir).flatMap((f) => {
      const p = join(dir, f);
      if (["node_modules", ".next", "test"].includes(f)) return [];
      return statSync(p).isDirectory() ? files(p) : /\.tsx?$/.test(f) ? [p] : [];
    });
  const root = join(import.meta.dir, "..", "..");
  const readers = files(root).filter((f) => readFileSync(f, "utf8").includes('env("SUPABASE_SERVICE_ROLE_KEY")'));
  expect(readers.map((f) => relative(root, f))).toEqual(["lib/supabase/service.ts"]);
  expect(readFileSync(join(root, "lib", "supabase", "service.ts"), "utf8")).toContain('import "server-only"');
  expect(readFileSync(join(root, "lib", "env.ts"), "utf8")).not.toContain("NEXT_PUBLIC_");
});
