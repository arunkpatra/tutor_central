import { expect, test } from "bun:test";
import { SAMPLE } from "../src/claude-fake.js";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { type PdfSource, pdfJob } from "../src/jobs/kinds/pdf.js";
import type { Job, StepContext } from "../src/jobs/types.js";
import { snake } from "../src/plan/material.js";

// The PDF job (D90): a kept sheet, mock or brief rendered in the phone's layout and written under the centre in `pdfs`.
const CENTRE = "c0000000-0000-4000-8000-0000000000aa";
function storage(artefact: { kind: string; title: string; content: Record<string, unknown>; foot?: string } | null) {
  const uploads: { bucket: string; path: string; head: string; size: number }[] = [];
  const reads: string[] = [];
  const s: PdfSource & { uploads: typeof uploads; reads: string[] } = {
    uploads,
    reads,
    async artefact(centre) {
      reads.push(centre);
      return artefact;
    },
    async upload(bucket, path, bytes) {
      uploads.push({ bucket, path, head: new TextDecoder("latin1").decode(bytes.slice(0, 5)), size: bytes.length });
    },
  };
  return s;
}
const job = (id = "a0000000-0000-4000-8000-000000000001"): Job => ({ id: "job-1", centreId: CENTRE, kind: "pdf", attempts: 1, step: {}, input: { artefact_id: id }, leaseUntil: "" });
const ctx = (): StepContext => {
  const clock = fakeClock();
  return { db: fakeDb(), jobs: fakeJobsDb(clock), claude: fakeClaude({}), clock, requestId: "r1", worker: "w1" };
};
const sheet = SAMPLE.sheet as { title: string; instructions: string; questions: unknown[] };

test("the pdf job renders a sheet and its key form and uploads both under the centre, done with the pages", async () => {
  const s = storage({ kind: "sheet", title: "Balancing equations · set 1", content: { title: sheet.title, instructions: sheet.instructions, questions: sheet.questions, for_homework: false, light: false } });
  const out = await pdfJob(s).step(job(), ctx());
  expect(s.uploads.map((u) => [u.bucket, u.path, u.head])).toEqual([
    ["pdfs", `${CENTRE}/a0000000-0000-4000-8000-000000000001.pdf`, "%PDF-"],
    ["pdfs", `${CENTRE}/a0000000-0000-4000-8000-000000000001-key.pdf`, "%PDF-"],
  ]);
  expect(out).toMatchObject({ kind: "done", result: { path: `${CENTRE}/a0000000-0000-4000-8000-000000000001.pdf`, key_path: `${CENTRE}/a0000000-0000-4000-8000-000000000001-key.pdf`, pages: 1 } });
  expect(s.reads).toEqual([CENTRE]);
});

test("a brief is one file; an artefact gone or not printable is done with nothing written", async () => {
  const brief = storage({ kind: "brief", title: "Your brief · Chemical reactions", content: snake(SAMPLE.brief) as Record<string, unknown> });
  expect(await pdfJob(brief).step(job(), ctx())).toMatchObject({ kind: "done", result: { pages: 1 } });
  expect(brief.uploads).toHaveLength(1);
  const gone = storage(null);
  expect(await pdfJob(gone).step(job(), ctx())).toMatchObject({ kind: "done", result: { reason: "gone" } });
  const check = storage({ kind: "check", title: "Checks", content: {} });
  expect(await pdfJob(check).step(job(), ctx())).toMatchObject({ kind: "done", result: { reason: "not_printable" } });
  expect([...gone.uploads, ...check.uploads]).toEqual([]);
});

test("an upload that fails is taken again", async () => {
  const s = storage({ kind: "brief", title: "Your brief", content: snake(SAMPLE.brief) as Record<string, unknown> });
  s.upload = async () => {
    throw new Error("storage down");
  };
  expect(await pdfJob(s).step(job(), ctx())).toMatchObject({ kind: "fail", error: { reason: "pdf_failed" }, retry: true });
});

test("the job hands the artefact's foot to its forms (P20-PDF-Sheet)", async () => {
  const sources: string[] = [];
  const s = storage({ kind: "sheet", title: "Linear equations · sheet 1", foot: "Bright Minds Tuition · Class 8", content: { title: sheet.title, instructions: sheet.instructions, questions: sheet.questions, for_homework: false, light: false } });
  await pdfJob(s, { render: async (source) => (sources.push(source), { bytes: new Uint8Array([37, 80, 68, 70, 45]), pages: 1 }) }).step(job(), ctx());
  expect(sources).toHaveLength(2);
  expect(sources.every((source) => source.includes("Bright Minds Tuition · Class 8"))).toBe(true);
});

test("a figure artefact's PDF is drawn from its spec and uploaded at its path, one file (D90)", async () => {
  const s = storage({ kind: "figure", title: "A right triangle", content: { figure: { kind: "unit_circle", angle_degrees: 30 }, caption: "The angle and its ratios." } });
  const out = await pdfJob(s).step(job(), ctx());
  expect(s.uploads.map((u) => [u.bucket, u.path, u.head])).toEqual([["pdfs", `${CENTRE}/a0000000-0000-4000-8000-000000000001.pdf`, "%PDF-"]]);
  expect(out).toMatchObject({ kind: "done", result: { pages: 1 } });
  const broken = storage({ kind: "figure", title: "t", content: { figure: { kind: "triangle", angles: [100, 50, 40], labels: ["a", "b", "c"] }, caption: "c" } });
  expect(await pdfJob(broken).step(job(), ctx())).toMatchObject({ kind: "done", result: { reason: "not_printable" } });
  expect(broken.uploads).toEqual([]);
});
