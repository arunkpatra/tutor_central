import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { Cell, Pill, Row, Section, Table, Tile, Tiles, Title } from "@/components/parts";
import { SubmitButton } from "@/components/SubmitButton";
import { FIGURES, reasonLabel, weekLabel, weekLong } from "@/content/figures";
import { ENVIRONMENT, NONE, PENDING } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import type { Week } from "@/lib/data/types";
import { environment } from "@/lib/env";
import { count, istDay, rupees, when } from "@/lib/format";
import { sendReport } from "./actions";

export const metadata: Metadata = { title: "Product figures" };

const COLS = "1.4fr .8fr .7fr 1fr .8fr .9fr .6fr .8fr 1fr";
const REASON_COLS = "2fr .6fr .8fr";

function perTutor(w: Week): string {
  return w.tutors_active > 0 ? rupees(w.per_active_tutor_paise) : NONE;
}

/** A share as a whole percentage; none of nothing. */
function pct(part: number, whole: number): string {
  return whole > 0 ? `${Math.round((part / whole) * 100)}%` : NONE;
}

export default async function FiguresPage({
  searchParams,
}: {
  searchParams: Promise<{ weeks?: string; sent?: string }>;
}) {
  await requireAdmin("/figures");
  const q = await searchParams;
  const at = now();
  const weeks = (FIGURES.weekChoices as readonly string[]).includes(q.weeks ?? "") ? Number(q.weeks) : 8;
  const rows = await data().figures(weeks);
  const current = rows[0];
  const [reasons, last] = await Promise.all([
    current ? data().reasons(current.week_monday) : Promise.resolve({ again: [], edits: 0, made: 0, notes: 0 }),
    data().reportLast(),
  ]);
  const dayOfWeek = current ? Math.round((Date.parse(istDay(at)) - Date.parse(current.week_monday)) / 86_400_000) : 0;
  return (
    <Frame current="Figures">
      <Title eyebrow={ENVIRONMENT[environment()]} title={FIGURES.title} lead={FIGURES.lead}>
        <Pill
          label={FIGURES.weeks}
          options={FIGURES.weekChoices.map((w) => ({
            label: w,
            href: w === "8" ? "/figures" : `/figures?weeks=${w}`,
            current: Number(w) === weeks,
          }))}
        />
      </Title>
      {current ? (
        <Section>
          <Tiles>
            <Tile value={count(current.tutors_active)} label={FIGURES.tiles.tutors} />
            <Tile value={count(current.closes)} label={FIGURES.tiles.closes} />
            <Tile value={count(current.notes_sent)} label={FIGURES.tiles.notes} />
            <Tile value={perTutor(current)} label={FIGURES.tiles.perTutor} />
          </Tiles>
        </Section>
      ) : null}
      <Section title={FIGURES.byWeek} lead={FIGURES.byWeekLead}>
        <Table
          cols={COLS}
          head={[
            { label: FIGURES.head.week },
            { label: FIGURES.head.tutors, right: true },
            { label: FIGURES.head.closes, right: true },
            { label: FIGURES.head.plans, right: true },
            { label: FIGURES.head.notes, right: true },
            { label: FIGURES.head.made, right: true },
            { label: FIGURES.head.make, right: true },
            { label: FIGURES.head.consent, right: true },
            { label: FIGURES.head.perTutor, right: true },
          ]}
        >
          {rows.map((w) => (
            <Row key={w.week_monday} cols={COLS}>
              <Cell label={FIGURES.head.week} kind="main" sub={w.so_far ? FIGURES.soFar(dayOfWeek) : undefined}>
                {weekLabel(w.week_monday)}
              </Cell>
              <Cell label={FIGURES.head.tutors} kind="r">
                {count(w.tutors_active)}
              </Cell>
              <Cell label={FIGURES.head.closes} kind="r">
                {count(w.closes)}
              </Cell>
              <Cell label={FIGURES.head.plans} kind="r">
                {`${count(w.plans_made)} · ${count(w.plans_followed)}`}
              </Cell>
              <Cell label={FIGURES.head.notes} kind="r">
                {count(w.notes_sent)}
              </Cell>
              <Cell label={FIGURES.head.made} kind="r">
                {`${count(w.made)} · ${count(w.again)}`}
              </Cell>
              <Cell label={FIGURES.head.make} kind="r">
                {count(w.make)}
              </Cell>
              <Cell label={FIGURES.head.consent} kind="r">
                {count(w.consent_given)}
              </Cell>
              <Cell label={FIGURES.head.perTutor} kind="r">
                {perTutor(w)}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
      <Section>
        <div className="cols2">
          <div className="stack">
            <h2 className="h2">{FIGURES.reasons}</h2>
            <Table
              cols={REASON_COLS}
              head={[
                { label: FIGURES.reasonsHead.reason },
                { label: FIGURES.reasonsHead.count, right: true },
                { label: FIGURES.reasonsHead.of, right: true },
              ]}
            >
              {[
                ...reasons.again.map((r) => (
                  <Row key={r.reason} cols={REASON_COLS}>
                    <Cell
                      label={FIGURES.reasonsHead.reason}
                      kind="main"
                      sub={r.reason === "typed" ? FIGURES.typedSub : undefined}
                    >
                      {r.reason === "typed" ? FIGURES.typed : reasonLabel(r.reason)}
                    </Cell>
                    <Cell label={FIGURES.reasonsHead.count} kind="r">
                      {count(r.count)}
                    </Cell>
                    <Cell label={FIGURES.reasonsHead.of} kind="r">
                      {pct(r.count, reasons.made)}
                    </Cell>
                  </Row>
                )),
                <Row key="edited" cols={REASON_COLS}>
                  <Cell label={FIGURES.reasonsHead.reason} kind="main" sub={FIGURES.editedSub}>
                    {FIGURES.edited}
                  </Cell>
                  <Cell label={FIGURES.reasonsHead.count} kind="r">
                    {count(reasons.edits)}
                  </Cell>
                  <Cell label={FIGURES.reasonsHead.of} kind="r">
                    {reasons.notes > 0 ? FIGURES.ofNotes(Math.round((reasons.edits / reasons.notes) * 100)) : NONE}
                  </Cell>
                </Row>,
              ]}
            </Table>
          </div>
          <form action={sendReport} className="card padded stack">
            <span className="h3">{FIGURES.report}</span>
            <p className="lead small">{FIGURES.reportLead}</p>
            <p className="small">
              <b>{FIGURES.lastSent}</b>{" "}
              {last
                ? `${when(last.finished_at ?? last.created_at, at)} · ${FIGURES.reportLine(last.state, weekLong(last.week_monday), last.so_far)}`
                : FIGURES.never}
            </p>
            {q.sent ? <p className="banner">{FIGURES.sent}</p> : null}
            <div>
              <SubmitButton kind="primary" working={PENDING.send}>
                {FIGURES.send}
              </SubmitButton>
            </div>
          </form>
        </div>
      </Section>
    </Frame>
  );
}
