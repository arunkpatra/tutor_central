import { afterAll, beforeAll, expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { renderToStaticMarkup } from "react-dom/server";
import { samePage } from "../../components/PageLink";
import { buttonState } from "../../components/SubmitButton";
import { PENDING } from "../../content/words";

const ROOT = join(import.meta.dir, "..", "..");
const APP = join(ROOT, "app");
/** The door's pages load at once: they read no centre (and redirect within a moment when they must). */
const DOOR = ["sign-in", "mfa", "refused"];

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});

function files(dir: string, keep: (f: string) => boolean): string[] {
  return readdirSync(dir).flatMap((f) => {
    const p = join(dir, f);
    return statSync(p).isDirectory() ? files(p, keep) : keep(f) ? [p] : [];
  });
}

const signedIn = files(APP, (f) => f === "page.tsx")
  .map((p) => relative(APP, dirname(p)))
  .filter((d) => d !== "" && !DOOR.some((o) => d === o || d.startsWith(`${o}/`)));

test("every signed-in page has a loading state of its own (D97)", () => {
  expect(signedIn.length).toBe(10);
  for (const d of signedIn)
    expect({
      page: d,
      loading: statSync(join(APP, d, "loading.tsx"), { throwIfNoEntry: false })?.isFile() ?? false,
    }).toEqual({ page: d, loading: true });
});

test("a loading state shows the page's frame, its title and the moving bar, and says it is busy", async () => {
  for (const d of signedIn) {
    const { default: Loading } = await import(join(APP, d, "loading.tsx"));
    const html = renderToStaticMarkup(<Loading />);
    expect({ page: d, frame: html.includes('aria-label="Pages"') }).toEqual({ page: d, frame: true });
    expect({ page: d, bar: html.includes('class="loadBar"') }).toEqual({ page: d, bar: true });
    expect({ page: d, busy: html.includes('aria-busy="true"') }).toEqual({ page: d, busy: true });
  }
  const { default: Centres } = await import(join(APP, "centres", "loading.tsx"));
  const centres = renderToStaticMarkup(<Centres />);
  expect(centres).toContain("Centres</h1>");
  expect(centres).toContain('aria-current="page"');
});

test("no plain link in the portal: every one is PageLink (Next's Link with the pending bar), so a click never reloads the page (D97)", () => {
  const sources = [
    ...files(APP, (f) => f.endsWith(".tsx")),
    ...files(join(ROOT, "components"), (f) => f.endsWith(".tsx")),
  ];
  const plain = sources.filter((p) => /<a[\s>]/.test(readFileSync(p, "utf8"))).map((p) => relative(ROOT, p));
  expect(plain).toEqual([]);
  const direct = sources
    .filter((p) => readFileSync(p, "utf8").includes('from "next/link"'))
    .map((p) => relative(ROOT, p));
  expect(direct).toEqual(["components/PageLink.tsx"]);
});

test("a working button shows its own words, the spinner, and takes no second press", () => {
  expect(buttonState(false, PENDING.signIn)).toEqual({ busy: false, words: null });
  expect(buttonState(true, PENDING.signIn)).toEqual({ busy: true, words: "Signing in…" });
  expect(PENDING).toEqual({
    signIn: "Signing in…",
    verify: "Verifying…",
    open: "Opening the record…",
    retry: "Retrying…",
    cancel: "Cancelling…",
    acknowledge: "Acknowledging…",
  });
});

test("every form that runs a server action has a working button", () => {
  const sources = files(APP, (f) => f.endsWith(".tsx")).map(
    (p) => [relative(ROOT, p), readFileSync(p, "utf8")] as const,
  );
  for (const [path, text] of sources.filter(([, t]) => /<form action=\{/.test(t)))
    expect({ path, working: text.includes("<SubmitButton") && !/<Button[\s>]/.test(text) }).toEqual({
      path,
      working: true,
    });
});

test("a link within the page on screen is not prefetched, so it shows the bar while pending; another page is", () => {
  expect(samePage("/jobs?state=queued", "/jobs")).toBe(true);
  expect(samePage("/jobs?state=queued&open=j1", "/jobs")).toBe(true);
  expect(samePage("/centres/c1?ask=1", "/centres/c1")).toBe(true);
  expect(samePage("/centres/c1", "/centres")).toBe(false);
  expect(samePage("/cost", "/centres")).toBe(false);
});
