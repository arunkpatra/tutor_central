import { sh } from "../lib/sh";

/** Run a shell pipeline with inherited stdio; throw on a non-zero exit. */
export async function run(cmd: string, cwd?: string): Promise<void> {
  const r = await sh(["bash", "-c", `set -o pipefail; ${cmd}`], { cwd, inherit: true });
  if (r.code !== 0) throw new Error(`step failed (${r.code}): ${cmd}`);
}
