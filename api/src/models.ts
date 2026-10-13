import table from "../models.json" with { type: "json" };
import type { AIKind } from "./db.js";
import { type Clock, realClock } from "./jobs/types.js";
import { log } from "./log.js";
import type { ModelRow, ModelSource } from "./models-db.js";
import type { ClassLevel } from "./schemas.js";

/** The model for each kind of AI work and step (D67, D73, D100). The order of truth: the environment's
 *  AI_MODEL_<WORK_TYPE> (the draft's, at deploy; an unknown name stops the API at start) over `ai_models` in the database
 *  (read by the platform each minute, 0052) over api/models.json (the seed, the price table and the tests' fixture). A
 *  name not in the file's price table is refused at every level. */
export type Model = keyof typeof table.models;
export type WorkType = keyof typeof table.work;
export type Step = "draft" | "check" | "repair";
export type Effort = "low" | "medium" | "high";
export type Chosen = { model: Model; effort: Effort; fallback: Model | null; enabled: boolean };

export const KNOWN_MODELS = Object.keys(table.models) as Model[];
const DEFAULTS = table.work as Record<WorkType, Model>;
let overrides: Partial<Record<WorkType, Model>> = {};
let rows = new Map<string, ModelRow>();

/** A sheet moves from Haiku to Sonnet from class 6 (spec-v2 section 9). */
const EARLY: readonly ClassLevel[] = ["lkg", "ukg", "1", "2", "3", "4", "5"];
/** The kinds whose prompts ask for high effort; 0052's seed says the same. */
const HIGH: readonly WorkType[] = ["scan_register", "check_paper", "mock"];
/** The checker is the other tier (D99): Haiku checks Sonnet, Sonnet checks Haiku and Opus. */
const OTHER_TIER: Record<Model, Model> = {
  "claude-haiku-5-5": "claude-sonnet-5-5",
  "claude-sonnet-5-5": "claude-haiku-5-5",
  "claude-opus-5-5": "claude-sonnet-5-5",
};

/** The work type a kind and class name: the kind itself, or a sheet's band. */
export function workTypeOf(kind: AIKind, classLevel?: ClassLevel): WorkType {
  if (kind === "sheet") return classLevel && !EARLY.includes(classLevel) ? "sheet_from_6" : "sheet_to_5";
  return kind;
}

const known = (name: string | null): name is Model => name !== null && (KNOWN_MODELS as string[]).includes(name);

/** The model, effort, fallback and switch for a kind of work and step; a sheet needs the class. */
export function modelFor(kind: AIKind, step: Step, classLevel?: ClassLevel): Chosen {
  const type = workTypeOf(kind, classLevel);
  const row = rows.get(`${type}:${step}`);
  const override = step === "draft" ? overrides[type] : undefined;
  if (row) {
    return {
      model: override ?? (row.model as Model),
      effort: row.effort,
      fallback: known(row.fallbackModel) ? row.fallbackModel : null,
      enabled: row.enabled,
    };
  }
  const draft = overrides[type] ?? DEFAULTS[type];
  return {
    model: step === "check" ? OTHER_TIER[DEFAULTS[type]] : draft,
    effort: step === "check" ? "medium" : HIGH.includes(type) ? "high" : "medium",
    fallback: null,
    enabled: true,
  };
}

/** Installs the database's table. `refresh` reads it, drops a row whose model is not in the price table, and keeps the
 *  last good table on a failure (answering false); `fresh` refreshes when the table is a minute old, waiting at most
 *  `waitMs` for the database (a slow read goes on in the background), so a request or a job's run reads a table no
 *  older than a minute without a timer that a frozen function would not run. `stop` clears it (tests). */
export function installModelTable(source: ModelSource, clock: Clock = realClock, waitMs = 1_500) {
  let readAt: number | null = null;
  let inFlight: Promise<boolean> | null = null;
  const refresh = async (): Promise<boolean> => {
    try {
      const next = new Map<string, ModelRow>();
      for (const row of await source.current()) {
        if (!known(row.model)) {
          log.error({ at: "models", reason: "unknown model", kind: row.kind, step: row.step, model: row.model });
          continue;
        }
        next.set(`${row.kind}:${row.step}`, row);
      }
      rows = next;
      readAt = clock.now();
      return true;
    } catch (e) {
      log.error({ at: "models", reason: "table unreachable", error: e instanceof Error ? e : String(e) });
      readAt = clock.now();
      return false;
    }
  };
  return {
    refresh,
    async fresh(): Promise<void> {
      if (readAt !== null && clock.now() - readAt < 60_000) return;
      inFlight ??= refresh().finally(() => {
        inFlight = null;
      });
      await Promise.race([inFlight, new Promise((resolve) => setTimeout(resolve, waitMs))]);
    },
    stop(): void {
      rows = new Map();
    },
  };
}

/** Applies the environment's AI_MODEL_<WORK_TYPE> overrides; throws naming the variable on a work type or a model the
 *  file does not know. Called once at start. */
export function applyModelOverrides(env: Record<string, string | undefined>): void {
  const next: Partial<Record<WorkType, Model>> = {};
  for (const [name, value] of Object.entries(env)) {
    if (!name.startsWith("AI_MODEL_") || value === undefined) continue;
    const type = name.slice("AI_MODEL_".length).toLowerCase();
    if (!(type in DEFAULTS)) throw new Error(`${name} names no kind of work. Known: ${Object.keys(DEFAULTS).join(", ")}`);
    if (!known(value)) throw new Error(`${name} names an unknown model: ${value}. Known: ${KNOWN_MODELS.join(", ")}`);
    next[type as WorkType] = value;
  }
  overrides = next;
}

/** Tests only: back to the file's defaults. */
export function resetModelOverrides(): void {
  overrides = {};
}
