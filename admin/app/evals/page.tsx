import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { PageLink } from "@/components/PageLink";
import { Cell, Chip, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { SubmitButton } from "@/components/SubmitButton";
import { EVALS, RUPEES_A_KIND } from "@/content/evals";
import { ENVIRONMENT, NONE, PENDING } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import type { EvalRow } from "@/lib/data/types";
import { environment } from "@/lib/env";
import { count, dayMonth, rupees, when } from "@/lib/format";
import { EVAL_KINDS } from "@/lib/generated/contract";
import { runEvals } from "./actions";
import { chosenKinds } from "./kinds";

export const metadata: Metadata = { title: "Golden sets" };

const COLS = "1.3fr 1.1fr .5fr .8fr .7fr .6fr 1fr .6fr";
const FAILED_COLS = "1fr 3fr";
type Show = keyof typeof EVALS.shows;

/** Below the gate first, then passed, then never run; by name within each. */
function rank(row: EvalRow | undefined): number {
  return row ? (row.gate ? 1 : 0) : 2;
}

/** The address with the chips' kinds, in the golden sets' order. */
function kindsHref(kinds: string[]): string {
  return kinds.length === 0 ? "/evals" : `/evals?kinds=${encodeURIComponent(kinds.join(","))}`;
}

export default async function EvalsPage({
  searchParams,
}: {
  searchParams: Promise<{ show?: string; kinds?: string; queued?: string }>;
}) {
  await requireAdmin("/evals");
  const q = await searchParams;
  const at = now();
  const show: Show = q.show === "below" ? "below" : "all";
  const runs = await data().evalRuns();
  const byKind = new Map(runs.rows.map((r) => [r.kind, r]));
  const kinds = [...EVAL_KINDS]
    .sort((a, b) => rank(byKind.get(a)) - rank(byKind.get(b)) || a.localeCompare(b))
    .filter((k) => show === "all" || (byKind.get(k) && !byKind.get(k)?.gate));
  const chosen = chosenKinds(q.kinds);
  const toggle = (k: string) =>
    kindsHref(EVAL_KINDS.filter((x) => (x === k ? !chosen.includes(k) : chosen.includes(x))));
  const busy = q.queued === "busy" || (runs.queued !== null && q.queued === undefined);
  return (
    <Frame current="Evals">
      <Title eyebrow={ENVIRONMENT[environment()]} title={EVALS.title} lead={EVALS.lead}>
        <Pill
          label={EVALS.show}
          options={Object.entries(EVALS.shows).map(([k, label]) => ({
            label,
            href: k === "all" ? "/evals" : "/evals?show=below",
            current: k === show,
          }))}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={count(EVAL_KINDS.length)} label={EVALS.tiles.kinds} />
          <Tile value={count(runs.tiles.passed)} label={EVALS.tiles.passed} />
          <Tile
            value={count(runs.tiles.below)}
            label={EVALS.tiles.below}
            tone={runs.tiles.below > 0 ? "overdue" : undefined}
          />
          <Tile
            value={
              runs.tiles.last_run_at
                ? `${dayMonth(runs.tiles.last_run_at)} · ${rupees(runs.tiles.last_run_paise)}`
                : EVALS.never
            }
            label={EVALS.tiles.last}
          />
        </Tiles>
      </Section>
      <Section title={EVALS.list} lead={EVALS.listLead}>
        <Table
          cols={COLS}
          head={[
            { label: EVALS.head.kind },
            { label: EVALS.head.run },
            { label: EVALS.head.cases, right: true },
            { label: EVALS.head.free, right: true },
            { label: EVALS.head.check, right: true },
            { label: EVALS.head.rubric, right: true },
            { label: EVALS.head.gate },
            { label: EVALS.head.cost, right: true },
          ]}
        >
          {kinds.map((k) => {
            const r = byKind.get(k);
            return (
              <Row key={k} cols={COLS}>
                <Cell
                  label={EVALS.head.kind}
                  kind="main"
                  sub={r ? (r.by_admin ? EVALS.here : EVALS.nightly) : undefined}
                >
                  {k}
                </Cell>
                <Cell label={EVALS.head.run} kind="dim">
                  {r ? when(r.run_at, at) : EVALS.never}
                </Cell>
                <Cell label={EVALS.head.cases} kind="r">
                  {r ? count(r.cases) : NONE}
                </Cell>
                <Cell label={EVALS.head.free} kind="r">
                  {r ? `${r.schema} · ${r.verify}` : NONE}
                </Cell>
                <Cell label={EVALS.head.check} kind="r">
                  {r ? count(r.check_pass) : NONE}
                </Cell>
                <Cell label={EVALS.head.rubric} kind="r">
                  {r ? `${Math.round(r.grade_rate * 100)}%` : NONE}
                </Cell>
                <Cell label={EVALS.head.gate}>
                  {r ? (
                    <Chip tone={r.gate ? "ok" : "overdue"}>{r.gate ? EVALS.passed : EVALS.below}</Chip>
                  ) : (
                    <Chip>{EVALS.noRun}</Chip>
                  )}
                </Cell>
                <Cell label={EVALS.head.cost} kind="r">
                  {r ? rupees(r.cost_paise) : NONE}
                </Cell>
              </Row>
            );
          })}
        </Table>
      </Section>
      <Section title={EVALS.failed} lead={EVALS.failedLead}>
        <Table cols={FAILED_COLS} head={[{ label: EVALS.failedHead.case }, { label: EVALS.failedHead.why }]}>
          {runs.failures.map((f) => (
            <Row key={f.id} cols={FAILED_COLS}>
              <Cell label={EVALS.failedHead.case} kind="strong">
                {f.id}
              </Cell>
              <Cell label={EVALS.failedHead.why}>{f.reasons.join(" · ")}</Cell>
            </Row>
          ))}
        </Table>
      </Section>
      <Section>
        <form action={runEvals} className="card padded stack">
          <span className="h3">{EVALS.run}</span>
          <p className="lead small">{EVALS.runLead}</p>
          <input type="hidden" name="kinds" value={chosen.join(",")} />
          <div className="chips">
            {EVAL_KINDS.map((k) => (
              <PageLink key={k} href={toggle(k)} className={chosen.includes(k) ? "chip accent" : "chip"}>
                {k}
              </PageLink>
            ))}
            <PageLink href="/evals" className={chosen.length === 0 ? "chip accent" : "chip"}>
              {EVALS.every}
            </PageLink>
          </div>
          {q.queued && q.queued !== "busy" ? (
            <p className="banner">
              {EVALS.queued} · <PageLink href={`/jobs?day=all&open=${q.queued}`}>{EVALS.openJob}</PageLink>
            </p>
          ) : null}
          {busy ? <p className="banner">{EVALS.busy}</p> : null}
          <div className="formFoot">
            <SubmitButton kind="primary" working={PENDING.run}>
              {EVALS.button(
                chosen.length === 0 ? null : chosen.length,
                (chosen.length === 0 ? EVAL_KINDS.length : chosen.length) * RUPEES_A_KIND,
              )}
            </SubmitButton>
            <span className="formNote">{EVALS.runNote}</span>
          </div>
        </form>
      </Section>
    </Frame>
  );
}
