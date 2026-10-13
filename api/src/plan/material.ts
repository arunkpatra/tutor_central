import { type MakeInput, MakeInput as MakeSchema } from "../schemas.js";
import type { MaterialRequest } from "./budget.js";
import { BRIEF_PREFIX } from "./rules.js";
import { CLASS_LEVELS, type Chapter, type ClassLevel, type LineKind, type PlanDraft, type Skill } from "./types.js";

/** The plan's material as the phone made it (PlanMaker+Calls): the body each request sends to `/ai/make`, the artefact
 *  kept from the answer in the shape the app reads (`ArtefactContent`, snake-case keys), and the lines it links to. */

/** Swift's `convertToSnakeCase`: "skillId" → "skill_id", "howToCatch" → "how_to_catch", "myURLValue" → "my_url_value". */
export function snakeKey(key: string): string {
  return key
    .replace(/([A-Z]+)([A-Z][a-z])/g, "$1_$2")
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .toLowerCase();
}

/** An answer's keys as `keep_artefact` stores them (the app's encoder: snake case, objects nested alike). */
/** The app's snake-cased keys back to the API's camel case (a kept figure read for its PDF). */
export function camel(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(camel);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(Object.entries(value as Record<string, unknown>).map(([k, v]) => [k.replace(/_([a-z0-9])/g, (_, c: string) => c.toUpperCase()), camel(v)]));
  }
  return value;
}

export function snake(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(snake);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(Object.entries(value as Record<string, unknown>).map(([k, v]) => [snakeKey(k), snake(v)]));
  }
  return value;
}

const isLight = (level: ClassLevel) => CLASS_LEVELS.indexOf(level) <= CLASS_LEVELS.indexOf("5");

/** The body of `/ai/make` for a request (no student is named: D62); a placement's are `placementBodies`. Undefined when
 *  the body is not one the API takes (a personal check whose group has no subject). */
export function materialInput(req: Exclude<MaterialRequest, { kind: "placement" }>, centre: string): MakeInput | undefined {
  const common = { centreId: centre, classLevel: req.classLevel, subject: req.subject };
  const body = (() => {
    switch (req.kind) {
      case "checks":
      case "personalChecks":
        return { ...common, kind: "check", skills: req.skills };
      case "sheet":
        return { ...common, kind: "sheet", skills: req.skills, questions: req.questions, forHomework: req.forHomework };
      case "workedExample":
        return { ...common, kind: "worked_example", skill: req.skills[0] };
      case "figure":
        return { ...common, kind: "figure", figure: req.figure, skill: req.skills[0] };
      case "brief":
        return { ...common, kind: "brief", chapter: req.chapter };
      case "mock":
        return { ...common, kind: "mock", title: req.title, portions: req.portions, pattern: req.pattern };
    }
  })();
  const parsed = MakeSchema.safeParse(body);
  return parsed.success ? parsed.data : undefined;
}

/** A placement's subjects (Domain's Placement.groups): each subject's first skill of each chapter, a ladder's steps for a
 *  young student; the ladders first (reading, writing, numbers), then the subjects by name. */
export function placementGroups(chapters: Chapter[], skills: Skill[]): { title: string; items: { chapterID: string; skillID: string; name: string; skill: string }[] }[] {
  const areas = ["reading", "writing", "numbers"];
  const titles: Record<string, string> = { reading: "Reading", writing: "Writing", numbers: "Numbers" };
  const bySubject = new Map<string, Chapter[]>();
  for (const c of chapters) bySubject.set(c.subject, [...(bySubject.get(c.subject) ?? []), c]);
  const rank = (subject: string) => {
    const ladder = bySubject.get(subject)?.[0]?.ladder;
    return ladder ? areas.indexOf(ladder) : Number.MAX_SAFE_INTEGER;
  };
  const subjects = [...bySubject.keys()].sort((a, b) => (rank(a) !== rank(b) ? rank(a) - rank(b) : a < b ? -1 : a > b ? 1 : 0));
  return subjects.flatMap((subject) => {
    const list = [...(bySubject.get(subject) ?? [])].sort((a, b) => a.position - b.position);
    const first = list[0];
    const items = first?.ladder
      ? skills
          .filter((s) => s.chapterID === first.id)
          .sort((a, b) => a.position - b.position)
          .map((s) => ({ chapterID: first.id, skillID: s.id, name: s.name, skill: s.name }))
      : list.flatMap((chapter) => {
          const own = skills.filter((s) => s.chapterID === chapter.id).sort((a, b) => a.position - b.position)[0];
          return own ? [{ chapterID: chapter.id, skillID: own.id, name: chapter.name, skill: own.name }] : [];
        });
    return items.length === 0 ? [] : [{ title: first?.ladder ? (titles[first.ladder] ?? subject) : subject, items }];
  });
}

