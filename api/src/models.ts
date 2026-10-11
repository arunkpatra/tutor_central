import table from "../models.json" with { type: "json" };
import type { AIKind } from "./db.js";
import type { ClassLevel } from "./schemas.js";

/** The model for each kind of AI work lives in one checked-in table, api/models.json (D67): the API, the app's price
 *  sheet and `bun cost` read it. One model per work type, no fallbacks (D35, D63). An environment variable per work type,
 *  AI_MODEL_<WORK_TYPE>, overrides it at deploy; a value that is not one of the table's models stops the API at start, so
 *  the deploy's smoke fails rather than a tutor's call. */
export type Model = keyof typeof table.models;
export type WorkType = keyof typeof table.work;

export const KNOWN_MODELS = Object.keys(table.models) as Model[];
const DEFAULTS = table.work as Record<WorkType, Model>;
let work: Record<WorkType, Model> = { ...DEFAULTS };

/** A sheet moves from Haiku to Sonnet from class 6 (spec-v2 section 9). */
const EARLY: readonly ClassLevel[] = ["lkg", "ukg", "1", "2", "3", "4", "5"];

/** The work type a kind and class name: the kind itself, or a sheet's band. */
export function workTypeOf(kind: AIKind, classLevel?: ClassLevel): WorkType {
  if (kind === "sheet") return classLevel && !EARLY.includes(classLevel) ? "sheet_from_6" : "sheet_to_5";
  return kind;
}

/** The model for a kind of work; a sheet needs the class. */
export function modelFor(kind: AIKind, classLevel?: ClassLevel): Model {
  return work[workTypeOf(kind, classLevel)];
}

/** Applies the environment's AI_MODEL_<WORK_TYPE> overrides to the table; throws naming the variable on a work type or a
 *  model the table does not know. Called once at start. */
export function applyModelOverrides(env: Record<string, string | undefined>): void {
  const next = { ...DEFAULTS };
  for (const [name, value] of Object.entries(env)) {
    if (!name.startsWith("AI_MODEL_") || value === undefined) continue;
    const type = name.slice("AI_MODEL_".length).toLowerCase();
    if (!(type in DEFAULTS)) throw new Error(`${name} names no kind of work. Known: ${Object.keys(DEFAULTS).join(", ")}`);
    if (!(KNOWN_MODELS as string[]).includes(value)) {
      throw new Error(`${name} names an unknown model: ${value}. Known: ${KNOWN_MODELS.join(", ")}`);
    }
    next[type as WorkType] = value as Model;
  }
  work = next;
}

/** Tests only: back to the table's defaults. */
export function resetModelOverrides(): void {
  work = { ...DEFAULTS };
}
