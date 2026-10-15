import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Frame } from "@/components/Frame";
import { Cell, Chip, Dialog, Field, FormRow, LinkButton, Row, Section, Select, Table, Title } from "@/components/parts";
import { SubmitButton } from "@/components/SubmitButton";
import { EFFORTS, KNOWN_MODELS, knownModel, MODEL, MODELS, modelName, STEPS } from "@/content/models";
import { NONE, PENDING } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import { when } from "@/lib/format";
import { saveStep, switchOff, switchOn } from "../actions";
import { changedBy, changedWhen } from "../words";

export const metadata: Metadata = { title: "AI model" };

const CURRENT_COLS = "1fr 1.4fr .8fr 1.4fr .6fr 1.3fr";
const HISTORY_COLS = "1.2fr .7fr 1fr .7fr 1fr .5fr .9fr 2fr";
const KIND = /^[a-z0-9_]{1,40}$/;

function OnChip({ on }: { on: boolean }) {
  return on ? <Chip tone="ok">{MODELS.on}</Chip> : <Chip tone="overdue">{MODELS.off}</Chip>;
}

export default async function ModelPage({
  params,
  searchParams,
}: {
  params: Promise<{ kind: string }>;
  searchParams: Promise<{ off?: string; empty?: string; bad?: string }>;
}) {
  const { kind: raw } = await params;
  const admin = await requireAdmin(`/models/${raw}`);
  if (!KIND.test(raw)) notFound();
  const q = await searchParams;
  const at = now();
  const [model, me] = await Promise.all([data().model(raw), data().adminEmail(admin.userId)]);
  if (!model) notFound();
  const kind = model.kind;
  const draft = model.current.find((s) => s.step === "draft");
  const on = draft?.enabled ?? true;
  const models = KNOWN_MODELS.map((m) => ({ value: m, label: modelName(m) }));
  // A row written by SQL can name a model this portal does not know: shown as it is, so Save never changes it unasked.
  const odd = draft && !knownModel(draft.model) ? [{ value: draft.model, label: MODEL.unknownModel(draft.model) }] : [];
  return (
    <Frame current="Models">
      <Title eyebrow={MODEL.eyebrow(kind)} title={kind} lead={MODEL.lead(kind)}>
        <OnChip on={on} />
        {on ? (
          <LinkButton kind="destructive" href={`/models/${raw}?off=1`}>
            {MODEL.switchOff}
          </LinkButton>
        ) : (
          <form action={switchOn}>
            <input type="hidden" name="kind" value={kind} />
            <SubmitButton kind="primary" working={PENDING.switchOn}>
              {MODEL.switchOn}
            </SubmitButton>
          </form>
        )}
      </Title>
      <Section title={MODEL.current}>
        <Table
          cols={CURRENT_COLS}
          head={[
            { label: MODEL.head.step },
            { label: MODEL.head.model },
            { label: MODEL.head.effort },
            { label: MODEL.head.fallback },
            { label: MODEL.head.on },
            { label: MODEL.head.since },
          ]}
        >
          {model.current.map((s) => (
            <Row key={s.step} cols={CURRENT_COLS}>
              <Cell label={MODEL.head.step} kind="main" sub={MODEL.steps[s.step]}>
                {s.step}
              </Cell>
              <Cell label={MODEL.head.model}>{modelName(s.model)}</Cell>
              <Cell label={MODEL.head.effort}>{s.effort}</Cell>
              <Cell label={MODEL.head.fallback}>{s.fallback_model ? modelName(s.fallback_model) : NONE}</Cell>
              <Cell label={MODEL.head.on}>
                <OnChip on={s.enabled} />
              </Cell>
              <Cell label={MODEL.head.since} kind="dim">
                {changedWhen(s.since, at)} · {changedBy(s.set_by, s.note, me)}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
      <Section title={MODEL.change} lead={MODEL.changeLead}>
        <form action={saveStep} className="card padded stack">
          <input type="hidden" name="kind" value={kind} />
          <FormRow>
            <Select
              label={MODEL.head.step}
              name="step"
              options={STEPS.map((s) => ({ value: s, label: s }))}
              defaultValue="draft"
            />
            <Select
              label={MODEL.head.model}
              name="model"
              options={[...odd, ...models]}
              defaultValue={draft?.model}
              error={q.bad === "model" ? MODEL.badModel : undefined}
            />
            <Select
              label={MODEL.head.effort}
              name="effort"
              options={EFFORTS.map((e) => ({ value: e, label: e }))}
              defaultValue={draft?.effort}
            />
            <Select
              label={MODEL.head.fallback}
              name="fallback"
              options={[{ value: "", label: MODEL.noFallback }, ...models]}
              defaultValue={draft?.fallback_model ?? ""}
            />
          </FormRow>
          <Field label={MODEL.note} name="note" placeholder={MODEL.noteHint} maxLength={400} />
          <div className="formFoot">
            <SubmitButton kind="primary" working={PENDING.save}>
              {MODEL.save}
            </SubmitButton>
            <span className="formNote">{MODEL.saveNote}</span>
          </div>
        </form>
      </Section>
      <Section title={MODEL.history} lead={MODEL.historyLead}>
        <Table
          cols={HISTORY_COLS}
          head={[
            { label: MODEL.historyHead.when },
            { label: MODEL.historyHead.step },
            { label: MODEL.historyHead.model },
            { label: MODEL.historyHead.effort },
            { label: MODEL.historyHead.fallback },
            { label: MODEL.historyHead.on },
            { label: MODEL.historyHead.by },
            { label: MODEL.historyHead.note },
          ]}
        >
          {model.history.map((h) => (
            <Row key={h.id} cols={HISTORY_COLS}>
              <Cell label={MODEL.historyHead.when} kind="main">
                {when(h.since, at)}
              </Cell>
              <Cell label={MODEL.historyHead.step}>{h.step}</Cell>
              <Cell label={MODEL.historyHead.model}>{modelName(h.model)}</Cell>
              <Cell label={MODEL.historyHead.effort}>{h.effort}</Cell>
              <Cell label={MODEL.historyHead.fallback}>{h.fallback_model ? modelName(h.fallback_model) : NONE}</Cell>
              <Cell label={MODEL.historyHead.on}>
                <OnChip on={h.enabled} />
              </Cell>
              <Cell label={MODEL.historyHead.by} kind="dim">
                {h.set_by === "seed" ? "seed" : changedBy(h.set_by, null, me)}
              </Cell>
              <Cell label={MODEL.historyHead.note}>{h.note ?? NONE}</Cell>
            </Row>
          ))}
        </Table>
      </Section>
      {q.off && on ? (
        <Dialog title={MODEL.offTitle(kind)} lead={MODEL.offLead(kind)}>
          <form action={switchOff} className="stack">
            <input type="hidden" name="kind" value={kind} />
            <Field label={MODEL.reason} name="reason" placeholder={MODEL.reasonHint} required maxLength={400} />
            {q.empty ? <p className="fieldError">{MODEL.empty}</p> : null}
            <div className="dialogActions">
              <LinkButton kind="quiet" href={`/models/${raw}`}>
                {MODEL.cancel}
              </LinkButton>
              <SubmitButton kind="destructive" working={PENDING.switchOff}>
                {MODEL.switchOff}
              </SubmitButton>
            </div>
          </form>
        </Dialog>
      ) : null}
    </Frame>
  );
}
