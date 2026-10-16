#!/usr/bin/env bun
/** bun tools/admin-smoke.ts <origin> --commit <sha>: the deployed portal serves that commit at /health, Sign in answers,
 *  every gated page sends a request without a session to Sign in (never a page), and http redirects to https (plan
 *  decision 19); the tab icons are the brand kit's and answer without a session (D122). It never signs in: no script holds a second factor. Retries while the alias moves. Exit 1 with the
 *  problems in words. */
const GATED = ["/centres", "/jobs", "/alerts", "/calls/abc", "/nothing-here"];
const REDIRECTS = [301, 302, 303, 307, 308];
/** The brand kit's icon is known by its cap's path; the book it replaced by its spine (D120, D122). */
const KIT_ICON = "M128 0L256 64L128 128L0 64Z";
const BOOK = "M20.001 19A2";

const redirectsTo = (r: Response, ok: (location: string) => boolean) => REDIRECTS.includes(r.status) && ok(r.headers.get("location") ?? "");

export async function once(origin: string, commit: string, fetchLike: typeof fetch = fetch): Promise<string[]> {
  const problems: string[] = [];
  const get = (url: string) => fetchLike(url, { redirect: "manual" });
  try {
    const health = await get(`${origin}/health`);
    if (health.status !== 200) problems.push(`/health answered ${health.status}`);
    else {
      const served = ((await health.json()) as { commit?: string }).commit;
      if (served !== commit) problems.push(`/health serves ${served ?? "no commit"}, not ${commit}`);
    }
    const signIn = await get(`${origin}/sign-in`);
    if (signIn.status !== 200) problems.push(`/sign-in answered ${signIn.status}`);
    else if (!(await signIn.text()).includes("Sign in")) problems.push("/sign-in does not say Sign in");
    // An unknown path redirects too: the proxy sends any request without a session to Sign in before routing.
    for (const path of GATED) {
      const r = await get(origin + path);
      if (r.status === 200) problems.push(`${path} served a page without a session`);
      else if (!redirectsTo(r, (l) => new URL(l, origin).pathname === "/sign-in")) problems.push(`${path} answered ${r.status}, not a redirect to /sign-in`);
    }
    const icon = await get(`${origin}/icon.svg`);
    const svg = icon.status === 200 ? await icon.text() : "";
    if (!svg.includes(KIT_ICON) || svg.includes(BOOK)) problems.push("/icon.svg is not the brand kit's icon");
    const favicon = await get(`${origin}/favicon.ico`);
    if (favicon.status !== 200 || !(favicon.headers.get("content-type") ?? "").startsWith("image/")) problems.push(`/favicon.ico answered ${favicon.status}`);
    const host = new URL(origin).host;
    const http = await get(`http://${host}/`);
    if (!redirectsTo(http, (l) => l.startsWith("https://"))) problems.push(`http://${host}/ does not redirect to https`);
  } catch (e) {
    problems.push(`could not reach ${origin}: ${(e as Error).message}`);
  }
  return problems;
}

export async function adminSmoke(origin: string, commit: string, opts: { attempts?: number; waitMs?: number; fetchLike?: typeof fetch } = {}): Promise<string[]> {
  const attempts = opts.attempts ?? 6;
  let problems: string[] = [];
  for (let i = 1; i <= attempts; i++) {
    problems = await once(origin, commit, opts.fetchLike);
    if (problems.length === 0 || i === attempts) break;
    await Bun.sleep(opts.waitMs ?? 5000);
  }
  return problems;
}

if (import.meta.main) {
  const [origin, flag, commit] = process.argv.slice(2);
  if (!origin || flag !== "--commit" || !commit) {
    console.error("usage: bun tools/admin-smoke.ts <origin> --commit <sha>");
    process.exit(2);
  }
  const problems = await adminSmoke(origin.replace(/\/$/, ""), commit);
  if (problems.length > 0) {
    console.error(`smoke of ${origin} failed:\n${problems.map((p) => `  - ${p}`).join("\n")}`);
    process.exit(1);
  }
  console.log(`smoke of ${origin}: /health serves ${commit}; Sign in answers; the gated pages send to Sign in; the brand kit's tab icons; http goes to https`);
}
