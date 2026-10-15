import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import { runEvals } from "../../app/evals/actions";
import EvalsPage from "../../app/evals/page";
import { withData } from "../../lib/data";
import { previewData } from "../../lib/data/preview";

// Phase 22 (D116; P22-Evals): the last run per kind, what failed, the run a person starts.
beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const page = async (q: Record<string, string> = {}) =>
  renderToStaticMarkup(await EvalsPage({ searchParams: Promise.resolve(q) }));
const digest = async (p: Promise<unknown>) =>
  ((await p.catch((e: { digest?: string }) => e)) as { digest?: string }).digest ?? "";

test("Golden sets: the tiles, a row per kind with its gate, what failed, the run card", async () => {
  const html = await page({ kinds: "plan,brief,figure,placement" });
  for (const words of [
    "Golden sets",
    "kinds with a golden set",
    "below the gate",
    "passed",
    "no run yet",
    "What failed on the last run",
    "plan-oct-8-science",
    "Run golden sets now",
    "every kind",
    "Run 4 kinds now · about ₹40",
  ])
    expect(html).toContain(words);
  expect(html).toContain(">plan<");
  expect(html).toContain(">scan_register<");
});

test("the chips choose the kinds by the address; with none chosen the run is every kind", async () => {
  const none = await page();
  expect(none).toMatch(/Run every kind now · about ₹2\d0/);
  const one = await page({ kinds: "plan" });
  expect(one).toContain("Run 1 kind now · about ₹10");
  expect(one).toContain('href="/evals?kinds=brief%2Cplan"');
  expect(one).toContain('href="/evals"');
});

test("queued and busy answer in the card", async () => {
  expect(await page({ queued: "preview-done" })).toContain("Queued: the result lands here when the batches end");
  expect(await page({ queued: "busy" })).toContain("A run is already queued: see the Jobs page");
});

test("Run: the chosen kinds that have a golden set, or every kind; busy when one is queued", async () => {
  const seen: (string[] | null)[] = [];
  const fake = (answer: string | null) => ({
    ...previewData,
    runEvals: async (_a: string, k: string[] | null) => (seen.push(k), answer),
  });
  const form = (kinds: string) => {
    const f = new FormData();
    f.set("kinds", kinds);
    return f;
  };
  expect(await withData(fake("job-1"), () => digest(runEvals(form("plan,brief,nonsense"))))).toContain(
    "/evals?queued=job-1",
  );
  expect(seen[0]).toEqual(["brief", "plan"]);
  await withData(fake("job-2"), () => digest(runEvals(form(""))));
  expect(seen[1]).toBeNull();
  expect(await withData(fake(null), () => digest(runEvals(form("plan"))))).toContain("/evals?queued=busy");
});
