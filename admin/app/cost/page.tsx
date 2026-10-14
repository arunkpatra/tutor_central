import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { PageLink } from "@/components/PageLink";
import { Cell, Chip, Meter, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { PLAN_PAISE } from "@/content/centres";
import { COST, DAY_LINE_PAISE, monthLabel, stepRows } from "@/content/cost";
import { ENVIRONMENT, NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import { environment, preview } from "@/lib/env";
import { count, istDay, monthName, monthOf, perStudent, rupees } from "@/lib/format";
import { idOf } from "@/lib/ids";

export const metadata: Metadata = { title: "Cost" };

const CENTRE_COLS = "2fr 1fr 1fr 1fr 1.4fr";
const KIND_COLS = "1.3fr 1.1fr 1.7fr .7fr .7fr .6fr";
const MONTH_COLS = "1.6fr .8fr .8fr 1.2fr 1.1fr 1.4fr";
type Query = { month?: string; centre?: string };

function href(q: Query, change: Partial<Query>): string {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries({ ...q, ...change })) if (v) params.set(k, v);
  const s = params.toString();
  return s ? `/cost?${s}` : "/cost";
}

/** The last six months, newest first, as `YYYY-MM`. */
function months(at: Date): string[] {
  const [y, m] = istDay(at).split("-").map(Number) as [number, number];
  return Array.from({ length: 6 }, (_, i) => {
    const d = new Date(Date.UTC(y, m - 1 - i, 15));
    return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
  });
}

export default async function CostPage({ searchParams }: { searchParams: Promise<Query> }) {
  await requireAdmin("/cost");
  const q = await searchParams;
  const at = now();
  const month = monthOf(q.month, at);
  const centre = q.centre ? idOf(q.centre, preview()) : null;
  const [cost, centres] = await Promise.all([data().cost(month, centre), data().centres(month)]);
  const centreName = centre ? (centres.rows.find((r) => r.id === centre)?.name ?? null) : null;
  // This month's chart stops at today; an earlier month shows every day.
  const today = istDay(at);
  const days = cost.byDay.filter((d) => d.day <= today);
  const highest = Math.max(0, ...days.map((d) => d.paise));
  const kinds = stepRows(cost.byStep, 10);
  // The months with calls, newest first; this one always.
  const byMonth = [...cost.byMonth].reverse().filter((m) => m.calls > 0 || m.month.slice(0, 7) === today.slice(0, 7));
  const kindTotal = kinds.reduce((s, k) => s + k.paise, 0);
  return (
    <Frame current="Cost">
      <Title eyebrow={ENVIRONMENT[environment()]} title={COST.title} lead={COST.lead}>
        <Pill
          label={COST.month}
          options={months(at).map((m) => ({
            label: monthName(`${m}-01`),
            href: href(q, { month: m }),
            current: `${m}-01` === month,
          }))}
        />
        <Pill
          label={COST.centre}
          options={[
            { label: COST.all, href: href(q, { centre: "" }), current: !centre },
            ...centres.rows.map((r) => ({ label: r.name, href: href(q, { centre: r.id }), current: r.id === centre })),
          ]}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={rupees(cost.tiles.month_paise)} label={COST.tiles.month} />
          <Tile value={rupees(cost.tiles.per_active_centre_paise)} label={COST.tiles.perCentre} />
          <Tile value={rupees(cost.tiles.today_paise)} label={COST.tiles.today} tone="due" />
          <Tile
            value={`${Math.round((cost.tiles.per_active_centre_paise / PLAN_PAISE) * 100)}%`}
            label={COST.tiles.share}
          />
        </Tiles>
      </Section>
      <Section>
        <div className="card chart">
          <div className="spread">
            <span className="h3">{COST.byDay(centreName)}</span>
            <span className="small">{COST.line(monthName(month))}</span>
          </div>
          <div className="bars">
            {days.map((d) => (
              <div
                key={d.day}
                className={centre && d.paise > DAY_LINE_PAISE ? "bar over" : "bar"}
                style={{ height: `${highest > 0 ? Math.round((d.paise / highest) * 100) : 0}%` }}
              >
                {highest > 0 && d.paise === highest ? <span className="barTop">{rupees(d.paise)}</span> : null}
              </div>
            ))}
          </div>
          <div className="barlabels">
            {days.map((d) => (
              <span key={d.day}>{Number(d.day.slice(8))}</span>
            ))}
          </div>
        </div>
      </Section>
      <Section title={COST.split} lead={COST.splitLead}>
        <div className="stack">
          <Table
            cols={CENTRE_COLS}
            head={[
              { label: COST.centreHead.centre },
              { label: COST.centreHead.calls, right: true },
              { label: COST.centreHead.cost, right: true },
              { label: COST.centreHead.perStudent, right: true },
              { label: COST.centreHead.share },
            ]}
          >
            {cost.byCentre.map((r) => (
              <Row key={r.id} cols={CENTRE_COLS}>
                <Cell label={COST.centreHead.centre} kind="main">
                  <PageLink className="plain" href={`/centres/${r.id}`}>
                    {r.name}
                  </PageLink>
                </Cell>
                <Cell label={COST.centreHead.calls} kind="r">
                  {count(r.calls)}
                </Cell>
                <Cell label={COST.centreHead.cost} kind="r">
                  {rupees(r.paise)}
                </Cell>
                <Cell label={COST.centreHead.perStudent} kind="r">
                  {r.per_student_paise === null ? NONE : perStudent(r.per_student_paise)}
                </Cell>
                <Cell label={COST.centreHead.share}>
                  {Math.round((r.paise / PLAN_PAISE) * 100)}%
                  <Meter share={r.paise / PLAN_PAISE} />
                </Cell>
              </Row>
            ))}
          </Table>
          <Table
            cols={KIND_COLS}
            head={[
              { label: COST.kindHead.kind },
              { label: COST.kindHead.step },
              { label: COST.kindHead.model },
              { label: COST.kindHead.calls, right: true },
              { label: COST.kindHead.cost, right: true },
              { label: COST.kindHead.share, right: true },
            ]}
          >
            {kinds.map((k) => (
              <Row key={`${k.kind}|${k.step}|${k.batched}`} cols={KIND_COLS}>
                <Cell label={COST.kindHead.kind} kind="main">
                  {k.kind}
                </Cell>
                <Cell label={COST.kindHead.step} kind="dim">
                  {k.step}
                  {k.batched ? (
                    <>
                      {" "}
                      <Chip tone="accent">{COST.batched}</Chip>
                    </>
                  ) : null}
                </Cell>
                <Cell label={COST.kindHead.model} kind="dim">
                  {k.models}
                </Cell>
                <Cell label={COST.kindHead.calls} kind="r">
                  {count(k.calls)}
                </Cell>
                <Cell label={COST.kindHead.cost} kind="r">
                  {rupees(k.paise)}
                </Cell>
                <Cell label={COST.kindHead.share} kind="r">
                  {kindTotal > 0 ? `${Math.round((k.paise / kindTotal) * 100)}%` : NONE}
                </Cell>
              </Row>
            ))}
          </Table>
        </div>
      </Section>
      <Section title={COST.byMonth} lead={COST.byMonthLead}>
        <Table
          cols={MONTH_COLS}
          head={[
            { label: COST.monthHead.month },
            { label: COST.monthHead.calls, right: true },
            { label: COST.monthHead.cost, right: true },
            { label: COST.monthHead.batched, right: true },
            { label: COST.monthHead.perCentre, right: true },
            { label: COST.monthHead.share },
          ]}
        >
          {byMonth.map((m) => (
            <Row key={m.month} cols={MONTH_COLS}>
              <Cell label={COST.monthHead.month} kind="main">
                {monthLabel(m.month, today)}
              </Cell>
              <Cell label={COST.monthHead.calls} kind="r">
                {count(m.calls)}
              </Cell>
              <Cell label={COST.monthHead.cost} kind="r">
                {rupees(m.paise)}
              </Cell>
              <Cell label={COST.monthHead.batched} kind="r">
                {m.batched_paise > 0
                  ? `${rupees(m.batched_paise)} · ${Math.round((m.batched_paise / m.paise) * 100)}%`
                  : rupees(0)}
              </Cell>
              <Cell label={COST.monthHead.perCentre} kind="r">
                {rupees(m.per_active_centre_paise)}
              </Cell>
              <Cell label={COST.monthHead.share}>
                {Math.round((m.per_active_centre_paise / PLAN_PAISE) * 100)}%
                <Meter share={m.per_active_centre_paise / PLAN_PAISE} />
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
    </Frame>
  );
}
