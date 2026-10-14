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
export type Case = { kind: AIKind; id: string; input: Record<string, unknown>; expect: Expect; set?: string };
export type Scored = { schema: boolean; verify: boolean; expect: boolean; reasons: string[] };

/** The kinds with a golden set: every kind on its agent (the parents' four from Phase 21). */
export const EVAL_KINDS = [
  "sheet", "worked_example", "figure", "brief", "check", "placement", "plan", "parse_textbook", "parse_school",
  "note", "can_do", "test_tomorrow", "not_on_track",
] as const;
export type EvalKind = (typeof EVAL_KINDS)[number];
/** The language anchors (D110): `api/evals/anchors/<lang>/cases.json`, the parents' messages in Hindi and Kannada, each
 *  case naming its kind; run by name (`bun evals --kinds anchor_hi,anchor_kn`) under the free checks until the native
 *  speakers' labels come (docs/testing/anchor-labelling.md). */
export const ANCHOR_SETS = ["anchor_hi", "anchor_kn"] as const;

/** A set's folder under api/evals: a kind's own, or an anchor set's `anchors/<lang>`. */
export const setFolder = (set: string) => (set.startsWith("anchor_") ? join("anchors", set.slice("anchor_".length)) : set);
/** A centre's id for the inputs' schemas: the evals touch no database. */
export const PROBE_CENTRE = "22222222-2222-2222-2222-222222222222";

/** api/evals, where the function carries it (vercel.json's includeFiles) or beside the sources. */
export function evalsDir(): string {
  const candidates = [join(process.cwd(), "evals"), fileURLToPath(new URL("../../evals", import.meta.url)), join(process.cwd(), "api", "evals")];
  const found = candidates.find((dir) => existsSync(join(dir, "sheet", "cases.json")));
  if (!found) throw new Error("the golden sets are not with the function");
  return found;
}

/** Every case of the sets asked (every kind's by default), in the files' order; an anchor's case names its own kind. */
export function loadCases(sets: readonly string[] = EVAL_KINDS, dir = evalsDir()): Case[] {
  return sets.flatMap((set) =>
    (JSON.parse(readFileSync(join(dir, setFolder(set), "cases.json"), "utf8")) as (Omit<Case, "kind"> & { kind?: AIKind })[]).map((c) => ({ ...c, kind: c.kind ?? (set as AIKind), set })),
  );
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

type PageRow = { number: string; name: string; sections?: string[]; page: number };
type Page = { file: string; title: string; heading: string; rows: PageRow[] };

/** What a case's page prints, in words (`<kind>/pages.json`, the text the page was drawn from), for the graders: they
 *  read text alone, and without it judged a photo's chapters against the whole book they remember. "" for a case with
 *  no page. */
export function pageWords(c: Case, dir = evalsDir()): string {
  if (typeof c.input.image !== "string") return "";
  const file = c.input.image.replace(/^.*\//, "").replace(/\.png$/, "");
  const pages = JSON.parse(readFileSync(join(dir, c.kind, "pages.json"), "utf8")) as Page[];
  const page = pages.find((p) => p.file === file);
  if (!page) return "";
  const rows = page.rows.map((r) => `${r.number} ${r.name}${r.sections?.length ? ` (${r.sections.join("; ")})` : ""}, page ${r.page}`);
  return [page.title, page.heading, ...rows].join("\n");
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
