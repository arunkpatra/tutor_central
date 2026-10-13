import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { PageLink } from "@/components/PageLink";
import { Cell, Chip, Meter, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { CENTRES, PLAN_PAISE } from "@/content/centres";
import { ENVIRONMENT } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import type { CentreRow } from "@/lib/data/types";
import { environment } from "@/lib/env";
import { ago, count, dayMonth, monthOf, rupees } from "@/lib/format";

export const metadata: Metadata = { title: "Centres" };

const COLS = "2.2fr .7fr .7fr 1.2fr 1.3fr 1.3fr";
type Sort = keyof typeof CENTRES.sorts;
type Show = keyof typeof CENTRES.shows;
type Query = { month?: string; sort?: string; show?: string };

function sorted(rows: CentreRow[], sort: Sort): CentreRow[] {
  const by: Record<Sort, (a: CentreRow, b: CentreRow) => number> = {
    cost: (a, b) => b.cost_paise - a.cost_paise || a.name.localeCompare(b.name),
    name: (a, b) => a.name.localeCompare(b.name),
    opened: (a, b) => (b.last_opened ?? "").localeCompare(a.last_opened ?? ""),
  };
  return [...rows].sort(by[sort]);
}

function href(q: Query, change: Partial<Query>): string {
  const params = new URLSearchParams({ ...q, ...change } as Record<string, string>);
  for (const [k, v] of [...params]) if (!v) params.delete(k);
  const s = params.toString();
  return s ? `/centres?${s}` : "/centres";
}

export default async function CentresPage({ searchParams }: { searchParams: Promise<Query> }) {
  await requireAdmin("/centres");
  const q = await searchParams;
  const at = now();
  const sort: Sort = q.sort && q.sort in CENTRES.sorts ? (q.sort as Sort) : "cost";
  const show: Show = q.show && q.show in CENTRES.shows ? (q.show as Show) : "all";
  const centres = await data().centres(monthOf(q.month, at));
  const rows = sorted(centres.rows, sort).filter((r) => show === "all" || (show === "in-use" ? r.in_use : !r.in_use));
  return (
    <Frame current="Centres">
      <Title eyebrow={ENVIRONMENT[environment()]} title={CENTRES.title} lead={CENTRES.lead}>
        <Pill
          label={CENTRES.sort}
          options={Object.entries(CENTRES.sorts).map(([k, label]) => ({
            label,
            href: href(q, { sort: k }),
            current: k === sort,
          }))}
        />
        <Pill
          label={CENTRES.show}
          options={Object.entries(CENTRES.shows).map(([k, label]) => ({
            label,
            href: href(q, { show: k }),
            current: k === show,
          }))}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={count(centres.tiles.centres)} label={CENTRES.tiles.centres(centres.tiles.centres)} />
          <Tile value={count(centres.tiles.active_week)} label={CENTRES.tiles.active} />
          <Tile value={rupees(centres.tiles.cost_paise)} label={CENTRES.tiles.cost} />
          <Tile
            value={count(centres.tiles.failed_today)}
            label={CENTRES.tiles.failed(centres.tiles.failed_today)}
            tone={centres.tiles.failed_today > 0 ? "overdue" : undefined}
          />
        </Tiles>
      </Section>
      <Section title={CENTRES.list} lead={CENTRES.listLead}>
        <Table
          cols={COLS}
          head={[
            { label: CENTRES.head.centre },
            { label: CENTRES.head.students, right: true },
            { label: CENTRES.head.tutors, right: true },
            { label: CENTRES.head.opened },
            { label: CENTRES.head.cost },
            { label: CENTRES.head.jobs },
          ]}
        >
          {rows.map((r) => (
            <Row key={r.id} cols={COLS}>
              <Cell label={CENTRES.head.centre} kind="main" sub={CENTRES.since(r.owner_name, dayMonth(r.since))}>
                <PageLink className="plain" href={`/centres/${r.id}`}>
                  {r.name}
                </PageLink>
              </Cell>
              <Cell label={CENTRES.head.students} kind="r">
                {count(r.students)}
              </Cell>
              <Cell label={CENTRES.head.tutors} kind="r">
                {count(r.tutors)}
              </Cell>
              <Cell label={CENTRES.head.opened}>
                {r.last_opened ? ago(r.last_opened, at) : CENTRES.never}
                {r.in_use ? null : (
                  <>
                    {" "}
                    <Chip>{CENTRES.idle}</Chip>
                  </>
                )}
              </Cell>
              <Cell label={CENTRES.head.cost}>
                {rupees(r.cost_paise)}
                <Meter share={r.cost_paise / PLAN_PAISE} />
              </Cell>
              <Cell label={CENTRES.head.jobs} kind="dim">
                {CENTRES.jobs(r.jobs_today, r.failed_today, r.in_use)}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
    </Frame>
  );
}
