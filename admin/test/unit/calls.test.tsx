import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import CallPage from "../../app/calls/[id]/page";
import CallsPage from "../../app/calls/page";
import { outcomeChip, shortCentre, shortKey } from "../../content/calls";
import { withData } from "../../lib/data";
import { previewData } from "../../lib/data/preview";
import type { Call } from "../../lib/data/types";
import held from "./call-held.json";

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});

test("the calls: the tiles, today newest first, each outcome, who started it", async () => {
  const html = renderToStaticMarkup(await CallsPage({ searchParams: Promise.resolve({}) }));
  for (const words of [
    "AI calls",
    "Today, newest first",
    "calls today",
    "median latency",
    "failed · timeout",
    "refused",
    "job plan",
    "tap",
    "deploy",
    "Haiku 5.5 · v3",
    "v4 · student",
    "742 · 69",
    'href="/calls/preview-2"',
  ])
    expect(html).toContain(words);
});

test("one call: its facts, the input, Open the job", async () => {
  const html = renderToStaticMarkup(await CallPage({ params: Promise.resolve({ id: "preview" }) }));
  for (const words of [
    "sheet · a group kind (no student)",
    "no fallback",
    "the deadline",
    "Open the job",
    "&quot;kind&quot;: &quot;sheet&quot;",
    "7a1e…c0d4",
    "c9f2…e4a1:make:4",
    "₹0.06 (6 paise)",
    "1,736 in · 0 out · billed",
  ])
    expect(html).toContain(words);
});

test("a held input shows the consent line and no input", async () => {
  const fake = { ...previewData, call: async () => held as Call };
  const html = await withData(fake, async () =>
    renderToStaticMarkup(await CallPage({ params: Promise.resolve({ id: "preview" }) })),
  );
  expect(html).toContain("Held: the student’s consent is not current");
  expect(html).toContain("note · a personal kind (a student)");
  expect(html).not.toContain("&quot;kind&quot;:");
});

test("a call that is gone is not found", async () => {
  const thrown = await CallPage({ params: Promise.resolve({ id: "gone" }) }).catch((e: { digest?: string }) => e);
  expect((thrown as { digest?: string }).digest).toContain("404");
});

test("outcomes, centres and keys in the boards' words", () => {
  expect(outcomeChip("ok", null)).toEqual({ tone: "ok", text: "ok" });
  expect(outcomeChip("failed", "timeout")).toEqual({ tone: "overdue", text: "failed · timeout" });
  expect(outcomeChip("failed", "refused")).toEqual({ tone: "due", text: "refused" });
  expect(outcomeChip("failed", "unfit")).toEqual({ tone: "due", text: "unfit" });
  expect(outcomeChip("pending", null)).toEqual({ tone: "neutral", text: "pending" });
  expect(shortCentre("Sunrise Tuition Centre")).toBe("Sunrise");
  expect(shortCentre("Bright Minds, Jayanagar")).toBe("Bright Minds");
  expect(shortCentre(null)).toBe("—");
  expect(shortKey("smoke-6d973b9")).toBe("smoke-6d973b9");
});

// Phase 20 (D99): the agent's step on a call.
test("the list shows a check's step beside its kind; a draft shows its kind alone", async () => {
  const html = renderToStaticMarkup(await CallsPage({ searchParams: Promise.resolve({ day: "today" }) }));
  expect(html).toContain("sheet · check");
  expect(html).toMatch(/>sheet</);
});

test("a call's page names its step", async () => {
  const html = renderToStaticMarkup(await CallPage({ params: Promise.resolve({ id: "preview" }) }));
  expect(html).toContain("Step");
  expect(html).toContain("draft · the first answer");
});

test("a draft refused after its check reads refused, with the finding's item", () => {
  expect(outcomeChip("failed", "check:question 1")).toEqual({ tone: "due", text: "refused · check:question 1" });
});

test("a call's Feedback row: made again with its reason, edited at Send, never the revised text; a tap's call opens its centre", async () => {
  const html = renderToStaticMarkup(await CallPage({ params: Promise.resolve({ id: "preview-feedback" }) }));
  for (const words of [
    "Feedback",
    "made again · Less about marks",
    "edited at Send",
    "the text is never shown here",
    "Open the centre",
  ])
    expect(html).toContain(words);
  expect(html).not.toContain("revised");
  const none = renderToStaticMarkup(await CallPage({ params: Promise.resolve({ id: "preview" }) }));
  expect(none).toMatch(/Feedback<\/div><div class="cell"><span class="k">Feedback<\/span>—/);
  expect(none).toContain("Open the job");
});

test("a call whose input was reduced after 90 days says so in the Held line's place, with no input (D79, D117)", async () => {
  const html = renderToStaticMarkup(await CallPage({ params: Promise.resolve({ id: "preview-reduced" }) }));
  expect(html).toContain("Reduced after 90 days: only what came back is kept (D79)");
  expect(html).not.toContain("Held: the student’s consent is not current");
  expect(html).not.toContain('"week"');
  expect(html).toContain("Output");
});

test("a reason the tutor typed is never shown on the call page: it may name a student (review R-portal-2)", async () => {
  const base = (await previewData.call("preview-feedback"))!;
  const typed = {
    ...previewData,
    call: async () => ({
      ...base,
      feedback: [{ kind: "again" as const, reason: "typed", created_at: base.created_at }],
    }),
  };
  const html = renderToStaticMarkup(
    await withData(typed, () => CallPage({ params: Promise.resolve({ id: "preview-feedback" }) })),
  );
  expect(html).toContain("made again · typed by the tutor ·");
  // Two edits in the same minute draw two lines, keyed apart.
  const twice = { ...previewData, call: async () => ({ ...base, feedback: [base.feedback![1]!, base.feedback![1]!] }) };
  const both = renderToStaticMarkup(
    await withData(twice, () => CallPage({ params: Promise.resolve({ id: "preview-feedback" }) })),
  );
  expect(both.match(/edited at Send/g)?.length).toBe(2);
});
