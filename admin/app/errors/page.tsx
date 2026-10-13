import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { Cell, Chip, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { shortCentre } from "@/content/calls";
import { ERRORS, reasonShort, reasonTone, reasonWords } from "@/content/reasons";
import { ENVIRONMENT, NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import { environment } from "@/lib/env";
import { count, short, shortId } from "@/lib/format";

export const metadata: Metadata = { title: "Errors" };

const ROUTE_COLS = "1.6fr .8fr 1.4fr .7fr .7fr";
const LATEST_COLS = "1fr 1.4fr .6fr 1.2fr 1.2fr 1fr";
type Query = { hours?: string; route?: string };

function href(q: Query, change: Partial<Query>): string {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries({ ...q, ...change })) if (v) params.set(k, v);
  const s = params.toString();
  return s ? `/errors?${s}` : "/errors";
}

export default async function ErrorsPage({ searchParams }: { searchParams: Promise<Query> }) {
  await requireAdmin("/errors");
  const q = await searchParams;
  const at = now();
  const hours = q.hours === "168" ? 168 : 24;
  const errors = await data().errors(hours, 50);
  const routes = [...new Set(errors.rows.map((r) => r.route))];
  const route = q.route && routes.includes(q.route) ? q.route : null;
  // A 401 is grouped as "any" route; the latest keep the route asked.
  const rows = errors.rows.filter((r) => !route || r.route === route);
  const recent = errors.recent.filter((r) => !route || r.route === route || (route === "any" && r.status === 401));
  return (
    <Frame current="Errors">
      <Title eyebrow={ENVIRONMENT[environment()]} title={ERRORS.title} lead={ERRORS.lead}>
        <Pill
          label={ERRORS.window}
          options={Object.entries(ERRORS.windows).map(([k, label]) => ({
            label,
            href: href(q, { hours: k === "24" ? "" : k }),
            current: Number(k) === hours,
          }))}
        />
        <Pill
          label={ERRORS.route}
          options={[
            { label: ERRORS.all, href: href(q, { route: "" }), current: !route },
            ...routes.map((r) => ({ label: r, href: href(q, { route: r }), current: r === route })),
          ]}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={count(errors.tiles.requests)} label={ERRORS.tiles.requests(hours)} />
          <Tile
            value={count(errors.tiles.errors)}
            label={ERRORS.tiles.errors(errors.tiles.rate_pct)}
            tone={errors.tiles.rate_pct > 5 ? "overdue" : undefined}
          />
          <Tile
            value={count(errors.tiles.timeouts)}
            label={ERRORS.tiles.timeouts}
            tone={errors.tiles.timeouts > 0 ? "overdue" : undefined}
          />
          <Tile
            value={
              errors.tiles.median_latency_ms === null ? NONE : `${count(Math.round(errors.tiles.median_latency_ms))} ms`
            }
            label={ERRORS.tiles.latency}
          />
        </Tiles>
      </Section>
      <Section title={ERRORS.byRoute} lead={ERRORS.byRouteLead}>
        <Table
          cols={ROUTE_COLS}
          head={[
            { label: ERRORS.head.route },
            { label: ERRORS.head.status, right: true },
            { label: ERRORS.head.reason },
            { label: ERRORS.head.window(hours), right: true },
            { label: ERRORS.head.week, right: true },
          ]}
        >
          {rows.map((r) => (
            <Row key={`${r.route}-${r.status}-${r.reason}`} cols={ROUTE_COLS}>
              <Cell label={ERRORS.head.route} kind="main">
                {r.route}
              </Cell>
              <Cell label={ERRORS.head.status} kind="r">
                {r.status}
              </Cell>
              <Cell label={ERRORS.head.reason}>{reasonWords(r.reason, r.status)}</Cell>
              <Cell label={ERRORS.head.window(hours)} kind="r">
                {count(r.last_24h)}
              </Cell>
              <Cell label={ERRORS.head.week} kind="r">
                {count(r.last_7d)}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
      <Section title={ERRORS.latest} lead={ERRORS.latestLead}>
        <Table
          cols={LATEST_COLS}
          head={[
            { label: ERRORS.latestHead.time },
            { label: ERRORS.latestHead.route },
            { label: ERRORS.latestHead.status, right: true },
            { label: ERRORS.latestHead.reason },
            { label: ERRORS.latestHead.request },
            { label: ERRORS.latestHead.centre },
          ]}
        >
          {recent.map((r) => (
            <Row key={r.request_id + r.created_at} cols={LATEST_COLS}>
              <Cell label={ERRORS.latestHead.time}>{short(r.created_at, at, true)}</Cell>
              <Cell label={ERRORS.latestHead.route} kind="main">
                {r.route}
              </Cell>
              <Cell label={ERRORS.latestHead.status} kind="r">
                {r.status}
              </Cell>
              <Cell label={ERRORS.latestHead.reason}>
                <Chip tone={reasonTone(r.status)}>{reasonShort(r.reason, r.status)}</Chip>
              </Cell>
              <Cell label={ERRORS.latestHead.request} kind="dim">
                {shortId(r.request_id)}
              </Cell>
              <Cell label={ERRORS.latestHead.centre} kind="dim">
                {r.centre ? shortCentre(r.centre) : NONE}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
    </Frame>
  );
}
