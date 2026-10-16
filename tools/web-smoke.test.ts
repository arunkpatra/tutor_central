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

/** The brand kit's icon (its cap's path) and the link preview's tag, as the export serves them (D120, D122). */
const ICON = '<svg><path d="M128 0L256 64L128 128L0 64Z" fill="#FFB547"/></svg>';
const PREVIEW = '<meta property="og:image" content="https://tutorcentral.in/opengraph-image.png?abc"/>';

const GOOD: Record<string, Answer> = {
  "https://tutorcentral.in/": { status: 200, body: html("Tutor Central").replace("</head>", `${PREVIEW}</head>`) },
  "https://tutorcentral.in/icon.svg": { status: 200, type: "image/svg+xml", body: ICON },
  "https://tutorcentral.in/favicon.ico": { status: 200, type: "image/vnd.microsoft.icon", body: "ico" },
  "https://tutorcentral.in/opengraph-image.png": { status: 200, type: "image/png", body: "png" },
  "https://tutorcentral.in/privacy": { status: 200, body: html("Privacy · Tutor Central") },
  "https://tutorcentral.in/terms": { status: 200, body: html("Terms · Tutor Central") },
  "https://tutorcentral.in/support": { status: 200, body: html("Support · Tutor Central") },
  "https://tutorcentral.in/trust": { status: 200, body: html("Trust · Tutor Central") },
  "https://tutorcentral.in/privacy/": { status: 308, location: "/privacy" },
  "http://tutorcentral.in/": { status: 308, location: "https://tutorcentral.in/" },
  "https://www.tutorcentral.in/": { status: 308, location: "https://tutorcentral.in/" },
};

test("a right site has no problems", async () => {
  expect(await once("https://tutorcentral.in", "abc", site(GOOD))).toEqual([]);
});

test("the trust page must be there too (Phase 15)", async () => {
  const { "https://tutorcentral.in/trust": _, ...without } = GOOD;
  expect((await once("https://tutorcentral.in", "abc", site(without))).length).toBeGreaterThan(0);
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

test("the brand: the kit's tab icon, the favicon and the link preview, never the book (D120, D122)", async () => {
  const book = {
    ...GOOD,
    "https://tutorcentral.in/icon.svg": { status: 200, type: "image/svg+xml", body: '<svg><path d="M20.001 19A2"/></svg>' },
  };
  expect(await once("https://tutorcentral.in", "abc", site(book))).toEqual(["/icon.svg is not the brand kit's icon"]);
  const { "https://tutorcentral.in/favicon.ico": _f, "https://tutorcentral.in/opengraph-image.png": _o, ...without } = GOOD;
  expect(await once("https://tutorcentral.in", "abc", site(without))).toEqual([
    "/favicon.ico answered 404",
    "/opengraph-image.png answered 404",
  ]);
  const noPreview = { ...GOOD, "https://tutorcentral.in/": { status: 200, body: html("Tutor Central") } };
  expect(await once("https://tutorcentral.in", "abc", site(noPreview))).toEqual(["/ has no link preview"]);
});
