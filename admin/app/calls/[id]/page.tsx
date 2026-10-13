import type { Metadata } from "next";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { Frame } from "@/components/Frame";
import { Cell, Chip, Code, LinkButton, Row, Section, Table, Title } from "@/components/parts";
import { CALL, DEADLINE_MS, outcomeChip } from "@/content/calls";
import { NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import { preview } from "@/lib/env";
import { count, dayMonth, rupees, time } from "@/lib/format";
import { idOf } from "@/lib/ids";

export const metadata: Metadata = { title: "AI call" };

const COLS = "1fr 2fr";

/** JSON as the board shows it, two spaces; text as it is. */
function pretty(value: unknown): string {
  if (typeof value === "string") {
    try {
      return JSON.stringify(JSON.parse(value), null, 2);
    } catch {
      return value;
    }
  }
  return JSON.stringify(value, null, 2);
}

export default async function CallPage({ params }: { params: Promise<{ id: string }> }) {
  const { id: raw } = await params;
  await requireAdmin(`/calls/${raw}`);
  const id = idOf(raw, preview());
  if (!id) notFound();
  const call = await data().call(id);
  if (!call) notFound();
  const chip = outcomeChip(call.status, call.error_reason);
  const jobHref = call.job ? `/jobs?day=all&open=${call.job.id}` : null;
  const facts: [string, ReactNode][] = [
    [CALL.facts.kind, CALL.kindOf(call.kind, call.student)],
    [CALL.facts.model, CALL.model(call.model ?? NONE, call.fallback_model)],
    [CALL.facts.prompt, CALL.prompt(call.kind, call.prompt_version, call.prompt_hash)],
    [
      CALL.facts.outcome,
      <>
        <Chip tone={chip.tone}>{chip.text}</Chip>
        <span className="dim">{CALL.outcomeMore(call.stop_reason, call.error_reason)}</span>
      </>,
    ],
    [CALL.facts.tokens, CALL.tokens(call.tokens_in, call.tokens_out)],
    [
      CALL.facts.latency,
      call.latency_ms === null ? NONE : CALL.latency(count(call.latency_ms), call.latency_ms >= DEADLINE_MS),
    ],
    [CALL.facts.cost, call.cost_paise === null ? NONE : CALL.cost(rupees(call.cost_paise), call.cost_paise)],
    [
      CALL.facts.started,
      <>
        {CALL.started(call.started_by, call.job?.subject ?? null, call.job?.step ?? null)}
        {jobHref ? (
          <>
            {" · "}
            <a href={jobHref}>{CALL.openJobLink}</a>
          </>
        ) : null}
      </>,
    ],
    [CALL.facts.request, CALL.request(call.request_id, call.idempotency_key)],
    [
      CALL.facts.centre,
      call.centre ? (
        <a key="centre" href={`/centres/${call.centre_id}`}>
          {call.centre}
        </a>
      ) : (
        NONE
      ),
    ],
  ];
  return (
    <Frame current="Calls">
      <Title
        eyebrow={CALL.eyebrow(`${dayMonth(call.created_at)} ${time(call.created_at, true)}`)}
        title={CALL.title(call.kind, call.centre)}
      >
        <Chip tone={chip.tone}>{chip.text}</Chip>
        {jobHref ? (
          <LinkButton kind="secondary" href={jobHref}>
            {CALL.openJob}
          </LinkButton>
        ) : null}
      </Title>
      <Section>
        <div className="cols2">
          <Table cols={COLS} head={[{ label: CALL.head.fact }, { label: CALL.head.value }]} bare>
            {facts.map(([label, value]) => (
              <Row key={label} cols={COLS}>
                <Cell label={label} kind="dim">
                  {label}
                </Cell>
                <Cell label={label}>{value}</Cell>
              </Row>
            ))}
          </Table>
          <div className="stack">
            {call.input_held ? (
              <div>
                <div className="h3 codeTitle">{CALL.input}</div>
                <p className="banner">{CALL.held}</p>
              </div>
            ) : (
              <Code title={CALL.input}>{pretty(call.input)}</Code>
            )}
            <Code title={CALL.output}>{call.output === null ? CALL.noOutput : pretty(call.output)}</Code>
          </div>
        </div>
      </Section>
    </Frame>
  );
}
