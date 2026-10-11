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
  /** A mock's key (docs/spec-v2.md section 7): the mock's generation output, the one table the API reads. */
  z.object({ kind: z.literal("mock"), generationId: z.guid() }),
]);

/** POST /ai/check-paper: up to six page photos, together under Vercel's body limit, and the scheme. */
export const CheckPaperInput = z
  .object({
    pages: z.array(Image).min(1).max(6),
    scheme: Scheme,
    studentName: z.string().min(1).max(80),
    /** Sent for a mock (Phase 13), so start_ai_generation asks the student's consent (D62). */
    studentId: z.guid().optional(),
  })
  .refine((v) => v.pages.reduce((n, p) => n + p.imageBase64.length, 0) <= 4_200_000, {
    message: "pages: too many characters in one request",
  })
  // A mock is marked for one named student: without the id the gate could not ask their consent (D62).
  .refine((v) => v.scheme.kind !== "mock" || v.studentId !== undefined, { message: "studentId: a mock's marking names the student" });
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
export type Language = z.infer<typeof Language>;
/** The figure templates the app draws from a typed spec (D59); a kind without a template has no figure. */
export const FigureKind = z.enum(["number_line", "fraction_bar", "place_value", "unit_circle", "triangle", "labelled_cell", "food_chain"]);
export type FigureKind = z.infer<typeof FigureKind>;
const Day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const Subject = z.string().min(1).max(80);
const Name = z.string().min(1).max(200);
const Skills = z.array(Name);
const Student = { studentId: z.guid(), studentName: z.string().min(1).max(80), tutorName: z.string().min(1).max(80) };
const V2 = { ...CentreInput.shape };
/** Who a parent's message is for and in what words (Phase 14's note, can-now-do and not-on-track message). */
const Parent = { parentName: z.string().max(80).optional(), centreName: z.string().max(120), language: Language, classLevel: ClassLevel };

/** POST /ai/plan: the groups whose record names no skill yet (new students, no book). The API names a first chapter and
 *  skill per group for the class, subject and month of the school year. No student. */
export const PlanInput = z.object({
  ...V2,
  classId: z.guid().nullable(),
  date: Day,
  month: z.number().int().min(1).max(12),
  groups: z.array(z.object({ groupNo: z.number().int().min(1).max(3), classLevel: ClassLevel, subject: Subject }).strict()).min(1).max(3),
});
export type PlanInput = z.infer<typeof PlanInput>;
export const PlanOutput = z.object({ groups: z.array(z.object({ groupNo: z.number().int().min(1).max(3), chapter: Name, skill: Name })).min(1) });
export type PlanOutput = z.infer<typeof PlanOutput>;


/** The mock's pattern: the board's blueprint as the syllabus data writes it, or the app's default by class. */
export const MockPattern = z.object({
  marks: z.number().int().min(5).max(100),
  durationMinutes: z.number().int().min(10).max(240),
  sections: z.array(z.object({ name: z.string().max(40), questions: z.number().int().positive(), marksEach: z.number().positive() })).optional(),
});
export type MockPattern = z.infer<typeof MockPattern>;

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
    /** Make it again: one of the menu's words or the tutor's own, in the prompt (P10-Sheet-Regenerate). */
    reason: z.string().min(1).max(200).optional(),
  }).strict(),
  // The plan's group material is strict: a body that names a student is a 400 (D62; nothing personal is made here).
  z.object({ ...V2, kind: z.literal("worked_example"), classLevel: ClassLevel, subject: Subject, skill: Name }).strict(),
  z.object({ ...V2, kind: z.literal("figure"), figure: FigureKind, classLevel: ClassLevel, subject: Subject, skill: Name }).strict(),
  z.object({ ...V2, kind: z.literal("brief"), classLevel: ClassLevel, subject: Subject, chapter: Name }).strict(),
  z.object({ ...V2, kind: z.literal("check"), classLevel: ClassLevel, subject: Subject, skills: Skills.min(1).max(3) }),
  z.object({ ...V2, kind: z.literal("placement"), classLevel: ClassLevel, subject: Subject, chapters: z.array(Name).min(1).max(30) }),
  z.object({
    ...V2,
    kind: z.literal("mock"),
    classLevel: ClassLevel,
    subject: Subject,
    title: z.string().min(1).max(120),
    portions: z.array(Name).min(1).max(30),
    pattern: MockPattern,
  }).strict(),
  // The parents' messages (Phase 14): the student is named, so each needs their consent (start_ai_generation). The
  // facts are the app's, worked out from the record on the phone (Domain's NoteWeek, CanDoWeek); the model words them.
  z.object({
    ...V2,
    kind: z.literal("note"),
    ...Student,
    ...Parent,
    week: z.object({
      monday: Day,
      taught: Skills.max(6),
      right: z.string().max(120).optional(),
      practise: Skills.max(3),
      coming: z.array(z.string().max(200)).max(3),
      attendance: z.string().max(80).optional(),
    }),
  }),
  z.object({
    ...V2,
    kind: z.literal("can_do"),
    ...Student,
    ...Parent,
    ladder: z.object({
      movedUp: z.array(z.object({ area: z.enum(["reading", "writing", "numbers"]), step: z.string().min(1).max(40) })).max(3),
      canDo: z.array(z.string().min(1).max(80)).min(1).max(4),
      atHome: z.string().min(1).max(160),
      next: z.array(z.string().min(1).max(80)).max(3),
    }),
  }),
  z.object({
    ...V2,
    kind: z.literal("not_on_track"),
    ...Student,
    ...Parent,
    hard: z.array(Name).min(1).max(3),
    reasons: z.array(z.string().max(200)).max(4),
    doing: z.string().min(1).max(200),
    atHome: z.string().max(200).optional(),
  }),
  z.object({
    ...V2,
    kind: z.literal("test_tomorrow"),
    ...Student,
    centreName: z.string().max(120),
    parentName: z.string().max(80).optional(),
    language: Language,
    subject: Subject,
    title: z.string().min(1).max(120),
    date: Day,
    portions: z.string().max(500).optional(),
    revise: z.string().max(200).optional(),
  }),
  z.object({
    ...V2,
    kind: z.literal("gap_report"),
    studentId: z.guid(),
    classLevel: ClassLevel,
    subject: Subject,
    daysLeft: z.number().int().min(1).max(3),
    bySkill: z.array(z.object({ skill: Name, right: z.number().int().min(0), of: z.number().int().min(1), note: z.string().max(300).optional() })).min(1).max(12),
  }),
]);
export type MakeInput = z.infer<typeof MakeInput>;
export type SheetInput = Extract<MakeInput, { kind: "sheet" }>;
export type MockInput = Extract<MakeInput, { kind: "mock" }>;
export type GapReportInput = Extract<MakeInput, { kind: "gap_report" }>;
export type TestTomorrowInput = Extract<MakeInput, { kind: "test_tomorrow" }>;
export type WeeklyNoteInput = Extract<MakeInput, { kind: "note" }>;
export type CanDoInput = Extract<MakeInput, { kind: "can_do" }>;
export type NotOnTrackInput = Extract<MakeInput, { kind: "not_on_track" }>;

