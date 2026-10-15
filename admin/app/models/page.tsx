import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { Cell, Chip, LinkButton, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { kindLine, MODELS, modelName } from "@/content/models";
import { ENVIRONMENT } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import type { ModelStep, ModelsRow } from "@/lib/data/types";
import { environment } from "@/lib/env";
import { count, when } from "@/lib/format";
import { changedBy, changedWhen } from "./words";

export const metadata: Metadata = { title: "AI models" };

const COLS = "1.3fr 1.2fr 1.2fr 1.2fr .5fr 1.4fr .6fr";
type Show = keyof typeof MODELS.shows;

function StepCell({ label, step }: { label: string; step: ModelStep }) {
  return (
    <Cell label={label} sub={step.fallback_model ? MODELS.fallback(modelName(step.fallback_model)) : undefined}>
      {modelName(step.model)} · {step.effort}
    </Cell>
  );
}

/** Switched off first, then the newest change, then by name: what was touched is on top (the board's order). */
function ordered(rows: ModelsRow[]): ModelsRow[] {
  return [...rows].sort(
    (a, b) =>
      Number(a.draft.enabled) - Number(b.draft.enabled) ||
      Number(b.changed_by !== "seed") - Number(a.changed_by !== "seed") ||
      b.changed_at.localeCompare(a.changed_at) ||
      a.kind.localeCompare(b.kind),
  );
}

export default async function ModelsPage({ searchParams }: { searchParams: Promise<{ show?: string }> }) {
  const admin = await requireAdmin("/models");
  const q = await searchParams;
  const at = now();
  const show: Show = q.show === "off" || q.show === "changed" ? q.show : "all";
  const [models, me] = await Promise.all([data().models(), data().adminEmail(admin.userId)]);
  const rows = ordered(models.rows).filter((r) =>
    show === "off" ? !r.draft.enabled : show === "changed" ? r.changed_by !== "seed" : true,
  );
  return (
    <Frame current="Models">
      <Title eyebrow={ENVIRONMENT[environment()]} title={MODELS.title} lead={MODELS.lead}>
        <Pill
          label={MODELS.show}
          options={Object.entries(MODELS.shows).map(([k, label]) => ({
            label,
            href: k === "all" ? "/models" : `/models?show=${k}`,
            current: k === show,
          }))}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={count(models.tiles.kinds)} label={MODELS.tiles.kinds} />
          <Tile
            value={count(models.tiles.off)}
            label={MODELS.tiles.off}
            tone={models.tiles.off > 0 ? "overdue" : undefined}
          />
          <Tile value={count(models.tiles.changes_month)} label={MODELS.tiles.changes} />
          <Tile
            value={models.tiles.last_change ? when(models.tiles.last_change, at) : MODELS.never}
            label={MODELS.tiles.last}
          />
        </Tiles>
      </Section>
      <Section title={MODELS.list} lead={MODELS.listLead}>
        <Table
          cols={COLS}
          head={[
            { label: MODELS.head.kind },
            { label: MODELS.head.draft },
            { label: MODELS.head.check },
            { label: MODELS.head.repair },
            { label: MODELS.head.on },
            { label: MODELS.head.changed },
            { label: MODELS.head.act },
          ]}
        >
          {rows.map((r) => (
            <Row key={r.kind} cols={COLS}>
              <Cell label={MODELS.head.kind} kind="main" sub={kindLine(r.kind)}>
                {r.kind}
              </Cell>
              <StepCell label={MODELS.head.draft} step={r.draft} />
              <StepCell label={MODELS.head.check} step={r.check} />
              <StepCell label={MODELS.head.repair} step={r.repair} />
              <Cell label={MODELS.head.on}>
                {r.draft.enabled ? <Chip tone="ok">{MODELS.on}</Chip> : <Chip tone="overdue">{MODELS.off}</Chip>}
              </Cell>
              <Cell
                label={MODELS.head.changed}
                kind="dim"
                sub={r.changed_by !== "seed" ? (r.note ?? undefined) : undefined}
              >
                {changedWhen(r.changed_at, at)} · {changedBy(r.changed_by, r.note, me)}
              </Cell>
              <Cell label={MODELS.head.act} kind="acts">
                <LinkButton kind="secondary" href={`/models/${r.kind}`}>
                  {MODELS.change}
                </LinkButton>
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
      <Section>
        <div className="card padded tight">
          <span className="h3">{MODELS.how}</span>
          <div className="facts">
            {MODELS.howLines.map(([head, words]) => (
              <span key={head}>
                <b>{head}</b> · {words}
              </span>
            ))}
          </div>
        </div>
      </Section>
    </Frame>
  );
}
