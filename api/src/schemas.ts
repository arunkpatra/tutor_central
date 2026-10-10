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
  /** A mock's key (docs/spec-v2.md section 7); marked from Phase 13. */
  z.object({ kind: z.literal("mock"), artefactId: z.guid() }),
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

// V2 (docs/spec-v2.md sections 7 and 9). The values are the database's (migrations 0009 to 0013) and the app's Domain.
export const ClassLevel = z.enum(["lkg", "ukg", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]);
export type ClassLevel = z.infer<typeof ClassLevel>;
export const Language = z.enum(["en", "hinglish", "hi", "kn"]);
/** The figure templates the app draws from a typed spec (D59); a kind without a template has no figure. */
export const FigureKind = z.enum(["number_line", "fraction_bar", "place_value", "unit_circle", "triangle", "labelled_cell", "food_chain"]);
const Day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const Subject = z.string().min(1).max(80);
const Name = z.string().min(1).max(200);
const Skills = z.array(Name);
const Student = { studentId: z.guid(), studentName: z.string().min(1).max(80), tutorName: z.string().min(1).max(80) };
const V2 = { ...CentreInput.shape };

/** POST /ai/plan: the batch (null: the session for all students) and the day; the API reads the record as the user. */
export const PlanInput = z.object({ ...V2, classId: z.guid().nullable(), date: Day });
export type PlanInput = z.infer<typeof PlanInput>;

/** POST /ai/make: one artefact of a kind. Group material names skills and a level and no student; the personal kinds
 *  name the student and need their consent (start_ai_generation). */
export const MakeInput = z.discriminatedUnion("kind", [
  z.object({
    ...V2,
    kind: z.literal("sheet"),
    classLevel: ClassLevel,
    subject: Subject,
    skills: Skills.min(1).max(6),
    questions: z.number().int().min(3).max(30).default(10),
    forHomework: z.boolean().default(false),
    groupNo: z.number().int().min(1).max(9).optional(),
  }),
  z.object({ ...V2, kind: z.literal("worked_example"), classLevel: ClassLevel, subject: Subject, skill: Name }),
  z.object({ ...V2, kind: z.literal("figure"), figure: FigureKind, classLevel: ClassLevel, subject: Subject, skill: Name }),
  z.object({ ...V2, kind: z.literal("brief"), classLevel: ClassLevel, subject: Subject, chapter: Name }),
  z.object({ ...V2, kind: z.literal("check"), classLevel: ClassLevel, subject: Subject, skills: Skills.min(1).max(3) }),
  z.object({ ...V2, kind: z.literal("placement"), classLevel: ClassLevel, subject: Subject, chapters: z.array(Name).min(1).max(30) }),
  z.object({
    ...V2,
    kind: z.literal("mock"),
    classLevel: ClassLevel,
    subject: Subject,
    portions: z.array(Name).min(1).max(30),
    pattern: z.object({
      marks: z.number().int().min(5).max(100),
      durationMinutes: z.number().int().min(10).max(240),
      sections: z.array(z.object({ name: z.string().max(40), questions: z.number().int().positive(), marksEach: z.number().positive() })).optional(),
    }),
  }),
  z.object({
    ...V2,
    kind: z.literal("note"),
    ...Student,
    language: Language,
    week: z.object({ taught: Skills, right: Skills, practise: Skills, coming: z.array(z.string().max(200)) }),
  }),
  z.object({ ...V2, kind: z.literal("can_do"), ...Student, language: Language, ladder: z.record(z.string().max(40), z.string().max(40)) }),
  z.object({ ...V2, kind: z.literal("test_tomorrow"), ...Student, language: Language, subject: Subject, date: Day, portions: z.string().max(2000).optional() }),
  z.object({
    ...V2,
    kind: z.literal("gap_report"),
    studentId: z.guid(),
    marking: z
      .array(z.object({ question: z.number().int().positive(), marks: z.number().min(0), max: z.number().positive(), note: z.string().max(500).optional() }))
      .min(1),
  }),
]);
export type MakeInput = z.infer<typeof MakeInput>;

/** POST /ai/parse-school: what the school sent, as text or one photo. */
export const ParseSchoolInput = z
  .object({ ...V2, text: z.string().min(1).max(4000).optional(), image: Image.optional() })
  .refine((v) => v.text !== undefined || v.image !== undefined, { message: "text or image is needed" });
export type ParseSchoolInput = z.infer<typeof ParseSchoolInput>;

/** POST /ai/parse-textbook: a contents page, with the class and subject it is for. */
export const ParseTextbookInput = z.object({ ...V2, image: Image, classLevel: ClassLevel, subject: Subject });
export type ParseTextbookInput = z.infer<typeof ParseTextbookInput>;

/** What a contents page reads into (POST /ai/parse-textbook): the chapter names as printed and one to eight short skills
 *  under each, from the section headings; nothing from inside the book (D58). The position is the order. */
export const TextbookOutput = z.object({
  title: z.string().max(200).nullable(),
  chapters: z
    .array(z.object({ name: z.string().min(1).max(200), skills: z.array(z.string().min(1).max(200)).min(1).max(8) }))
    .min(1)
    .max(40),
});
export type TextbookOutput = z.infer<typeof TextbookOutput>;

/** The close's questions (one per skill, asked aloud, answered in a few words) and the placement's (one per chapter, the
 *  chapter's most basic idea). The app keeps the question and the tap; the answer is for the tutor's eye. */
const Question = { question: z.string().min(1).max(300), answer: z.string().min(1).max(200) };
export const ChecksOutput = z.object({ questions: z.array(z.object({ skill: Name, ...Question })).min(1).max(3) });
export type ChecksOutput = z.infer<typeof ChecksOutput>;
export const PlacementOutput = z.object({ questions: z.array(z.object({ chapter: Name, ...Question })).min(1).max(30) });
export type PlacementOutput = z.infer<typeof PlacementOutput>;

/** POST /account/revoke-apple (D38): the fresh authorization code the app got from Apple at deletion. */
export const RevokeAppleInput = z.object({ code: z.string().min(1).max(2000) });
