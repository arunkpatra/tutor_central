import { Glob } from "bun";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

const skipped = (path: string) => path.split("/").slice(0, -1).some((dir) => dir.startsWith(".") || dir === "node_modules");

/** sha256 over the sorted matched files (path and contents) and a salt naming the toolchain.
 *  Files inside hidden directories (.build, .swiftpm) or node_modules never count; a dotfile itself may. */
export async function hashInputs(globs: string[], root: string, salt: string): Promise<string> {
  const files = new Set<string>();
  for (const g of globs) {
    for await (const f of new Glob(g).scan({ cwd: root, dot: true, onlyFiles: true })) {
      if (!skipped(f)) files.add(f);
    }
  }
  const h = new Bun.CryptoHasher("sha256");
  h.update(salt);
  for (const f of [...files].sort()) {
    h.update(`\0${f}\0`);
    h.update(await Bun.file(join(root, f)).arrayBuffer());
  }
  return h.digest("hex");
}

export async function readStamp(step: string, cacheDir = ".check-cache"): Promise<string | null> {
  const f = Bun.file(join(cacheDir, step));
  return (await f.exists()) ? (await f.text()).trim() : null;
}

export async function writeStamp(step: string, hash: string, cacheDir = ".check-cache"): Promise<void> {
  await mkdir(cacheDir, { recursive: true });
  await Bun.write(join(cacheDir, step), hash);
}
