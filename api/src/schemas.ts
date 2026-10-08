import { z } from "zod";

const Common = { subject: z.string().min(1).max(80), classLevel: z.string().min(1).max(40) };
const Topic = z.string().min(1).max(200);

/** POST /ai/generate: one body per kind of material. */
export const GenerateInput = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("paper"),
    ...Common,
    topic: Topic,
    marks: z.number().int().min(5).max(100).default(20),
    questions: z.number().int().min(1).max(50).default(10),
  }),
  z.object({ kind: z.literal("homework"), ...Common, topic: Topic, questions: z.number().int().min(1).max(30).default(5) }),
  z.object({ kind: z.literal("worksheet"), ...Common, topic: Topic, questions: z.number().int().min(1).max(40).default(10) }),
  z.object({
    kind: z.literal("progress_note"),
    ...Common,
    studentName: z.string().min(1).max(80),
    observations: z.string().min(1).max(2000),
    tone: z.enum(["warm", "plain"]).default("warm"),
  }),
]);
export type GenerateInput = z.infer<typeof GenerateInput>;

const Image = z.object({
  imageBase64: z.string().min(1).max(8_000_000),
  mediaType: z.enum(["image/jpeg", "image/png", "image/webp"]),
});

/** POST /ai/scan-register: one photo of a register. */
export const ScanRegisterInput = Image;
export type ScanRegisterInput = z.infer<typeof ScanRegisterInput>;

/** POST /ai/check-paper: up to six page photos and the marking scheme. */
export const CheckPaperInput = z.object({ pages: z.array(Image).min(1).max(6), markingScheme: z.string().min(1).max(4000) });
export type CheckPaperInput = z.infer<typeof CheckPaperInput>;

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
