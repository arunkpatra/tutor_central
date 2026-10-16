import { expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

/** The brand kit's copies are never edited here (D120, D122): each file in the manifest matches the hash it was copied
 * with, and, where the kit sits beside this repo, the kit's own file at the manifest's version. */
const ROOT = join(import.meta.dir, "..");
const KIT = join(ROOT, "..", "tutor_central_logo");
type Manifest = { version: string; files: { path: string; source: string; sha256: string }[] };
const manifest: Manifest = JSON.parse(readFileSync(join(ROOT, "docs/design/brand-kit.json"), "utf8"));
const sha = (data: Uint8Array) => createHash("sha256").update(data).digest("hex");

test("every copy is the kit's file, unchanged", () => {
  for (const file of manifest.files) {
    const path = join(ROOT, file.path);
    expect(existsSync(path), `${file.path} is missing`).toBe(true);
    expect(sha(readFileSync(path)), `${file.path} differs from the kit's ${file.source}`).toBe(file.sha256);
  }
});

test("the manifest names the kit's files at its version (when the kit is beside this repo)", () => {
  if (!existsSync(join(KIT, ".git"))) return;
  for (const file of manifest.files) {
    const shown = Bun.spawnSync(["git", "-C", KIT, "show", `${manifest.version}:${file.source}`]);
    expect(shown.exitCode, `${file.source} is not in the kit at ${manifest.version}`).toBe(0);
    expect(sha(shown.stdout), `${file.source} at ${manifest.version}`).toBe(file.sha256);
  }
});
