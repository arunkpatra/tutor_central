import type { Metadata } from "next";
import { Fragment } from "react";
import { Frame } from "@/components/Frame";
import { Button, Cell, Chip, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { shortCentre } from "@/content/calls";
import { cutIds, inputLine, JOBS, span, stateChip, stepNote } from "@/content/jobs";
import { ENVIRONMENT, NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import type { Job } from "@/lib/data/types";
import { environment, preview } from "@/lib/env";
import { count, istDay, rupees } from "@/lib/format";
import { idOf } from "@/lib/ids";
import { cancelJob, retryJob } from "./actions";

export const metadata: Metadata = { title: "Jobs" };

const COLS = ".9fr 1fr 1.5fr 1.4fr 1.1fr .5fr .6fr";
const STEP_COLS = "1.2fr .6fr 1fr 1.6fr .7fr";
type Query = { day?: string; state?: string; kind?: string; centre?: string; open?: string; done?: string };
type Day = keyof typeof JOBS.days;

function href(q: Query, change: Partial<Query>): string {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries({ ...q, done: undefined, ...change })) if (v) params.set(k, v);
  const s = params.toString();
  return s ? `/jobs?${s}` : "/jobs";
}

/** A job open in place (P19-Jobs): the error, Cancel or Retry, what just happened, its steps. */
function Opened({ job, q }: { job: Job; q: Query }) {
  const live = job.state === "queued" || job.state === "waiting" || job.state === "running";
  const back = href(q, { open: undefined });
  const done = q.done && q.done in JOBS.done ? JOBS.done[q.done as keyof typeof JOBS.done] : null;
  return (
    <div className="open">
      <div className="openHead">
        <span>
          {job.error ? (
            <>
              {JOBS.error}
              <span className="overdueText">{job.error.reason ?? "failed"}</span>
              {job.error.message ? ` · ${job.error.message}` : ""}
              {" · "}
            </>
          ) : null}
          input {inputLine(job.input)} · key {cutIds(job.idempotency_key)}
        </span>
        <div className="acts">
          {live ? (
            <form action={cancelJob}>
              <input type="hidden" name="job" value={job.id} />
              <input type="hidden" name="back" value={back} />
              <Button kind="destructive">{JOBS.cancel}</Button>
            </form>
          ) : null}
          {job.state === "failed" ? (
            <form action={retryJob}>
              <input type="hidden" name="job" value={job.id} />
              <input type="hidden" name="back" value={back} />
              <Button kind="primary">{JOBS.retry}</Button>
            </form>
          ) : null}
        </div>
      </div>
      {done ? <div className="banner">{done}</div> : null}
      <Table
        cols={STEP_COLS}
        head={[
          { label: JOBS.stepHead.step },
          { label: JOBS.stepHead.try, right: true },
          { label: JOBS.stepHead.state },
          { label: JOBS.stepHead.note },
          { label: JOBS.stepHead.cost, right: true },
        ]}
      >
        {job.steps.map((s) => {
          const chip = stateChip({ ...job, state: s.state, made: null }, false);
          return (
            <Row key={s.step} cols={STEP_COLS}>
              <Cell label={JOBS.stepHead.step} kind="main">
                {s.step}
              </Cell>
              <Cell label={JOBS.stepHead.try} kind="r">
                {s.attempt}
              </Cell>
              <Cell label={JOBS.stepHead.state}>
                <Chip tone={chip.tone}>{s.state}</Chip>
              </Cell>
              <Cell label={JOBS.stepHead.note} kind="dim">
                {stepNote(s)}
              </Cell>
              <Cell label={JOBS.stepHead.cost} kind="r">
                {rupees(s.cost_paise)}
              </Cell>
            </Row>
          );
        })}
      </Table>
    </div>
  );
}

export default async function JobsPage({ searchParams }: { searchParams: Promise<Query> }) {
  await requireAdmin("/jobs");
  const q = await searchParams;
  const at = now();
  const day: Day = q.day && q.day in JOBS.days ? (q.day as Day) : "today";
  const date = day === "all" ? null : istDay(new Date(at.getTime() - (day === "yesterday" ? 86_400_000 : 0)));
  const state = q.state && q.state in JOBS.states ? q.state : null;
  const kind = q.kind && (JOBS.kinds as readonly string[]).includes(q.kind) ? q.kind : null;
  const centre = q.centre ? idOf(q.centre, preview()) : null;
  const openId = q.open ? idOf(q.open, preview()) : null;
  const [jobs, centres, open] = await Promise.all([
    data().jobs({ day: date, state, kind, centre }),
    data().centres(`${istDay(at).slice(0, 7)}-01`),
    openId ? data().job(openId) : Promise.resolve(null),
  ]);
  return (
    <Frame current="Jobs">
      <Title eyebrow={ENVIRONMENT[environment()]} title={JOBS.title} lead={JOBS.lead}>
        <Pill
          label={JOBS.state}
          options={[
            { label: JOBS.all, href: href(q, { state: "" }), current: !state },
            ...Object.keys(JOBS.states).map((k) => ({ label: k, href: href(q, { state: k }), current: k === state })),
          ]}
        />
        <Pill
          label={JOBS.kind}
          options={[
            { label: JOBS.all, href: href(q, { kind: "" }), current: !kind },
            ...JOBS.kinds.map((k) => ({ label: k, href: href(q, { kind: k }), current: k === kind })),
          ]}
        />
        <Pill
          label={JOBS.centre}
          options={[
            { label: JOBS.all, href: href(q, { centre: "" }), current: !centre },
            ...centres.rows.map((r) => ({ label: r.name, href: href(q, { centre: r.id }), current: r.id === centre })),
          ]}
        />
        <Pill
          label={JOBS.day}
          options={Object.entries(JOBS.days).map(([k, label]) => ({
            label,
            href: href(q, { day: k }),
            current: k === day,
          }))}
        />
      </Title>
      <Section>
        <Tiles>
          <Tile value={count(jobs.tiles.today)} label={JOBS.tiles.today(day)} />
          <Tile
            value={count(jobs.tiles.failed)}
            label={JOBS.tiles.failed}
            tone={jobs.tiles.failed > 0 ? "overdue" : undefined}
          />
          <Tile
            value={count(jobs.tiles.running)}
            label={JOBS.tiles.running}
            tone={jobs.tiles.running > 0 ? "due" : undefined}
          />
          <Tile value={count(jobs.tiles.waiting)} label={JOBS.tiles.waiting} />
        </Tiles>
      </Section>
      <Section title={JOBS.list(day)} lead={JOBS.listLead(open ? { state: open.state, kind: open.kind } : null)}>
        <Table
          cols={COLS}
          head={[
            { label: JOBS.head.kind },
            { label: JOBS.head.centre },
            { label: JOBS.head.subject },
            { label: JOBS.head.state },
            { label: JOBS.head.when },
            { label: JOBS.head.tries, right: true },
            { label: JOBS.head.cost, right: true },
          ]}
        >
          {jobs.rows.map((j) => {
            const chip = stateChip(j, true);
            return (
              <Fragment key={j.id}>
                <Row cols={COLS}>
                  <Cell label={JOBS.head.kind} kind="main">
                    <a className="plain" href={href(q, { open: j.id === open?.id ? undefined : j.id })}>
                      {j.kind}
                    </a>
                  </Cell>
                  <Cell label={JOBS.head.centre} kind="dim">
                    {j.centre ? shortCentre(j.centre) : "—"}
                  </Cell>
                  <Cell label={JOBS.head.subject}>{j.subject ?? NONE}</Cell>
                  <Cell label={JOBS.head.state}>
                    <Chip tone={chip.tone}>{chip.text}</Chip>
                  </Cell>
                  <Cell label={JOBS.head.when} kind="dim">
                    {span(j, at)}
                  </Cell>
                  <Cell label={JOBS.head.tries} kind="r">
                    {j.attempts}
                  </Cell>
                  <Cell label={JOBS.head.cost} kind="r">
                    {rupees(j.cost_paise)}
                  </Cell>
                </Row>
                {open && open.id === j.id ? <Opened job={open} q={q} /> : null}
              </Fragment>
            );
          })}
        </Table>
      </Section>
    </Frame>
  );
}
