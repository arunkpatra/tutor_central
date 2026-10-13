#!/usr/bin/env bun
/** bun tools/smoke.ts <site> --commit <sha>: the deployed API answers, serves that commit, and guards its AI routes.
 *  Retries while the alias moves to the new deployment. With the smoke account (D80) it signs in and makes one real
 *  `check` for the smoke centre; with the worker's secret it wakes the worker. Exit 1 with the problems in words. */

/** The smoke centre's owner: a password sign-in at the project's Auth, then one call as that tutor. */
export type SmokeAccount = { url: string; anon: string; email: string; password: string; centre: string };
export type SmokeOptions = { attempts?: number; waitMs?: number; account?: SmokeAccount; workerSecret?: string };

/** One `check` on the real model (Haiku, no student, no consent). The key makes a re-run for the same commit free. */
async function makeCheck(site: string, commit: string, a: SmokeAccount): Promise<string[]> {
  const signIn = await fetch(`${a.url}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: { apikey: a.anon, "content-type": "application/json" },
    body: JSON.stringify({ email: a.email, password: a.password }),
  });
  if (signIn.status !== 200) return [`the smoke account could not sign in (${signIn.status})`];
  const token = ((await signIn.json()) as { access_token?: string }).access_token;
  if (!token) return ["the smoke account's sign-in answered no token"];
  const made = await fetch(`${site}/ai/make`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
      "idempotency-key": `smoke-${commit}`,
      "x-request-id": crypto.randomUUID(),
    },
    body: JSON.stringify({ kind: "check", centreId: a.centre, classLevel: "5", subject: "Mathematics", skills: ["Adding fractions"] }),
  });
  if (made.status !== 200) {
    const reason = ((await made.json().catch(() => ({}))) as { reason?: string }).reason;
    return [`/ai/make for the smoke centre answered ${made.status}${reason ? ` (${reason})` : ""}`];
  }
  const questions = ((await made.json()) as { result?: { questions?: unknown[] } }).result?.questions ?? [];
  if (questions.length < 1) return ["/ai/make for the smoke centre answered no question"];
  return [];
}

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
  // The paid call and the wake run once, on the deployment the retries settled on.
  if (problems.length > 0) return problems;
  try {
    if (opts.account) problems.push(...(await makeCheck(site, commit, opts.account)));
    if (opts.workerSecret) problems.push(...(await tick(site, opts.workerSecret)), ...(await workerHealth(site, opts.workerSecret)));
  } catch (e) {
    problems.push(`could not reach ${site}: ${(e as Error).message}`);
  }
  return problems;
}

/** The account from the environment the deploy sets, when all five names are there. */
export function accountFromEnv(env: Record<string, string | undefined>): SmokeAccount | undefined {
  const { SUPABASE_URL: url, SUPABASE_ANON_KEY: anon, SMOKE_EMAIL: email, SMOKE_PASSWORD: password, SMOKE_CENTRE_ID: centre } = env;
  return url && anon && email && password && centre ? { url: url.replace(/\/$/, ""), anon, email, password, centre } : undefined;
}

if (import.meta.main) {
  const [site, flag, commit] = process.argv.slice(2);
  if (!site || flag !== "--commit" || !commit) {
    console.error("usage: bun tools/smoke.ts <site> --commit <sha>");
    process.exit(2);
  }
  const account = accountFromEnv(process.env);
  const workerSecret = process.env.WORKER_SECRET || undefined;
  const problems = await smoke(site.replace(/\/$/, ""), commit, { account, workerSecret });
  if (problems.length > 0) {
    console.error(`smoke of ${site} failed:\n${problems.map((p) => `  - ${p}`).join("\n")}`);
    process.exit(1);
  }
  console.log(`smoke of ${site}: health ok, commit ${commit}, AI routes refuse a missing token`);
  console.log(account ? "one check made for the smoke centre on the real model" : "no smoke account: no real call made");
  console.log(workerSecret ? "the worker answered its tick; a page rendered and APNs took the key" : "no worker secret: the worker not woken");
}
