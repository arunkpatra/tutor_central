import { expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const NEXT = join(import.meta.dir, "..", "..", ".next");
const PROBE = "sb_secret_build_probe_do_not_use";

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((f) => {
    const p = join(dir, f);
    return statSync(p).isDirectory() ? files(p) : [p];
  });
}

test("the service key is in no build output", () => {
  // The build ran with the probe as the service key (package.json's check): no file Next wrote may carry it.
  const hits = files(NEXT).filter((f) => readFileSync(f).includes(PROBE));
  expect(hits).toEqual([]);
});

test("the browser's files carry no Supabase key at all", () => {
  const browser = files(join(NEXT, "static"));
  expect(browser.filter((f) => /sb_secret|service_role/.test(readFileSync(f, "utf8")))).toEqual([]);
});
