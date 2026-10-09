import { expect, test } from "bun:test";
import { once, webSmoke } from "./web-smoke";

type Answer = { status: number; type?: string; body?: string; location?: string };
const html = (title: string, commit = "abc") =>
  `<html><head><title>${title}</title><meta name="tc-commit" content="${commit}"/></head></html>`;

function site(answers: Record<string, Answer>): typeof fetch {
  return (async (input: string | URL | Request) => {
    const url = String(input);
    const a = answers[url] ?? { status: 404, type: "text/html", body: html("There is nothing at this address.") };
    const headers = new Headers({ "content-type": a.type ?? "text/html" });
    if (a.location) headers.set("location", a.location);
    return new Response(a.body ?? "", { status: a.status, headers });
  }) as typeof fetch;
}

const GOOD: Record<string, Answer> = {
  "https://tutorcentral.in/": { status: 200, body: html("Tutor Central") },
  "https://tutorcentral.in/privacy": { status: 200, body: html("Privacy · Tutor Central") },
  "https://tutorcentral.in/terms": { status: 200, body: html("Terms · Tutor Central") },
  "https://tutorcentral.in/support": { status: 200, body: html("Support · Tutor Central") },
  "https://tutorcentral.in/privacy/": { status: 308, location: "/privacy" },
  "http://tutorcentral.in/": { status: 308, location: "https://tutorcentral.in/" },
  "https://www.tutorcentral.in/": { status: 308, location: "https://tutorcentral.in/" },
};

test("a right site has no problems", async () => {
  expect(await once("https://tutorcentral.in", "abc", site(GOOD))).toEqual([]);
});

test("every page must be there with the commit; an unknown path is 404 with the not-found words", async () => {
  const stale = { ...GOOD, "https://tutorcentral.in/terms": { status: 200, body: html("Terms · Tutor Central", "old") } };
  expect(await once("https://tutorcentral.in", "abc", site(stale))).toEqual(["/terms serves old, not abc"]);
  const missing = { ...GOOD };
  delete missing["https://tutorcentral.in/support"];
  expect(await once("https://tutorcentral.in", "abc", site(missing))).toEqual(["/support answered 404"]);
  const blank404 = { ...GOOD, "https://tutorcentral.in/students/abc": { status: 404, body: "<html>NOT_FOUND</html>" } };
  expect(await once("https://tutorcentral.in", "abc", site(blank404))).toEqual([
    "/students/abc is not the not-found page",
  ]);
  const capital = { ...GOOD, "https://tutorcentral.in/Privacy": { status: 200, body: html("Privacy · Tutor Central") } };
  expect(await once("https://tutorcentral.in", "abc", site(capital))).toEqual(["/Privacy is not the not-found page"]);
  const soft404 = {
    ...GOOD,
    "https://tutorcentral.in/students/abc": { status: 200, body: html("There is nothing at this address.") },
  };
  expect(await once("https://tutorcentral.in", "abc", site(soft404))).toEqual([
    "/students/abc is not the not-found page",
  ]);
});

test("http and www must redirect to the apex over https; a trailing slash must land", async () => {
  const noRedirect = { ...GOOD, "http://tutorcentral.in/": { status: 200, body: html("Tutor Central") } };
  expect(await once("https://tutorcentral.in", "abc", site(noRedirect))).toEqual([
    "http://tutorcentral.in/ does not redirect to https",
  ]);
  const www = { ...GOOD, "https://www.tutorcentral.in/": { status: 200, body: html("Tutor Central") } };
  expect(await once("https://tutorcentral.in", "abc", site(www))).toEqual([
    "https://www.tutorcentral.in/ does not redirect to https://tutorcentral.in/",
  ]);
  const slash = {
    ...GOOD,
    "https://tutorcentral.in/privacy/": { status: 404, body: html("There is nothing at this address.") },
  };
  expect(await once("https://tutorcentral.in", "abc", site(slash))).toEqual(["/privacy/ does not reach /privacy"]);
});

test("an unreachable site is one problem in words, and the smoke tries again before it gives up", async () => {
  let calls = 0;
  const down = (async () => {
    calls += 1;
    throw new Error("connection refused");
  }) as unknown as typeof fetch;
  expect(await webSmoke("https://tutorcentral.in", "abc", { fetchLike: down, attempts: 3, waitMs: 1 })).toEqual([
    "could not reach https://tutorcentral.in: connection refused",
  ]);
  expect(calls).toBe(3);
});
