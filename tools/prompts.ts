#!/usr/bin/env bun
/** bun prompts [--write]: the prompts' versions (D74). Each kind's VERSION and the hash of its words, from
 *  api/src/prompts/registry.ts, against api/src/prompts/versions.json: a kind whose words changed under the same VERSION,
 *  or a VERSION raised with the same words, is named and the run exits 1 (`bun check`'s api step holds the same in
 *  test/prompt-versions.test.ts). --write rewrites the table once each changed kind's VERSION is raised. */
import { join } from "node:path";

const ROOT = join(import.meta.dir, "..");
const TABLE = join(ROOT, "api/src/prompts/versions.json");

type Table = Record<string, { version: string; hash: string }>;

/** The table and its problems, read in the API's own package so its imports resolve as they do there. */
async function fromAPI(written: Table): Promise<{ table: Table; problems: string[] }> {
  const p = Bun.spawn(
    ["bun", "-e", `import { versionTable, versionProblems } from "./src/prompts/registry.ts"; const t = versionTable(); console.log(JSON.stringify({ table: t, problems: versionProblems(${JSON.stringify(written)}, t) }))`],
    { cwd: join(ROOT, "api"), stdout: "pipe", stderr: "pipe" },
  );
  const out = await new Response(p.stdout).text();
  if ((await p.exited) !== 0) throw new Error(`api/src/prompts/registry.ts did not run: ${await new Response(p.stderr).text()}`);
  return JSON.parse(out);
}

/** Only a table whose every change carries a raised VERSION is written: words moved under the same version stay a problem. */
export function writable(problems: string[]): string[] {
  return problems.filter((p) => !p.endsWith("versions.json is stale; run bun prompts --write") && !p.endsWith("not in versions.json") && !p.endsWith("but no prompt"));
}

if (import.meta.main) {
  const file = Bun.file(TABLE);
  const written: Table = (await file.exists()) ? await file.json() : {};
  const { table, problems } = await fromAPI(written);
  if (process.argv.includes("--write")) {
    const blocking = Object.keys(written).length === 0 ? [] : writable(problems);
    if (blocking.length > 0) {
      console.error(`not written:\n${blocking.map((p) => `  - ${p}`).join("\n")}`);
      process.exit(1);
    }
    await Bun.write(TABLE, `${JSON.stringify(table, null, 2)}\n`);
    console.log(`wrote ${Object.keys(table).length} prompts' versions`);
  } else if (problems.length > 0) {
    console.error(`the prompts' versions do not hold:\n${problems.map((p) => `  - ${p}`).join("\n")}`);
    process.exit(1);
  } else console.log("the prompts' versions hold");
}
