#!/usr/bin/env bun
/** bun tools/smoke.ts <site> --commit <sha>: the deployed API answers, serves that commit, and guards its AI routes.
 *  Retries while the alias moves to the new deployment. Exit 1 with the problems in words. */

export type SmokeOptions = { attempts?: number; waitMs?: number };

async function once(site: string, commit: string): Promise<string[]> {
  const problems: string[] = [];
  try {
    const health = await fetch(`${site}/health`);
    if (health.status !== 200) {
      problems.push(`/health answered ${health.status}`);
    } else {
      const body = (await health.json()) as { ok?: boolean; commit?: string };
      if (body.ok !== true) problems.push("/health did not say ok");
      if (body.commit !== commit) problems.push(`the site serves ${body.commit}, not ${commit}`);
    }
    const ai = await fetch(`${site}/ai/generate`, { method: "POST", headers: { "content-type": "application/json" }, body: "{}" });
    if (ai.status !== 401) problems.push(`/ai/generate without a token answered ${ai.status}, not 401`);
  } catch (e) {
    problems.push(`could not reach ${site}: ${(e as Error).message}`);
  }
  return problems;
}

export async function smoke(site: string, commit: string, opts: SmokeOptions = {}): Promise<string[]> {
  const attempts = opts.attempts ?? 6;
  let problems: string[] = [];
  for (let i = 1; i <= attempts; i++) {
    problems = await once(site, commit);
    if (problems.length === 0 || i === attempts) break;
    await Bun.sleep(opts.waitMs ?? 5000);
  }
  return problems;
}

if (import.meta.main) {
  const [site, flag, commit] = process.argv.slice(2);
  if (!site || flag !== "--commit" || !commit) {
    console.error("usage: bun tools/smoke.ts <site> --commit <sha>");
    process.exit(2);
  }
  const problems = await smoke(site.replace(/\/$/, ""), commit);
  if (problems.length > 0) {
    console.error(`smoke of ${site} failed:\n${problems.map((p) => `  - ${p}`).join("\n")}`);
    process.exit(1);
  }
  console.log(`smoke of ${site}: health ok, commit ${commit}, AI routes refuse a missing token`);
}
