import type { Metadata } from "next";
import { cookies } from "next/headers";
import { notFound, redirect } from "next/navigation";
import { Frame } from "@/components/Frame";
import { Cell, Chip, Row, Section, Table, Title } from "@/components/parts";
import { consentChip, madeWords, meets, RECORD, tracking } from "@/content/record";
import { NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import { preview } from "@/lib/env";
import { rupees, time, when } from "@/lib/format";
import { idOf } from "@/lib/ids";
import { recordAsk, recordCookie } from "../reason";

export const metadata: Metadata = { title: "The record" };

const STUDENT_COLS = "1.6fr .6fr 1.2fr 1.2fr 1fr";
const BATCH_COLS = "1.6fr 1fr 1.2fr .8fr";
const MADE_COLS = "1fr 2fr 1fr";

/** "17:00" from Postgres's "17:00:00". */
const hhmm = (t: string | null) => (t ? t.slice(0, 5) : NONE);

/** The record, served only from a fresh open's audit row (0047's admin_record_opened): a bookmark asks again. */
export default async function RecordPage({ params }: { params: Promise<{ id: string }> }) {
  const { id: raw } = await params;
  const admin = await requireAdmin(`/centres/${raw}`);
  const id = idOf(raw, preview());
  if (!id) notFound();
  const audit = preview() ? undefined : (await cookies()).get(recordCookie(id))?.value;
  const ask = recordAsk(id, audit, preview());
  if (ask) redirect(ask);
  const record = await data().record(audit ?? "preview", admin.userId);
  if (!record || record.centre.id !== id) redirect(`/centres/${id}?ask=1`);
  const at = now();
  return (
    <Frame current="Centres">
      <Title eyebrow={RECORD.eyebrow} title={record.centre.name} lead={RECORD.lead} />
      <Section>
        <div className="banner">
          <b>{RECORD.opened(time(record.opened_at))}</b>
          <span>{RECORD.reason(record.reason)}</span>
          <span>{RECORD.audited}</span>
        </div>
      </Section>
      <Section title={RECORD.students} lead={RECORD.studentsLead(record.students.length)}>
        <Table
          cols={STUDENT_COLS}
          head={[
            { label: RECORD.head.student },
            { label: RECORD.head.class, right: true },
            { label: RECORD.head.batch },
            { label: RECORD.head.consent },
            { label: RECORD.head.tracking },
          ]}
        >
          {record.students.map((s) => {
            const chip = consentChip(s.consent);
            return (
              <Row key={s.id} cols={STUDENT_COLS}>
                <Cell label={RECORD.head.student} kind="main">
                  {s.name}
                </Cell>
                <Cell label={RECORD.head.class} kind="r">
                  {s.class_level ?? NONE}
                </Cell>
                <Cell label={RECORD.head.batch}>{s.batch ?? NONE}</Cell>
                <Cell label={RECORD.head.consent}>
                  <Chip tone={chip.tone}>{chip.text}</Chip>
                </Cell>
                <Cell label={RECORD.head.tracking} kind="dim">
                  {tracking(s.tracking)}
                </Cell>
              </Row>
            );
          })}
        </Table>
      </Section>
      <Section title={RECORD.batches}>
        <Table
          cols={BATCH_COLS}
          head={[
            { label: RECORD.batchHead.batch },
            { label: RECORD.batchHead.meets },
            { label: RECORD.batchHead.time },
            { label: RECORD.batchHead.students, right: true },
          ]}
        >
          {record.batches.map((b) => (
            <Row key={b.name} cols={BATCH_COLS}>
              <Cell label={RECORD.batchHead.batch} kind="main">
                {b.name}
              </Cell>
              <Cell label={RECORD.batchHead.meets}>{meets(b.days)}</Cell>
              <Cell label={RECORD.batchHead.time} kind="dim">
                {b.start_time ? RECORD.time(hhmm(b.start_time), hhmm(b.end_time)) : NONE}
              </Cell>
              <Cell label={RECORD.batchHead.students} kind="r">
                {b.students}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
      <Section title={RECORD.made} lead={RECORD.madeLead}>
        <Table
          cols={MADE_COLS}
          head={[
            { label: RECORD.madeHead.when },
            { label: RECORD.madeHead.what },
            { label: RECORD.madeHead.cost, right: true },
          ]}
          empty={RECORD.nothingKept}
        >
          {record.made.map((m) => (
            <Row key={m.id} cols={MADE_COLS}>
              <Cell label={RECORD.madeHead.when}>{when(m.at, at)}</Cell>
              <Cell label={RECORD.madeHead.what}>{madeWords(m)}</Cell>
              <Cell label={RECORD.madeHead.cost} kind="r">
                {rupees(m.cost_paise)}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
    </Frame>
  );
}