/** A sheet is a question set (V1's homework and worksheet shape): the app's `SheetContent` decodes it. */
export const SheetOutput = QuestionSetOutput;
export type SheetOutput = z.infer<typeof SheetOutput>;

export const WorkedExampleOutput = z.object({
  problem: z.string().min(1).max(300),
  steps: z.array(z.object({ title: z.string().min(1).max(80), working: z.string().min(1).max(400) })).min(2).max(6),
  slip: z.string().min(1).max(300),
});
export type WorkedExampleOutput = z.infer<typeof WorkedExampleOutput>;

/** The seven figure templates (D59), each with the rule the app checks again before drawing (Domain's FigureSpec). */
const Label = z.string().min(1).max(40);
export const Figure = z.discriminatedUnion("kind", [
  z
    .object({ kind: z.literal("number_line"), from: z.number().int(), to: z.number().int(), step: z.number().int().min(1), start: z.number().int(), jumps: z.array(z.number().int()).min(1).max(8) })
    .refine((f) => f.from < f.to && (f.to - f.from) / f.step <= 40, { message: "the line has 1 to 40 steps" })
    .refine((f) => f.start >= f.from && f.start <= f.to, { message: "start is on the line" })
    .refine((f) => f.jumps.every((j) => j !== 0) && f.start + f.jumps.reduce((a, b) => a + b, 0) >= f.from && f.start + f.jumps.reduce((a, b) => a + b, 0) <= f.to, { message: "the landing is on the line" }),
  z.object({ kind: z.literal("fraction_bar"), parts: z.number().int().min(1).max(24), shaded: z.number().int().min(0), label: Label }).refine((f) => f.shaded <= f.parts, { message: "shaded parts fit the whole" }),
  z.object({ kind: z.literal("place_value"), number: z.number().int().min(0).max(9_999_999) }),
  z.object({ kind: z.literal("unit_circle"), angleDegrees: z.number().int().min(0).max(360) }),
  z.object({ kind: z.literal("triangle"), angles: z.array(z.number().int().min(1).max(178)).length(3), labels: z.array(Label).length(3) }).refine((f) => f.angles.reduce((a, b) => a + b, 0) === 180, { message: "the angles sum to 180" }),
  z.object({ kind: z.literal("labelled_cell"), cell: z.enum(["plant", "animal"]), labels: z.array(Label).min(1).max(5) }),
  z.object({ kind: z.literal("food_chain"), links: z.array(Label).min(2).max(6) }),
]);
export type Figure = z.infer<typeof Figure>;
export const FigureOutput = z.object({ figure: Figure, caption: z.string().min(1).max(200) });
export type FigureOutput = z.infer<typeof FigureOutput>;

export const BriefOutput = z.object({
  about: z.string().min(1).max(1200),
  mistakes: z.array(z.object({ title: z.string().min(1).max(80), howToCatch: z.string().min(1).max(300) })).length(3),
  workedExample: WorkedExampleOutput,
  words: z.array(z.string().min(1).max(160)).length(3),
});
export type BriefOutput = z.infer<typeof BriefOutput>;

