import { z } from "zod";

const Common = { subject: z.string().min(1).max(80), classLevel: z.string().min(1).max(40) };
/** Recorded with the input (never sent to Claude), so a result read back from the database names its class again. */
const ClassId = { classId: z.guid().optional() };
const Topic = z.string().min(1).max(200);
export const Level = z.enum(["easy", "medium", "hard"]);

/** POST /ai/generate: one body per kind of material. The note carries the names the register knows; the API never
 *  sees an id but the centre's. */
export const GenerateInput = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("paper"),
    ...Common,
    ...ClassId,
    topic: Topic,
    level: Level.default("medium"),
    marks: z.number().int().min(5).max(100).default(20),
    questions: z.number().int().min(1).max(50).default(10),
  }),
  z.object({
    kind: z.literal("homework"),
    ...Common,
    ...ClassId,
    topic: Topic,
    level: Level.default("medium"),
    questions: z.number().int().min(1).max(30).default(5),
  }),
  z.object({
    kind: z.literal("worksheet"),
    ...Common,
    ...ClassId,
    topic: Topic,
    level: Level.default("medium"),
    questions: z.number().int().min(1).max(40).default(10),
    withAnswers: z.boolean().default(true),
  }),
  z.object({
    kind: z.literal("progress_note"),
    ...Common,
    /** Recorded, never sent to Claude: a note read back from History can still be sent to the parent. */
    studentId: z.guid().optional(),
    studentName: z.string().min(1).max(80),
    parentName: z.string().max(80).optional(),
    observations: z.string().min(1).max(2000),
    attendanceLine: z.string().max(120).optional(),
    tone: z.enum(["warm", "plain"]).default("warm"),
    tutorName: z.string().max(80),
    centreName: z.string().max(120),
  }),
]);
export type GenerateInput = z.infer<typeof GenerateInput>;
export type PaperInput = Extract<GenerateInput, { kind: "paper" }>;
export type HomeworkInput = Extract<GenerateInput, { kind: "homework" }>;
export type WorksheetInput = Extract<GenerateInput, { kind: "worksheet" }>;
export type NoteInput = Extract<GenerateInput, { kind: "progress_note" }>;

/** One photo: the device reduces it to 2000 px as a JPEG, so a real page is well under this. */
const Image = z.object({
  imageBase64: z.string().min(1).max(4_000_000),
  mediaType: z.enum(["image/jpeg", "image/png", "image/webp"]),
});

/** POST /ai/scan-register: one photo of a register. */
export const ScanRegisterInput = Image;
export type ScanRegisterInput = z.infer<typeof ScanRegisterInput>;

/** The marking scheme: typed by the tutor, or the answer key of a paper the centre created. */
export const Scheme = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("typed"), text: z.string().min(1).max(4000) }),
  z.object({ kind: z.literal("paper"), generationId: z.guid() }),
]);

/** POST /ai/check-paper: up to six page photos, together under Vercel's body limit, and the scheme. */
export const CheckPaperInput = z
  .object({ pages: z.array(Image).min(1).max(6), scheme: Scheme, studentName: z.string().min(1).max(80) })
  .refine((v) => v.pages.reduce((n, p) => n + p.imageBase64.length, 0) <= 4_200_000, {
    message: "pages: too many characters in one request",
  });
export type CheckPaperInput = z.infer<typeof CheckPaperInput>;

/** Every AI body names the centre; start_ai_generation refuses one the tutor is not a member of. */
export const CentreInput = z.object({ centreId: z.guid() });

// The outputs Claude is held to (structured outputs, src/claude.ts); the app decodes the same shapes.
export const PaperOutput = z.object({
  title: z.string(),
  sections: z
    .array(
      z.object({
        title: z.string(),
        marksEach: z.number().int().min(1),
        questions: z
          .array(z.object({ number: z.number().int().min(1), text: z.string(), marks: z.number().int().min(1), answer: z.string() }))
          .min(1),
      }),
    )
    .min(1),
});
export type PaperOutput = z.infer<typeof PaperOutput>;

export const QuestionSetOutput = z.object({
  title: z.string(),
  instructions: z.string().nullable(),
  questions: z.array(z.object({ number: z.number().int().min(1), text: z.string(), answer: z.string() })).min(1),
});
export type QuestionSetOutput = z.infer<typeof QuestionSetOutput>;

export const NoteOutput = z.object({ note: z.string().min(1) });
export type NoteOutput = z.infer<typeof NoteOutput>;

export const ScanOutput = z.object({
  rows: z.array(z.object({ name: z.string().min(1), phone: z.string().nullable(), fee: z.number().int().min(0).nullable() })),
});
export type ScanOutput = z.infer<typeof ScanOutput>;

/** A mark above its question's maximum is not refused here: the app clamps it on arrival and says so. */
export const CheckOutput = z.object({
  questions: z
    .array(
      z.object({
        number: z.number().int().min(1),
        text: z.string(),
        note: z.string(),
        marks: z.number().int().min(0),
        of: z.number().int().min(1),
      }),
    )
    .min(1),
  summary: z.string(),
});
export type CheckOutput = z.infer<typeof CheckOutput>;
