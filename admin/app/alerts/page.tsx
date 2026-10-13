import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { Cell, Chip, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { SubmitButton } from "@/components/SubmitButton";
import { ALERTS, valueLine } from "@/content/alerts";
import { shortCentre } from "@/content/calls";
import { ENVIRONMENT, NONE, PENDING } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import { environment } from "@/lib/env";
import { count, dayMonth, short, when } from "@/lib/format";
import { acknowledge } from "./actions";

export const metadata: Metadata = { title: "Alerts" };

const COLS = "2fr 1fr 1fr 1fr 1.2fr";
type Show = keyof typeof ALERTS.shows;

/** "07:20" today, "yesterday", else "11 Oct". */
function ackWhen(iso: string, at: Date): string {
  const w = short(iso, at);
  if (w.length <= 5) return w;
  return w.startsWith("Yesterday") ? "yesterday" : dayMonth(iso);
}

export default async function AlertsPage({ searchParams }: { searchParams: Promise<{ show?: string }> }) {
  await requireAdmin("/alerts");
  const q = await searchParams;
  const at = now();
  const show: Show = q.show === "newest" ? "newest" : "open-first";
  const alerts = await data().alerts(show === "open-first");
  return (
    <Frame current="Alerts">
      <Title eyebrow={ENVIRONMENT[environment()]} title={ALERTS.title} lead={ALERTS.lead}>
        <Pill
          label={ALERTS.show}
          options={Object.entries(ALERTS.shows).map(([k, label]) => ({
            label,
            href: k === "newest" ? "/alerts?show=newest" : "/alerts",
            current: k === show,
          }))}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile
            value={count(alerts.tiles.open)}
            label={ALERTS.tiles.open}
            tone={alerts.tiles.open > 0 ? "overdue" : undefined}
          />
          <Tile value={count(alerts.tiles.acknowledged_week)} label={ALERTS.tiles.acknowledgedWeek} />
          <Tile
            value={alerts.tiles.last_raised ? when(alerts.tiles.last_raised, at) : ALERTS.never}
            label={ALERTS.tiles.lastRaised}
          />
          <Tile value={ALERTS.tiles.how} label={ALERTS.tiles.howLabel} />
        </Tiles>
      </Section>
      <Section title={ALERTS.shows[show]}>
        <Table
          cols={COLS}
          head={[
            { label: ALERTS.head.alert },
            { label: ALERTS.head.centre },
            { label: ALERTS.head.value },
            { label: ALERTS.head.raised },
            { label: ALERTS.head.act },
          ]}
        >
          {alerts.rows.map((a) => (
            <Row key={a.id} cols={COLS}>
              <Cell label={ALERTS.head.alert} kind="main" sub={a.message ?? undefined}>
                {a.kind}
              </Cell>
              <Cell label={ALERTS.head.centre} kind="dim">
                {a.centre ? shortCentre(a.centre) : NONE}
              </Cell>
              <Cell label={ALERTS.head.value}>{valueLine(a.kind, a.value, a.threshold)}</Cell>
              <Cell label={ALERTS.head.raised} kind="dim">
                {when(a.raised_at, at)}
              </Cell>
              <Cell label={ALERTS.head.act} kind="acts">
                {a.acknowledged_at ? (
                  <Chip>{ALERTS.acknowledged(ackWhen(a.acknowledged_at, at))}</Chip>
                ) : (
                  <form action={acknowledge}>
                    <input type="hidden" name="alert" value={a.id} />
                    <input type="hidden" name="show" value={show} />
                    <SubmitButton kind="secondary" working={PENDING.acknowledge}>
                      {ALERTS.acknowledge}
                    </SubmitButton>
                  </form>
                )}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
      <Section>
        <div className="card padded tight">
          <span className="h3">{ALERTS.lines}</span>
          <div className="facts">
            {ALERTS.line.map(([kind, words]) => (
              <span key={kind}>
                <b>{kind}</b> · {words}
              </span>
            ))}
          </div>
          <p className="lead smaller">{ALERTS.linesNote}</p>
        </div>
      </Section>
    </Frame>
  );
}
