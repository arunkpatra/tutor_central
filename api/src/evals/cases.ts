import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import type { AgentOutcome, Kind } from "../agents/agent.js";
import { proofHolds } from "../agents/arith.js";
import { kindFor } from "../agents/kinds/index.js";
import type { AIKind } from "../db.js";
import { decodeImage } from "../images.js";
import { FigureOutput, MakeInput, ParseSchoolInput, PlanInput } from "../schemas.js";

/** A golden case (D74, plan decision 10): a kind's input without a centre, and what its answer must show. */
export type Expect = { count?: number; proofs?: boolean; contains?: string[]; never?: string[]; figure?: string; refused?: boolean };
export type Case = { kind: AIKind; id: string; input: Record<string, unknown>; expect: Expect };
export type Scored = { schema: boolean; verify: boolean; expect: boolean; reasons: string[] };

/** The kinds with a golden set: the nine on their agents. */
export const EVAL_KINDS = ["sheet", "worked_example", "figure", "brief", "check", "placement", "plan", "parse_textbook", "parse_school"] as const;
export type EvalKind = (typeof EVAL_KINDS)[number];
/** A centre's id for the inputs' schemas: the evals touch no database. */
export const PROBE_CENTRE = "22222222-2222-2222-2222-222222222222";

/** api/evals, where the function carries it (vercel.json's includeFiles) or beside the sources. */
export function evalsDir(): string {
  const candidates = [join(process.cwd(), "evals"), fileURLToPath(new URL("../../evals", import.meta.url)), join(process.cwd(), "api", "evals")];
  const found = candidates.find((dir) => existsSync(join(dir, "sheet", "cases.json")));
  if (!found) throw new Error("the golden sets are not with the function");
  return found;
}

/** Every case of the kinds asked (all nine by default), in the files' order. */
export function loadCases(kinds: readonly string[] = EVAL_KINDS, dir = evalsDir()): Case[] {
  return kinds.flatMap((kind) => (JSON.parse(readFileSync(join(dir, kind, "cases.json"), "utf8")) as Omit<Case, "kind">[]).map((c) => ({ ...c, kind: kind as AIKind })));
}

/** The kinds that have a golden set on disk. */
export function kindsOnDisk(dir = evalsDir()): string[] {
  return readdirSync(dir, { withFileTypes: true }).filter((d) => d.isDirectory() && existsSync(join(dir, d.name, "cases.json"))).map((d) => d.name).sort();
}

/** The agent and its input for a case: the input checked by the route's schema, a page read from the set's pages. */
export function agentFor(c: Case, dir = evalsDir()): { spec: Kind<unknown, unknown>; input: unknown } {
  const spec = kindFor(c.kind);
  if (!spec) throw new Error(`${c.kind} has no agent`);
  const withCentre = { centreId: PROBE_CENTRE, ...c.input };
  switch (c.kind) {
    case "plan":
      return { spec, input: PlanInput.parse(withCentre) };
    case "parse_school": {
      const v = ParseSchoolInput.parse(withCentre);
      return { spec, input: { text: v.text ?? null, image: null, today: v.today, schools: v.schools ?? [], classLevels: v.classLevels ?? [] } };
    }
    case "parse_textbook": {
      const bytes = readFileSync(join(dir, c.kind, String(c.input.image)));
      const image = decodeImage({ imageBase64: bytes.toString("base64"), mediaType: "image/png" });
      if (typeof image === "string") throw new Error(`${c.id}: ${image}`);
      return { spec, input: { image, classLevel: c.input.classLevel, subject: c.input.subject } };
    }
    default:
      return { spec, input: MakeInput.parse({ kind: c.kind, ...withCentre }) };
  }
}

/** How many things an answer holds, by kind: the questions, the mistakes, the chapters, the items, the groups. */
function countOf(kind: AIKind, parsed: Record<string, unknown>): number | undefined {
  const list = (key: string) => (Array.isArray(parsed[key]) ? (parsed[key] as unknown[]).length : undefined);
  if (kind === "brief") return list("mistakes");
  if (kind === "parse_textbook") return list("chapters");
  if (kind === "parse_school") return list("items");
  if (kind === "plan") return list("groups");
  if (kind === "worked_example") return list("steps");
  return list("questions");
}

/** Every proof an answer carries, wherever it sits. */
function proofsOf(value: unknown): { expression: string; equals: number }[] {
  if (Array.isArray(value)) return value.flatMap(proofsOf);
  if (!value || typeof value !== "object") return [];
  const object = value as Record<string, unknown>;
  const own = object.proof && typeof object.proof === "object" ? [object.proof as { expression: string; equals: number }] : [];
  return [...own, ...Object.entries(object).filter(([key]) => key !== "proof").flatMap(([, v]) => proofsOf(v))];
}

/** A case's free checks over an agent's outcome (the schema, the kind's verify, the case's expectations); the same code
 *  scores promptfoo's runs (api/evals/assert.ts) and the nightly's (src/evals/runner.ts). */
export function evaluate(c: Case, input: unknown, outcome: AgentOutcome<unknown>): Scored {
  const reasons: string[] = [];
  if (c.expect.refused) {
    const refused = outcome.kind === "failed" && outcome.words === "refused";
    if (!refused) reasons.push(`expected a refusal, got ${outcome.kind}`);
    return { schema: true, verify: true, expect: refused, reasons };
  }
  if (outcome.kind !== "ok") return { schema: false, verify: false, expect: false, reasons: [`no answer: ${outcome.kind}${outcome.kind === "failed" ? ` (${outcome.reason})` : ""}`] };
  const spec = kindFor(c.kind) as Kind<unknown, unknown>;
  const parsed = outcome.parsed as Record<string, unknown>;
  const schema = (c.kind === "figure" ? FigureOutput : spec.draft(input).schema).safeParse(parsed).success;
  if (!schema) reasons.push("the answer does not fit its schema");
  const findings = spec.verify?.(input, parsed) ?? [];
  if (findings.length > 0) reasons.push(...findings.map((f) => `${f.item}: ${f.problem}`));
  const text = JSON.stringify(parsed);
  const misses: string[] = [];
  const e = c.expect;
  if (e.count !== undefined && countOf(c.kind, parsed) !== e.count) misses.push(`count ${countOf(c.kind, parsed)}, expected ${e.count}`);
  if (e.proofs) {
    const proofs = proofsOf(parsed);
    if (proofs.length === 0) misses.push("no proof where an answer is a number");
    else if (!proofs.every(proofHolds)) misses.push("a proof does not add up");
  }
  for (const word of e.contains ?? []) if (!text.includes(word)) misses.push(`"${word}" missing`);
  for (const word of e.never ?? []) if (text.includes(word)) misses.push(`"${word}" present`);
  if (e.figure && (parsed.figure as { kind?: string } | undefined)?.kind !== e.figure) misses.push(`not a ${e.figure}`);
  reasons.push(...misses);
  return { schema, verify: findings.length === 0, expect: misses.length === 0, reasons };
}
