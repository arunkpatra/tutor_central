#!/usr/bin/env bun
/** bun tools/web-smoke.ts <origin> --commit <sha>: the deployed site serves the four pages from that commit, an unknown path
 *  is the not-found page with a 404, http and www redirect to the apex, a trailing slash lands (D45). Retries while the alias
 *  moves. Exit 1 with the problems in words. */
const PAGES = ["/", "/privacy", "/terms", "/support"];
const NOT_FOUND_WORDS = "There is nothing at this address.";
const REDIRECTS = [301, 302, 307, 308];

const commitOf = (body: string) => body.match(/<meta name="tc-commit" content="([^"]+)"/)?.[1];
const redirectsTo = (r: Response, ok: (location: string) => boolean) =>
  REDIRECTS.includes(r.status) && ok(r.headers.get("location") ?? "");

export async function once(origin: string, commit: string, fetchLike: typeof fetch = fetch): Promise<string[]> {
  const problems: string[] = [];
  const get = (url: string) => fetchLike(url, { redirect: "manual" });
  try {
    for (const path of PAGES) {
      const r = await get(origin + path);
      if (r.status !== 200) {
        problems.push(`${path} answered ${r.status}`);
        continue;
      }
      const served = commitOf(await r.text());
      if (served !== commit) problems.push(`${path} serves ${served ?? "no commit"}, not ${commit}`);
    }
    const unknown = await get(`${origin}/students/abc`);
    if (unknown.status !== 404 || !(await unknown.text()).includes(NOT_FOUND_WORDS))
      problems.push("/students/abc is not the not-found page");
    const slash = await get(`${origin}/privacy/`);
    if (!(slash.status === 200 || redirectsTo(slash, (l) => l.endsWith("/privacy"))))
      problems.push("/privacy/ does not reach /privacy");
    const host = new URL(origin).host;
    const http = await get(`http://${host}/`);
    if (!redirectsTo(http, (l) => l.startsWith("https://"))) problems.push(`http://${host}/ does not redirect to https`);
    const www = await get(`https://www.${host}/`);
    if (!redirectsTo(www, (l) => l.startsWith(`${origin}/`)))
      problems.push(`https://www.${host}/ does not redirect to ${origin}/`);
  } catch (e) {
    problems.push(`could not reach ${origin}: ${(e as Error).message}`);
  }
  return problems;
}

export async function webSmoke(
  origin: string,
  commit: string,
  opts: { attempts?: number; waitMs?: number; fetchLike?: typeof fetch } = {},
): Promise<string[]> {
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
    console.error("usage: bun tools/web-smoke.ts <origin> --commit <sha>");
    process.exit(2);
  }
  const problems = await webSmoke(origin.replace(/\/$/, ""), commit);
  if (problems.length > 0) {
    console.error(`smoke of ${origin} failed:\n${problems.map((p) => `  - ${p}`).join("\n")}`);
    process.exit(1);
  }
  console.log(`smoke of ${origin}: the four pages serve ${commit}; not found, http and www behave`);
}