/** POST /ai/parse-school: what the school sent, as text or one photo, with the day it is read on (so "Friday 16th Oct"
 *  becomes a date), the centre's school names and class levels (so a named school and "Class VIII B" resolve), and
 *  nothing about a student (D62). */
export const ParseSchoolInput = z
  .object({
    ...V2,
    text: z.string().min(1).max(4000).optional(),
    image: Image.optional(),
    today: Day,
    schools: z.array(z.string().min(1).max(120)).max(20).optional(),
    classLevels: z.array(ClassLevel).max(12).optional(),
  })
  .strict()
  .refine((v) => v.text !== undefined || v.image !== undefined, { message: "text or image is needed" });
export type ParseSchoolInput = z.infer<typeof ParseSchoolInput>;

/** One item as read: the words the school used; a date the message does not give is null (the tutor sets it). */
export const ParsedItem = z.object({
  kind: z.enum(["exam", "homework", "notice", "holiday"]),
  title: z.string().min(1).max(120),
  subject: z.string().max(80).nullable(),
  date: Day.nullable(),
  endDate: Day.nullable(),
  classLevel: ClassLevel.nullable(),
  school: z.string().max(120).nullable(),
  studentName: z.string().max(80).nullable(),
  portions: z.string().max(500).nullable(),
});
export type ParsedItem = z.infer<typeof ParsedItem>;
export const ParseSchoolOutput = z.object({ items: z.array(ParsedItem).max(12) });
export type ParseSchoolOutput = z.infer<typeof ParseSchoolOutput>;

/** A mock (P10-Mock): V1's paper shape with the skill each question tests (the gap report's tallies) and the time. The
 *  route refuses an answer whose marks do not sum to the pattern's. */
export const MockOutput = z.object({
  title: z.string().min(1).max(120),
  durationMinutes: z.number().int().min(10).max(240),
  sections: z
    .array(
      z.object({
        name: z.string().min(1).max(40),
        marksEach: z.number().int().min(1),
        questions: z
          .array(z.object({ number: z.number().int().min(1), text: z.string().min(1).max(600), marks: z.number().int().min(1), answer: z.string().min(1).max(600), skill: Name }))
          .min(1),
      }),
    )
    .min(1)
    .max(5),
});
export type MockOutput = z.infer<typeof MockOutput>;
export const mockMarks = (mock: MockOutput) => mock.sections.flatMap((s) => s.questions).reduce((n, q) => n + q.marks, 0);

/** The gap report's words (P10-GapReport): a line on what the mock showed and one line per day left. The tallies by
 *  skill are the app's arithmetic. */
export const GapReportOutput = z.object({
  summary: z.string().min(1).max(200),
  days: z.array(z.object({ title: z.string().min(1).max(40), line: z.string().min(1).max(200) })).min(1).max(3),
});
export type GapReportOutput = z.infer<typeof GapReportOutput>;

/** A message to a parent in their language with the English beside it for the tutor (Test tomorrow, the note,
 *  can-now-do, not on track). 600 characters; the prompts ask for 500 and no signature (the app signs once). */
export const MessageOutput = z.object({ message: z.string().min(1).max(600), english: z.string().min(1).max(600) });
export type MessageOutput = z.infer<typeof MessageOutput>;
export const TestTomorrowOutput = MessageOutput;
export type TestTomorrowOutput = MessageOutput;

/** POST /ai/read-marks: one or two photos of a printed report card or a marked test, the student (named, so their
 *  consent is asked), and the subjects the tutor keeps for them so the rows use the same names. */
export const ReadMarksInput = z
  .object({ ...V2, studentId: z.guid(), studentName: z.string().min(1).max(80), pages: z.array(Image).min(1).max(2), subjects: z.array(Subject).max(12).optional() })
  .refine((v) => v.pages.reduce((n, p) => n + p.imageBase64.length, 0) <= 4_200_000, { message: "pages: too many characters in one request" });
export type ReadMarksInput = z.infer<typeof ReadMarksInput>;
export const ReadMarksOutput = z.object({
  marks: z
    .array(z.object({ subject: Subject, test: z.string().min(1).max(120), date: Day.nullable(), score: z.number().min(0), max: z.number().min(1) }))
    .max(12),
});
export type ReadMarksOutput = z.infer<typeof ReadMarksOutput>;


/** POST /ai/parse-textbook: a contents page, with the class and subject it is for. */
export const ParseTextbookInput = z.object({ ...V2, image: Image, classLevel: ClassLevel, subject: Subject });
export type ParseTextbookInput = z.infer<typeof ParseTextbookInput>;

/** What a contents page reads into (POST /ai/parse-textbook): the chapter names as printed and one to eight short skills
 *  under each, from the section headings; nothing from inside the book (D58). The position is the order. */
export const TextbookOutput = z.object({
  title: z.string().max(200).nullable(),
  chapters: z
    .array(z.object({ name: z.string().min(1).max(200), skills: z.array(z.string().min(1).max(200)).min(1).max(8) }))
    // None when the page holds no chapters (the prompt asks for that): the route refuses it in words.
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
