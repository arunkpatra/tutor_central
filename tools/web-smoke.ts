#!/usr/bin/env bun
/** bun tools/web-smoke.ts <origin> --commit <sha>: the deployed site serves the five pages from that commit, an unknown path
 *  and a capitalised one are the not-found page with a 404, http and www redirect to the apex, a trailing slash lands (D45),
 *  the tab icons are the brand kit's and Home carries the link preview (D122). Retries while the alias
 *  moves. Exit 1 with the problems in words. */
const PAGES = ["/", "/privacy", "/terms", "/support", "/trust"];
const NOT_FOUND_WORDS = "There is nothing at this address.";
const REDIRECTS = [301, 302, 307, 308];
/** The brand kit's icon is known by its cap's path; the book it replaced by its spine (D120, D122). */
const KIT_ICON = "M128 0L256 64L128 128L0 64Z";
const BOOK = "M20.001 19A2";

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
      const body = await r.text();
      const served = commitOf(body);
      if (served !== commit) problems.push(`${path} serves ${served ?? "no commit"}, not ${commit}`);
      if (path === "/" && !body.includes(`<meta property="og:image" content="${origin}/opengraph-image.png`))
        problems.push("/ has no link preview");
    }
    const icon = await get(`${origin}/icon.svg`);
    const svg = icon.status === 200 ? await icon.text() : "";
    if (!svg.includes(KIT_ICON) || svg.includes(BOOK)) problems.push("/icon.svg is not the brand kit's icon");
    for (const path of ["/favicon.ico", "/opengraph-image.png"]) {
      const r = await get(origin + path);
      if (r.status !== 200 || !(r.headers.get("content-type") ?? "").startsWith("image/"))
        problems.push(`${path} answered ${r.status}`);
    }
    // A deep unknown path and a capital letter (paths are case-sensitive) are both the not-found page with a 404.
    for (const path of ["/students/abc", "/Privacy"]) {
      const unknown = await get(origin + path);
      if (unknown.status !== 404 || !(await unknown.text()).includes(NOT_FOUND_WORDS))
        problems.push(`${path} is not the not-found page`);
    }
    const slash = await get(`${origin}/privacy/`);
    if (!(slash.status === 200 || redirectsTo(slash, (l) => l.endsWith("/privacy"))))
      problems.push("/privacy/ does not reach /privacy");
    const host = new URL(origin).host;
    const http = await get(`http://${host}/`);
    if (!redirectsTo(http, (l) => l.startsWith("https://")))
      problems.push(`http://${host}/ does not redirect to https`);
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
  console.log(`smoke of ${origin}: the five pages serve ${commit}; not found, http and www behave; the brand kit's icons and the link preview`);
}
