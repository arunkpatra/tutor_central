#!/usr/bin/env bun
/** bun tools/smoke.ts <site> --commit <sha>: the deployed API answers, serves that commit, and guards its AI routes.
 *  Retries while the alias moves to the new deployment. With the worker's secret it wakes the worker and reads its
 *  health. It makes no paid AI call (D112): a deploy spends nothing on its own. Exit 1 with the problems in words. */

export type SmokeOptions = { attempts?: number; waitMs?: number; workerSecret?: string };

async function tick(site: string, secret: string): Promise<string[]> {
  const res = await fetch(`${site}/jobs/tick`, { headers: { authorization: `Bearer ${secret}` } });
  return res.status === 200 ? [] : [`/jobs/tick answered ${res.status}`];
}

/** The worker's health (plan decision 26): a page rendered with the bundled fonts and a formula (D102), and APNs taking
 *  the key. */
async function workerHealth(site: string, secret: string): Promise<string[]> {
  const res = await fetch(`${site}/jobs/health`, { headers: { authorization: `Bearer ${secret}` } });
  if (res.status !== 200) return [`/jobs/health answered ${res.status}`];
  const body = (await res.json()) as { pdf?: number; maths?: boolean; apns?: boolean };
  const problems: string[] = [];
  if (!body.pdf || body.pdf < 1) problems.push("/jobs/health rendered no page");
  else if (body.maths !== true) problems.push("/jobs/health drew no formula (mitex or STIX Two Math is not with the function)");
  if (body.apns !== true) problems.push("/jobs/health could not reach APNs");
  return problems;
}

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
  // The wake runs once, on the deployment the retries settled on.
  if (problems.length > 0) return problems;
  try {
    if (opts.workerSecret) problems.push(...(await tick(site, opts.workerSecret)), ...(await workerHealth(site, opts.workerSecret)));
  } catch (e) {
    problems.push(`could not reach ${site}: ${(e as Error).message}`);
  }
  return problems;
}

if (import.meta.main) {
  const [site, flag, commit] = process.argv.slice(2);
  if (!site || flag !== "--commit" || !commit) {
    console.error("usage: bun tools/smoke.ts <site> --commit <sha>");
    process.exit(2);
  }
  const workerSecret = process.env.WORKER_SECRET || undefined;
  const problems = await smoke(site.replace(/\/$/, ""), commit, { workerSecret });
  if (problems.length > 0) {
    console.error(`smoke of ${site} failed:\n${problems.map((p) => `  - ${p}`).join("\n")}`);
    process.exit(1);
  }
  console.log(`smoke of ${site}: health ok, commit ${commit}, AI routes refuse a missing token`);
  console.log(workerSecret ? "the worker answered its tick; a page rendered and APNs took the key" : "no worker secret: the worker not woken");
}
