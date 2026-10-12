import { expect, test } from "bun:test";
import { readdirSync } from "node:fs";

// A workflow file GitHub cannot parse is never offered to run: it only records a failed run on each push (run-job.yml,
// 2026-10-12: a plain value holding ": "). Every file under .github/workflows must parse.
const dir = `${import.meta.dir}/../.github/workflows`;

for (const name of readdirSync(dir).filter((f) => f.endsWith(".yml"))) {
  test(`${name} parses as YAML`, async () => {
    const text = await Bun.file(`${dir}/${name}`).text();
    expect(() => Bun.YAML.parse(text)).not.toThrow();
  });
}
