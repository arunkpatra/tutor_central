import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { PageLink } from "@/components/PageLink";
import { Cell, Chip, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { CALL_KINDS, CALLS, outcomeChip, shortCentre } from "@/content/calls";
import { modelName } from "@/content/models";
import { ENVIRONMENT, NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import { environment, preview } from "@/lib/env";
import { count, istDay, latency, rupees, short } from "@/lib/format";
import { idOf } from "@/lib/ids";

export const metadata: Metadata = { title: "AI calls" };

const COLS = "1fr .9fr 1.4fr 1.1fr 1fr .7fr .7fr .8fr";
type Query = { day?: string; centre?: string; kind?: string; outcome?: string };
type Day = keyof typeof CALLS.days;

function href(q: Query, change: Partial<Query>): string {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries({ ...q, ...change })) if (v) params.set(k, v);
  const s = params.toString();
  return s ? `/calls?${s}` : "/calls";
}

export default async function CallsPage({ searchParams }: { searchParams: Promise<Query> }) {
  await requireAdmin("/calls");
  const q = await searchParams;
  const at = now();
  const day: Day = q.day && q.day in CALLS.days ? (q.day as Day) : "today";
  const date = day === "all" ? null : istDay(new Date(at.getTime() - (day === "yesterday" ? 86_400_000 : 0)));
  const centre = q.centre ? idOf(q.centre, preview()) : null;
  const kind = q.kind && (CALL_KINDS as readonly string[]).includes(q.kind) ? q.kind : null;
  const outcome = q.outcome && q.outcome in CALLS.outcomes ? q.outcome : null;
  const [calls, centres] = await Promise.all([
    data().calls({ day: date, centre, kind, status: outcome }),
    data().centres(`${istDay(at).slice(0, 7)}-01`),
  ]);
  return (
    <Frame current="Calls">
      <Title eyebrow={ENVIRONMENT[environment()]} title={CALLS.title} lead={CALLS.lead}>
        <Pill
          label={CALLS.day}
          options={Object.entries(CALLS.days).map(([k, label]) => ({
            label,
            href: href(q, { day: k }),
            current: k === day,
          }))}
        />
        <Pill
          label={CALLS.centre}
          options={[
            { label: CALLS.all, href: href(q, { centre: "" }), current: !centre },
            ...centres.rows.map((r) => ({ label: r.name, href: href(q, { centre: r.id }), current: r.id === centre })),
          ]}
        />
        <Pill
          label={CALLS.kind}
          options={[
            { label: CALLS.all, href: href(q, { kind: "" }), current: !kind },
            ...CALL_KINDS.map((k) => ({ label: k, href: href(q, { kind: k }), current: k === kind })),
          ]}
        />
        <Pill
          label={CALLS.outcome}
          options={[
            { label: CALLS.all, href: href(q, { outcome: "" }), current: !outcome },
            ...Object.entries(CALLS.outcomes).map(([k, label]) => ({
              label,
              href: href(q, { outcome: k }),
              current: k === outcome,
            })),
          ]}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={count(calls.tiles.calls)} label={CALLS.tiles.calls(day)} />
          <Tile
            value={count(calls.tiles.failed)}
            label={CALLS.tiles.failed}
            tone={calls.tiles.failed > 0 ? "overdue" : undefined}
          />
          <Tile
            value={count(calls.tiles.refused)}
            label={CALLS.tiles.refused}
            tone={calls.tiles.refused > 0 ? "due" : undefined}
          />
          <Tile
            value={calls.tiles.median_latency_ms === null ? NONE : latency(calls.tiles.median_latency_ms)}
            label={CALLS.tiles.latency}
          />
        </Tiles>
      </Section>
      <Section title={CALLS.list(day)} lead={CALLS.listLead}>
        <Table
          cols={COLS}
          head={[
            { label: CALLS.head.time },
            { label: CALLS.head.centre },
            { label: CALLS.head.kind },
            { label: CALLS.head.outcome },
            { label: CALLS.head.tokens, right: true },
            { label: CALLS.head.latency, right: true },
            { label: CALLS.head.cost, right: true },
            { label: CALLS.head.from },
          ]}
        >
          {calls.rows.map((c) => {
            const chip = outcomeChip(c.status, c.error_reason);
            return (
              <Row key={c.id} cols={COLS}>
                <Cell label={CALLS.head.time}>{short(c.created_at, at, true)}</Cell>
                <Cell label={CALLS.head.centre} kind="dim">
                  {shortCentre(c.centre)}
                </Cell>
                <Cell
                  label={CALLS.head.kind}
                  kind="main"
                  sub={CALLS.sub(modelName(c.model), c.prompt_version, c.student)}
                >
                  <PageLink className="plain" href={`/calls/${c.id}`}>
                    {c.kind}
                  </PageLink>
                </Cell>
                <Cell label={CALLS.head.outcome}>
                  <Chip tone={chip.tone}>{chip.text}</Chip>
                </Cell>
                <Cell label={CALLS.head.tokens} kind="r">
                  {count(c.tokens_in ?? 0)} · {count(c.tokens_out ?? 0)}
                </Cell>
                <Cell label={CALLS.head.latency} kind="r">
                  {c.latency_ms === null ? NONE : latency(c.latency_ms)}
                </Cell>
                <Cell label={CALLS.head.cost} kind="r">
                  {c.cost_paise === null ? NONE : rupees(c.cost_paise)}
                </Cell>
                <Cell label={CALLS.head.from} kind="dim">
                  {c.started_by}
                </Cell>
              </Row>
            );
          })}
        </Table>
      </Section>
    </Frame>
  );
}
