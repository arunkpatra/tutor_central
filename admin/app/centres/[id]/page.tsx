import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Frame } from "@/components/Frame";
import {
  Button,
  Cell,
  Chip,
  Dialog,
  Field,
  LinkButton,
  Meter,
  Pill,
  Row,
  Section,
  Table,
  Tile,
  Tiles,
  Title,
} from "@/components/parts";
import { activityWords } from "@/content/activity";
import { CENTRE, PLAN_PAISE } from "@/content/centres";
import { finished, stateChip } from "@/content/jobs";
import { family } from "@/content/models";
import { ASK } from "@/content/record";
import { NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import type { Centre } from "@/lib/data/types";
import { preview } from "@/lib/env";
import { count, dayMonth, monthName, monthOf, rupees, when } from "@/lib/format";
import { idOf } from "@/lib/ids";
import { openRecord } from "./actions";

export const metadata: Metadata = { title: "Centre" };

const TUTOR_COLS = "1.6fr 1.6fr 1fr 1fr";
const JOB_COLS = "1fr 1.3fr .9fr 1.1fr .7fr";
const ACTIVITY_COLS = "1.1fr 2fr 1fr";

/** The last six months, newest first, as `YYYY-MM`. */
function months(at: Date): string[] {
  const first = new Date(`${monthOf(undefined, at)}T12:00:00+05:30`);
  return Array.from({ length: 6 }, (_, i) => {
    const d = new Date(first);
    d.setMonth(d.getMonth() - i);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
  });
}

/** "Sonnet 71% · Haiku 29%". */
function modelShares(c: Centre): string {
  const total = c.cost_by_model.reduce((s, m) => s + m.paise, 0);
  if (total === 0) return NONE;
  return c.cost_by_model.map((m) => `${family(m.model)} ${Math.round((m.paise / total) * 100)}%`).join(" · ");
}

function lastClose(c: Centre, at: Date): { value: string; label: string } {
  if (!c.last_close) return { value: NONE, label: CENTRE.tiles.noClose };
  const w = when(c.last_close, at);
  const [day, time] = w.startsWith("Today ")
    ? ["today", w.slice(6)]
    : w.startsWith("Yesterday ")
      ? ["yesterday", w.slice(10)]
      : [dayMonth(c.last_close), w.slice(-5)];
  return { value: time, label: CENTRE.tiles.lastClose(day) };
}

export default async function CentrePage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ month?: string; ask?: string; empty?: string }>;
}) {
  const { id: raw } = await params;
  await requireAdmin(`/centres/${raw}`);
  const id = idOf(raw, preview());
  if (!id) notFound();
  const at = now();
  const query = await searchParams;
  const month = monthOf(query.month, at);
  const c = await data().centre(id, month);
  if (!c) notFound();
  const [jobs, activity] = await Promise.all([data().centreJobs(id, 5), data().activity(id, 12)]);
  const share = c.cost_paise / PLAN_PAISE;
  const close = lastClose(c, at);
  return (
    <Frame current="Centres">
      <Title
        eyebrow={CENTRE.eyebrow}
        title={c.name}
        lead={CENTRE.lead(c.owner_name, dayMonth(c.since), c.students, c.batches)}
      >
        <Chip tone={c.in_use ? "ok" : "neutral"}>{c.in_use ? CENTRE.inUse : CENTRE.idle}</Chip>
        <Pill
          label={CENTRE.month}
          options={months(at).map((m) => ({
            label: monthName(`${m}-01`),
            href: `/centres/${id}?month=${m}`,
            current: `${m}-01` === month,
          }))}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={rupees(c.cost_paise)} label={CENTRE.tiles.cost} />
          <Tile value={count(c.calls)} label={CENTRE.tiles.calls} />
          <Tile
            value={`${c.jobs_today} / ${c.failed_today}`}
            label={CENTRE.tiles.jobs}
            tone={c.failed_today > 0 ? "overdue" : undefined}
          />
          <Tile value={close.value} label={close.label} />
        </Tiles>
      </Section>
      <Section title={CENTRE.tutorsAndCost}>
        <div className="cols2">
          <Table
            cols={TUTOR_COLS}
            head={[
              { label: CENTRE.head.tutor },
              { label: CENTRE.head.email },
              { label: CENTRE.head.signIn },
              { label: CENTRE.head.push },
            ]}
          >
            {c.tutors.map((t) => (
              <Row key={t.user_id} cols={TUTOR_COLS}>
                <Cell label={CENTRE.head.tutor} kind="strong" sub={t.role === "owner" ? "owner" : undefined}>
                  {t.name ?? NONE}
                </Cell>
                <Cell label={CENTRE.head.email} kind="dim">
                  {t.email ?? NONE}
                </Cell>
                <Cell label={CENTRE.head.signIn}>{t.last_sign_in ? when(t.last_sign_in, at) : NONE}</Cell>
                <Cell label={CENTRE.head.push}>
                  {t.push ? <Chip tone="ok">{CENTRE.push(t.push.build)}</Chip> : <Chip>{CENTRE.noDevice}</Chip>}
                </Cell>
              </Row>
            ))}
          </Table>
          <div className="card padded loose">
            <div className="spread">
              <span className="h3">{CENTRE.monthSoFar(monthName(month))}</span>
              <span className="small">
                {CENTRE.allowance(c.allowance, c.allowance_paise ? rupees(c.allowance_paise) : null)}
              </span>
            </div>
            <div>
              <div className="figure">
                {rupees(c.cost_paise)} <span className="figureOf">{CENTRE.ofPlan(Math.round(share * 100))}</span>
              </div>
              <Meter share={share} />
            </div>
            <div className="row">
              <span>{CENTRE.calls(c.calls)}</span>
              <span>
                {CENTRE.byKind(rupees(c.cost_by_kind.plan), rupees(c.cost_by_kind.notes), rupees(c.cost_by_kind.exams))}
              </span>
              <span>{modelShares(c)}</span>
            </div>
          </div>
        </div>
      </Section>
      <Section
        title={CENTRE.jobs}
        lead={CENTRE.jobsLead}
        action={
          <LinkButton kind="secondary" href={`/jobs?centre=${id}`}>
            {CENTRE.allJobs}
          </LinkButton>
        }
      >
        <Table
          cols={JOB_COLS}
          head={[
            { label: CENTRE.jobsHead.kind },
            { label: CENTRE.jobsHead.subject },
            { label: CENTRE.jobsHead.state },
            { label: CENTRE.jobsHead.finished },
            { label: CENTRE.jobsHead.cost, right: true },
          ]}
        >
          {jobs.map((j) => {
            const chip = stateChip(j, false);
            return (
              <Row key={j.id} cols={JOB_COLS}>
                <Cell label={CENTRE.jobsHead.kind}>
                  <a className="plain" href={`/jobs?centre=${id}&day=all&open=${j.id}`}>
                    {j.kind}
                  </a>
                </Cell>
                <Cell label={CENTRE.jobsHead.subject} kind="dim">
                  {j.subject}
                </Cell>
                <Cell label={CENTRE.jobsHead.state}>
                  <Chip tone={chip.tone}>{chip.text}</Chip>
                </Cell>
                <Cell label={CENTRE.jobsHead.finished} kind="dim">
                  {finished(j, at)}
                </Cell>
                <Cell label={CENTRE.jobsHead.cost} kind="r">
                  {rupees(j.cost_paise)}
                </Cell>
              </Row>
            );
          })}
        </Table>
      </Section>
      <Section title={CENTRE.activity} lead={CENTRE.activityLead}>
        <div className="cols2">
          <Table
            cols={ACTIVITY_COLS}
            head={[
              { label: CENTRE.activityHead.when },
              { label: CENTRE.activityHead.what },
              { label: CENTRE.activityHead.who },
            ]}
          >
            {activity.map((a) => (
              <Row key={`${a.at}-${a.kind}-${a.what ?? a.screen}`} cols={ACTIVITY_COLS}>
                <Cell label={CENTRE.activityHead.when}>{when(a.at, at)}</Cell>
                <Cell label={CENTRE.activityHead.what}>{a.what ?? activityWords(a.kind, a.screen)}</Cell>
                <Cell label={CENTRE.activityHead.who} kind="dim">
                  {a.who ?? NONE}
                </Cell>
              </Row>
            ))}
          </Table>
          <div className="card padded">
            <span className="h3">{CENTRE.record}</span>
            <p className="lead small">{CENTRE.recordLead}</p>
            <div>
              <LinkButton kind="secondary" href={`/centres/${id}?ask=1`}>
                {CENTRE.openRecord}
              </LinkButton>
            </div>
          </div>
        </div>
      </Section>
      {query.ask ? (
        <Dialog title={ASK.title(c.name)} lead={ASK.lead}>
          <form action={openRecord} className="stack">
            <input type="hidden" name="centre" value={id} />
            <Field label={ASK.reason} name="reason" placeholder={ASK.reasonHint} required maxLength={200} />
            {query.empty ? <p className="fieldError">{ASK.empty}</p> : null}
            <div className="dialogActions">
              <LinkButton kind="quiet" href={`/centres/${id}`}>
                {ASK.cancel}
              </LinkButton>
              <Button kind="primary">{ASK.open}</Button>
            </div>
          </form>
        </Dialog>
      ) : null}
    </Frame>
  );
}
