#!/usr/bin/env bun
/** bun check: every step in order, stopping at the first failure; a step whose inputs are unchanged since it was last
 *  green is not run. --fresh ignores the cache; --only=a,b runs some steps. */
import { hashInputs, readStamp, writeStamp } from "./check/cache";
import { STEPS, toolchainSalt } from "./check/steps";

const fresh = process.argv.includes("--fresh");
const only = process.argv
  .find((a) => a.startsWith("--only="))
  ?.slice("--only=".length)
  .split(",");
const unknown = only?.filter((name) => !STEPS.some((s) => s.name === name)) ?? [];
if (unknown.length > 0) {
  console.error(`check: no step named ${unknown.join(", ")}. Steps: ${STEPS.map((s) => s.name).join(", ")}`);
  process.exit(2);
}

const salt = await toolchainSalt();
const summary: string[] = [];
const seconds = (since: number) => `${((Date.now() - since) / 1000).toFixed(1)}s`;
const t0 = Date.now();

for (const step of STEPS) {
  if (only && !only.includes(step.name)) continue;
  const started = Date.now();
  const reason = step.skipIf ? await step.skipIf() : null;
  if (reason) {
    summary.push(`  ${step.name.padEnd(8)} skipped: ${reason}`);
    continue;
  }
  const hash = await hashInputs(step.inputs, ".", salt);
  if (!fresh && (await readStamp(step.name)) === hash) {
    summary.push(`  ${step.name.padEnd(8)} unchanged, not run`);
    continue;
  }
  console.log(`\n▶ ${step.name}`);
  try {
    await step.run();
  } catch (e) {
    console.error(`\n✗ ${step.name} failed after ${seconds(started)}: ${(e as Error).message}`);
    if (summary.length > 0) console.log(summary.join("\n"));
    process.exit(1);
  }
  await writeStamp(step.name, hash);
  summary.push(`  ${step.name.padEnd(8)} green in ${seconds(started)}`);
}

console.log(`\ncheck: all green in ${seconds(t0)}\n${summary.join("\n")}`);