/** The artefact as `keep_artefact` takes it (`p_artefact`): its kind, made, its title, the content in the app's keys,
 *  and the generation it came from. */
export type KeptArtefact = { kind: string; source: "made"; title: string; content: Record<string, unknown>; generation_id?: string };

/** The checks' questions with their skill rows (PlanMaker.checks): a question takes the row of the skill it names, else
 *  the next row not taken; a skill with no row yet takes a fresh id. The rows belong to the last names when there are
 *  fewer of them (PlanMaker.named). */
export function checkRows(questions: { skill: string; question: string; answer: string }[], skills: string[], ids: string[]) {
  const missing = Math.max(0, skills.length - ids.length);
  const free: [string, string | undefined][] = skills.map((name, i) => [name, i < missing ? undefined : ids[i - missing]]);
  return questions.map((made) => {
    const at = free.findIndex(([name]) => name === made.skill);
    const index = at >= 0 ? at : free.length > 0 ? 0 : -1;
    const id = index >= 0 ? free.splice(index, 1)[0]?.[1] : undefined;
    return { skill_id: id ?? crypto.randomUUID(), skill: made.skill, question: made.question, answer: made.answer };
  });
}

/** The kept artefact for a request's answer, as PlanMaker+Calls shaped it. */
export function artefactOf(req: Exclude<MaterialRequest, { kind: "placement" }>, answer: unknown, generation: string): KeptArtefact {
  const a = answer as Record<string, unknown>;
  const made = (kind: string, title: string, content: unknown): KeptArtefact => ({ kind, source: "made", title, content: content as Record<string, unknown>, generation_id: generation });
  switch (req.kind) {
    case "checks":
    case "personalChecks":
      return made("check", `Checks · ${req.skills[0] ?? ""}`, { questions: checkRows(a.questions as never, req.skills, req.skillIDs), placement: false });
    case "sheet":
      return made("sheet", `${req.skills[0] ?? (a.title as string)} · ${req.forHomework ? "sheet" : "set"} 1`, {
        title: a.title,
        instructions: a.instructions ?? null,
        questions: snake(a.questions),
        for_homework: req.forHomework,
        light: req.forHomework && isLight(req.classLevel),
      });
    case "workedExample":
      return made("worked_example", req.skills[0], snake(a));
    case "figure":
      return made("figure", req.skills[0], snake(a));
    case "brief":
      return made("brief", `${BRIEF_PREFIX}${req.chapter}`, snake(a));
    case "mock":
      return made("mock", req.title, {
        title: a.title,
        duration_minutes: a.durationMinutes,
        sections: snake(a.sections),
        pattern: snake(req.pattern),
        portions: req.portions,
        school_item_id: req.item,
      });
  }
}

/** Where a request's artefact goes (PlanMaker.place): the group's lines of a kind, or one student's check line in their
 *  group; a mock with its exam. */
export function placeOf(req: MaterialRequest, draft: PlanDraft): { groupNo: number; student?: string; itemKind: LineKind; schoolItem?: string } {
  switch (req.kind) {
    case "checks":
      return { groupNo: req.group, itemKind: "check" };
    case "personalChecks":
    case "placement":
      return { groupNo: draft.groups.find((g) => g.memberIDs.includes(req.student))?.number ?? 1, student: req.student, itemKind: "check" };
    case "sheet":
      return { groupNo: req.group, itemKind: req.forHomework ? "homework" : "practise" };
    case "workedExample":
      return { groupNo: req.group, itemKind: "worked_example" };
    case "figure":
      return { groupNo: req.group, itemKind: "figure" };
    case "brief":
      return { groupNo: req.group, itemKind: "brief" };
    case "mock":
      return { groupNo: req.group, itemKind: "practise", schoolItem: req.item };
  }
}
