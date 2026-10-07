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
