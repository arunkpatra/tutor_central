import { type BriefContent, briefPdf } from "../../pdf/brief.js";
import { type MockContent, mockPdf } from "../../pdf/mock.js";
import { renderPdf } from "../../pdf/render.js";
import { type SheetContent, sheetPdf } from "../../pdf/sheet.js";
import type { JobHandler } from "../types.js";

/** What the PDF job reads and writes as the platform (D83): the artefact, and the private bucket `pdfs`. */
export type PdfSource = {
  artefact(centre: string, id: string): Promise<{ kind: string; title: string; content: Record<string, unknown> } | null>;
  upload(bucket: "pdfs" | "exports", path: string, bytes: Uint8Array): Promise<void>;
};

/** The paths of an artefact's PDFs: the questions, and the same with the key on its own page (Share's two forms). */
export const pdfPaths = (centre: string, artefact: string) => ({ path: `${centre}/${artefact}.pdf`, keyPath: `${centre}/${artefact}-key.pdf` });

/** The `pdf` job (D90; plan decision 3): a sheet's, mock's or brief's PDF made on the server when it is kept, in the
 *  phone's layout for its kind, written to `pdfs/<centre>/<artefact>.pdf` (and `-key.pdf` for a sheet or mock, the form
 *  with the answers). One step: the render and the upload together (the bytes never sit in the job's row); a retake
 *  writes the same paths again. */
export function pdfJob(source: PdfSource): JobHandler {
  return {
    async step(job) {
      const id = (job.input as { artefact_id?: unknown }).artefact_id;
      if (!job.centreId || typeof id !== "string") return { kind: "fail", name: "make", error: { reason: "input" }, retry: false };
      try {
        const artefact = await source.artefact(job.centreId, id);
        if (!artefact) return { kind: "done", name: "make", result: { reason: "gone" } };
        const meta = { title: artefact.title };
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
        } else {
          return { kind: "done", name: "make", result: { reason: "not_printable" } };
        }
        let pages = 0;
        let bytes = 0;
        for (const form of forms) {
          const pdf = await renderPdf(form.source);
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
