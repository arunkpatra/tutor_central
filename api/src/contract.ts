import type { z } from "zod";
import table from "../models.json" with { type: "json" };
import { SAMPLE } from "./claude-fake.js";
import type { AIKind } from "./db.js";
import { pausedWords } from "./errors.js";
import { EVAL_KINDS } from "./evals/cases.js";
import { noteContent } from "./jobs/kinds/note-day.js";
import versions from "./prompts/versions.json" with { type: "json" };
import { BODY_BASE64_MAX, CheckPaperInput, MakeInput, PlanInput, ReadMarksInput, ScanRegisterInput, TUTOR_SAYS_MAX } from "./schemas.js";

/** What the app is held to (D80): the limits and lists the API's schemas set, read from the schemas themselves, so a limit
 *  lives once. `bun contract` writes them into the app's `APIContract.swift`; `bun check` fails when that file is stale. */
export type Contract = { limits: Record<string, number>; lists: Record<string, string[]> };

type Node = { _zod: { def: { type: string; innerType?: Node; element?: Node; checks?: { _zod: { def: { check: string; maximum?: number; value?: number } } }[] } } };

/** The schema under optional and default. */
function unwrapped(schema: unknown): Node {
  let node = schema as Node;
  while (node._zod.def.innerType) node = node._zod.def.innerType;
  return node;
}

/** The largest length or count a schema allows, through optional and default. */
function most(schema: unknown): number {
  const node = unwrapped(schema);
  const check = node._zod.def.checks?.map((c) => c._zod.def).find((d) => d.check === "max_length" || d.check === "less_than");
  const max = check?.maximum ?? check?.value;
  if (max === undefined) throw new Error(`no maximum on a ${node._zod.def.type}`);
  return max;
}
const element = (schema: unknown) => unwrapped(schema)._zod.def.element as unknown;

function make<K extends MakeInput["kind"]>(kind: K) {
  const option = MakeInput.options.find((o) => o.shape.kind.value === kind);
  if (!option) throw new Error(`no /ai/make kind ${kind}`);
  return option.shape as Record<string, z.ZodType>;
}

export function contract(): Contract {
  const note = make("note");
  const week = (note.week as unknown as z.ZodObject).shape as Record<string, z.ZodType>;
  const ladder = (make("can_do").ladder as unknown as z.ZodObject).shape as Record<string, z.ZodType>;
  const notOnTrack = make("not_on_track");
  const gap = make("gap_report");
  const bySkill = (element(gap.bySkill) as z.ZodObject).shape as Record<string, z.ZodType>;
  const mock = make("mock");
  const readMarks = ReadMarksInput.shape;
  return {
    limits: {
      tutorSaysMax: TUTOR_SAYS_MAX,
      bodyBase64Max: BODY_BASE64_MAX,
      imageBase64Max: most(ScanRegisterInput.shape.imageBase64),
      pagesMax: most(CheckPaperInput.shape.pages),
      sheetSkillsMax: most(make("sheet").skills),
      checkSkillsMax: most(make("check").skills),
      planGroupsMax: most(PlanInput.shape.groups),
      mockTitleLength: most(mock.title),
      mockPortionsMax: most(mock.portions),
      noteTaughtMax: most(week.taught),
      noteItemLength: most(element(week.taught)),
      notePractiseMax: most(week.practise),
      noteComingMax: most(week.coming),
      noteComingLength: most(element(week.coming)),
      canDoMax: most(ladder.canDo),
      canDoLength: most(element(ladder.canDo)),
      canDoAtHomeLength: most(ladder.atHome),
      canDoNextMax: most(ladder.next),
      canDoNextLength: most(element(ladder.next)),
      notOnTrackHardMax: most(notOnTrack.hard),
      notOnTrackHardLength: most(element(notOnTrack.hard)),
      notOnTrackReasonsMax: most(notOnTrack.reasons),
      notOnTrackReasonLength: most(element(notOnTrack.reasons)),
      gapDaysMax: most(gap.daysLeft),
      gapSkillsMax: most(gap.bySkill),
      gapNoteLength: most(bySkill.note),
      readMarksPagesMax: most(readMarks.pages),
      readMarksSubjectsMax: most(readMarks.subjects),
      subjectLength: most(element(readMarks.subjects)),
    },
    lists: {
      // The kinds the app posts to `events` (D82); the database's check is the shape, this is the list.
      eventKinds: ["app_opened", "signed_in", "signed_out", "tab_opened", "link_opened"],
      // The `reason` an error body may carry (src/errors.ts).
      errorReasons: ["invalid", "consent", "student_consent", "member", "unreachable", "in_progress", "key_reused", "rate"],
    },
  };
}

/** The fake's answer per kind, as the API sends `result`, and `kept_note`, a note as the note day's job keeps it: the
 *  app's decoders read each (ContractTests). */
export function samples(): Record<string, unknown> {
  const kept_note = noteContent({
    message: "Aarav had a good week.",
    english: "Aarav had a good week.",
    language: "hi",
    monday: "2026-10-05",
    facts: [{ label: "Taught", fact: "Fractions", symbol: "book.closed" }],
    generationId: "11111111-1111-1111-1111-111111111111",
  });
  return { ...SAMPLE, kept_note };
}

/** What the admin portal shows of the API (D113, D116): each work type's switched-off words as the tutor reads them, the
 *  kinds with a golden set, and each work type's prompt version. `bun contract` writes it to the portal. */
export type Portal = { paused: Record<string, string>; evalKinds: string[]; versions: Record<string, string> };

export function portal(): Portal {
  const kindOf = (work: string): AIKind => (work.startsWith("sheet_") ? "sheet" : (work as AIKind));
  const prompts = versions as Record<string, { version: string }>;
  const paused: Record<string, string> = {};
  const byWork: Record<string, string> = {};
  for (const work of Object.keys(table.work)) {
    paused[work] = pausedWords(kindOf(work));
    const v = prompts[kindOf(work)]?.version;
    if (v) byWork[work] = v;
  }
  return { paused, evalKinds: [...EVAL_KINDS], versions: byWork };
}
