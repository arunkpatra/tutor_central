import type { StudentRecord } from "../../export/record.js";
import { istDay } from "../../plan/dates.js";
import { exportPdf } from "../../pdf/export.js";
import { renderPdf } from "../../pdf/render.js";
import type { JobHandler } from "../types.js";

/** What the export job reads and writes as the platform (D83): the student's record, the centre's name and tutor, and
 *  the private bucket `exports`. */
export type ExportSource = {
  student(centre: string, id: string): Promise<StudentRecord | null>;
  centre(centre: string): Promise<{ name: string; tutor: string; phone: string }>;
  upload(bucket: "pdfs" | "exports", path: string, bytes: Uint8Array): Promise<void>;
};

/** The `export` job (D92; plan decision 5): everything kept about a student as a PDF for the parent, in
 *  `exports/<centre>/<student>/<job>.pdf`, kept seven days (the sweep removes it). One step: the read, the render and the
 *  upload (the bytes never sit in the job's row); the centre is the job's own. */
export function exportJob(source: ExportSource): JobHandler {
  return {
    async step(job, ctx) {
      const id = (job.input as { student_id?: unknown }).student_id;
      if (!job.centreId || typeof id !== "string") return { kind: "fail", name: "make", error: { reason: "input" }, retry: false };
      try {
        const record = await source.student(job.centreId, id);
        if (!record) return { kind: "fail", name: "make", error: { reason: "not_found" }, retry: false };
        const madeAt = new Date(ctx.clock.now());
        const pdf = await renderPdf(exportPdf(record, await source.centre(job.centreId), istDay(madeAt)));
        const path = `${job.centreId}/${id}/${job.id}.pdf`;
        await source.upload("exports", path, pdf.bytes);
        return { kind: "done", name: "make", result: { path, pages: pdf.pages, bytes: pdf.bytes.length, made_at: madeAt.toISOString() } };
      } catch (e) {
        return { kind: "fail", name: "make", error: { reason: "export_failed", message: e instanceof Error ? e.message : String(e) }, retry: true };
      }
    },
  };
}
