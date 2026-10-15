import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import ModelPage from "../../app/models/[kind]/page";
import { saveStep, switchOff, switchOn } from "../../app/models/actions";
import ModelsPage from "../../app/models/page";
import { withData } from "../../lib/data";
import { previewData } from "../../lib/data/preview";
import type { ModelChange } from "../../lib/data/types";

// Phase 22 (D113; P22-Models, P22-Model, P22-Model-SwitchOff): the kinds by their three steps, one kind with its history,
// a change as a new row, the switch with its reason.
beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});
const query = (q: Record<string, string> = {}) => Promise.resolve(q);
const kindPage = async (q: Record<string, string> = {}) =>
  renderToStaticMarkup(await ModelPage({ params: Promise.resolve({ kind: "preview" }), searchParams: query(q) }));
const digest = async (p: Promise<unknown>) =>
  ((await p.catch((e: { digest?: string }) => e)) as { digest?: string }).digest ?? "";

test("AI models: the tiles, every kind by its three steps, a switched-off kind's chip, the card", async () => {
  const html = renderToStaticMarkup(await ModelsPage({ searchParams: query() }));
  for (const words of [
    "AI models",
    "switched off",
    "changes this month",
    "last change",
    "Every kind, by its draft step",
    "Sonnet 5.5 · high",
    "fallback Haiku 5.5",
    "a wrong marks total in two mocks",
    "seed 0052",
    "How a change takes effect",
    "Within a minute",
    'href="/models/mock"',
  ])
    expect(html).toContain(words);
  expect(html).toContain(">mock<");
  expect(html.match(/>off</g)?.length).toBe(1);
  expect(html.match(/>Change</g)?.length).toBeGreaterThanOrEqual(12);
});

test("the list's Show: switched off alone", async () => {
  const html = renderToStaticMarkup(await ModelsPage({ searchParams: query({ show: "off" }) }));
  expect(html).toContain(">mock<");
  expect(html).not.toContain(">brief<");
});

test("one kind: Current, Change a step, History; the On chip and Switch off in the title line", async () => {
  const html = await kindPage();
  for (const words of [
    "AI model · brief",
    "Current",
    "Change a step",
    "Note, for the history",
    "Save: a new row from now",
    "History",
    "high effort: the slips were shallow",
    "brief v6",
    "Switch off",
  ])
    expect(html).toContain(words);
  expect(html).not.toContain("Switch off brief?");
  expect(html).not.toContain("Not a model this API knows");
});

test("Switch off asks why, quoting the tutor's words", async () => {
  const html = await kindPage({ off: "1" });
  expect(html).toContain("Switch off brief?");
  expect(html).toContain("Briefs can&#x27;t be made right now. Making briefs is switched off for a short while");
  expect(html).toContain('name="reason"');
  const empty = await kindPage({ off: "1", empty: "1" });
  expect(empty).toContain("Say why: it goes to the history and the audit.");
});

test("a kind switched off shows off and Switch on", async () => {
  const off = {
    ...previewData,
    model: async () => ({
      ...(await previewData.model("preview"))!,
      current: (await previewData.model("preview"))!.current.map((s) =>
        s.step === "draft" ? { ...s, enabled: false } : s,
      ),
    }),
  };
  const html = await withData(off, () => kindPage());
  expect(html).toContain(">off<");
  expect(html).toContain("Switch on");
});

test("a model the API does not know is refused under the field", async () => {
  expect(await kindPage({ bad: "model" })).toContain("Not a model this API knows");
});

test("Save writes the step as a new row; an unknown model goes back with the field's words; a blank note is none", async () => {
  const seen: ModelChange[] = [];
  const fake = { ...previewData, setModel: async (_a: string, c: ModelChange) => (seen.push(c), "id") };
  const form = (model: string, note = "") => {
    const f = new FormData();
    for (const [k, v] of Object.entries({
      kind: "brief",
      step: "draft",
      model,
      effort: "high",
      fallback: "claude-haiku-5-5",
      note,
    }))
      f.set(k, v);
    return f;
  };
  expect(await withData(fake, () => digest(saveStep(form("claude-sonnet-5-5"))))).toContain("/models/brief");
  expect(seen[0]).toEqual({
    kind: "brief",
    step: "draft",
    model: "claude-sonnet-5-5",
    effort: "high",
    fallback: "claude-haiku-5-5",
    enabled: true,
    note: null,
  });
  expect(await withData(fake, () => digest(saveStep(form("claude-sonnet-6-0", "x"))))).toContain(
    "/models/brief?bad=model",
  );
  expect(seen).toHaveLength(1);
});

test("Switch off needs a reason and writes the draft disabled with the current values; Switch on writes it enabled", async () => {
  const seen: ModelChange[] = [];
  const fake = { ...previewData, setModel: async (_a: string, c: ModelChange) => (seen.push(c), "id") };
  const f = new FormData();
  f.set("kind", "brief");
  f.set("reason", "  ");
  expect(await withData(fake, () => digest(switchOff(f)))).toContain("/models/brief?off=1&empty=1");
  f.set("reason", "two wrong slips");
  expect(await withData(fake, () => digest(switchOff(f)))).toContain("/models/brief");
  expect(seen[0]).toEqual({
    kind: "brief",
    step: "draft",
    model: "claude-sonnet-5-5",
    effort: "high",
    fallback: "claude-haiku-5-5",
    enabled: false,
    note: "two wrong slips",
  });
  await withData(fake, () => digest(switchOn(f)));
  expect(seen[1]).toMatchObject({ step: "draft", enabled: true, note: "switched on" });
});
