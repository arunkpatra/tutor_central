import { type BriefContent, briefPdf } from "../../pdf/brief.js";
import { type MockContent, mockPdf } from "../../pdf/mock.js";
import { renderPdf } from "../../pdf/render.js";
import { type SheetContent, sheetPdf } from "../../pdf/sheet.js";
import { figurePdf } from "../../pdf/figure.js";
import { paperMeta, paperPdf, type V1Result } from "../../pdf/paper.js";
import { camel } from "../../plan/material.js";
import { FigureOutput } from "../../schemas.js";
import type { JobHandler, StepOutcome } from "../types.js";

/** What the PDF job reads and writes as the platform (D83): the artefact, and the private bucket `pdfs`. */
export type PdfSource = {
  /** The artefact, with the foot its pages carry: the centre's name, and its batch's when it came from a plan. */
  artefact(centre: string, id: string): Promise<{ kind: string; title: string; content: Record<string, unknown>; foot?: string } | null>;
  /** A V1 result (Phase 21 decision 9): its kind, its output and the request it was made from (the recorded input),
   *  with the centre's name for the foot; null when there is none of the centre's. */
  generation(centre: string, id: string): Promise<{ kind: string; output: Record<string, unknown> | null; input: Record<string, unknown>; foot?: string } | null>;
  upload(bucket: "pdfs" | "exports", path: string, bytes: Uint8Array): Promise<void>;
};

/** A V1 result's PDF: one file, its key on the last page unless a worksheet left it out (Phase 21 decision 9). */
export const generationPdfPath = (centre: string, generation: string) => `${centre}/gen-${generation}.pdf`;

/** The paths of an artefact's PDFs: the questions, and the same with the key on its own page (Share's two forms). */
export const pdfPaths = (centre: string, artefact: string) => ({ path: `${centre}/${artefact}.pdf`, keyPath: `${centre}/${artefact}-key.pdf` });

/** The `pdf` job (D90; plan decision 3; Phase 20 adds the figure, drawn from its spec): a sheet's, mock's, brief's or figure's PDF made on the server when it is kept, in the
 *  phone's layout for its kind, written to `pdfs/<centre>/<artefact>.pdf` (and `-key.pdf` for a sheet or mock, the form
 *  with the answers). One step: the render and the upload together (the bytes never sit in the job's row); a retake
 *  writes the same paths again. */
export function pdfJob(source: PdfSource, deps: { render: typeof renderPdf } = { render: renderPdf }): JobHandler {
  return {
    async step(job) {
      const generation = (job.input as { generation_id?: unknown }).generation_id;
      if (job.centreId && typeof generation === "string") return generationPdf(source, deps.render, job.centreId, generation);
      const id = (job.input as { artefact_id?: unknown }).artefact_id;
      if (!job.centreId || typeof id !== "string") return { kind: "fail", name: "make", error: { reason: "input" }, retry: false };
      try {
        const artefact = await source.artefact(job.centreId, id);
        if (!artefact) return { kind: "done", name: "make", result: { reason: "gone" } };
        const meta = { title: artefact.title, foot: artefact.foot };
        const forms: { path: string; source: string }[] = [];
        const { path, keyPath } = pdfPaths(job.centreId, id);
        if (artefact.kind === "sheet") {
          const content = artefact.content as SheetContent;
          forms.push({ path, source: sheetPdf(content, meta, false) }, { path: keyPath, source: sheetPdf(content, meta, true) });
        } else if (artefact.kind === "mock") {
          const content = artefact.content as unknown as MockContent;
          forms.push({ path, source: mockPdf(content, meta, false) }, { path: keyPath, source: mockPdf(content, meta, true) });
        } else if (artefact.kind === "brief") {
          forms.push({ path, source: briefPdf(artefact.content as unknown as BriefContent, meta) });
        } else if (artefact.kind === "figure") {
          // Kept snake-cased (the app's keys); drawn only when the spec keeps its template's rule.
          const figure = FigureOutput.safeParse(camel(artefact.content));
          if (!figure.success) return { kind: "done", name: "make", result: { reason: "not_printable" } };
          forms.push({ path, source: figurePdf(figure.data.figure, { ...meta, caption: figure.data.caption }) });
        } else {
          return { kind: "done", name: "make", result: { reason: "not_printable" } };
        }
        let pages = 0;
        let bytes = 0;
        for (const form of forms) {
          const pdf = await deps.render(form.source);
          await source.upload("pdfs", form.path, pdf.bytes);
          if (form.path === path) [pages, bytes] = [pdf.pages, pdf.bytes.length];
        }
        return { kind: "done", name: "make", result: { path, ...(forms.length > 1 ? { key_path: keyPath } : {}), pages, bytes } };
      } catch (e) {
        return { kind: "fail", name: "make", error: { reason: "pdf_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
      }
    },
  };
}

const PRINTED = new Set(["paper", "homework", "worksheet"]);

/** A V1 result's PDF made from its generation and written to `pdfs/<centre>/gen-<id>.pdf`; a note or a register is not
 *  printed, a result gone is done with nothing written. */
async function generationPdf(source: PdfSource, render: typeof renderPdf, centre: string, id: string): Promise<StepOutcome> {
  try {
    const row = await source.generation(centre, id);
    if (!row?.output) return { kind: "done", name: "make", result: { reason: "gone" } };
    if (!PRINTED.has(row.kind)) return { kind: "done", name: "make", result: { reason: "not_printable" } };
    const result = { kind: row.kind, output: row.output } as unknown as V1Result;
    const meta = paperMeta(result.kind, row.input, result.output);
    const path = generationPdfPath(centre, id);
    const pdf = await render(paperPdf(result, { ...meta, foot: row.foot }, meta.withKey));
    await source.upload("pdfs", path, pdf.bytes);
    return { kind: "done", name: "make", result: { path, pages: pdf.pages, bytes: pdf.bytes.length } };
  } catch (e) {
    return { kind: "fail", name: "make", error: { reason: "pdf_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
  }
}
