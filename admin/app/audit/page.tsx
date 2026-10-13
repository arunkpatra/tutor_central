import type { Metadata } from "next";
import { Frame } from "@/components/Frame";
import { Cell, Pill, Row, Section, Table, Title } from "@/components/parts";
import { AUDIT, auditDetail } from "@/content/alerts";
import { ENVIRONMENT, NONE } from "@/content/words";
import { requireAdmin } from "@/lib/admin";
import { now } from "@/lib/clock";
import { data } from "@/lib/data";
import { environment } from "@/lib/env";
import { maskIp, when } from "@/lib/format";

export const metadata: Metadata = { title: "Audit" };

const COLS = "1.1fr 1.5fr 1.2fr 1.4fr 1.9fr .8fr";
type Query = { days?: string; who?: string; action?: string };

function href(q: Query, change: Partial<Query>): string {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries({ ...q, ...change })) if (v) params.set(k, v);
  const s = params.toString();
  return s ? `/audit?${s}` : "/audit";
}

export default async function AuditPage({ searchParams }: { searchParams: Promise<Query> }) {
  const admin = await requireAdmin("/audit");
  const q = await searchParams;
  const at = now();
  const days = (AUDIT.dayChoices as readonly string[]).includes(q.days ?? "") ? Number(q.days) : 30;
  const mine = q.who === "you";
  const action = q.action && (AUDIT.actions as readonly string[]).includes(q.action) ? q.action : null;
  const rows = await data().audit({ days, admin: mine ? admin.userId : null, action });
  return (
    <Frame current="Audit">
      <Title eyebrow={ENVIRONMENT[environment()]} title={AUDIT.title} lead={AUDIT.lead}>
        <Pill
          label={AUDIT.who}
          options={[
            { label: AUDIT.everyone, href: href(q, { who: "" }), current: !mine },
            { label: AUDIT.you, href: href(q, { who: "you" }), current: mine },
          ]}
        />
        <Pill
          label={AUDIT.action}
          options={[
            { label: AUDIT.all, href: href(q, { action: "" }), current: !action },
            ...AUDIT.actions.map((a) => ({ label: a, href: href(q, { action: a }), current: a === action })),
          ]}
        />
        <Pill
          label={AUDIT.days}
          options={AUDIT.dayChoices.map((d) => ({
            label: d,
            href: href(q, { days: d === "30" ? "" : d }),
            current: Number(d) === days,
          }))}
        />
      </Title>
      <Section title={AUDIT.list}>
        <Table
          cols={COLS}
          head={[
            { label: AUDIT.head.when },
            { label: AUDIT.head.who },
            { label: AUDIT.head.action },
            { label: AUDIT.head.centre },
            { label: AUDIT.head.detail },
            { label: AUDIT.head.from },
          ]}
        >
          {rows.map((r) => (
            <Row key={r.id} cols={COLS}>
              <Cell label={AUDIT.head.when}>{when(r.created_at, at, true)}</Cell>
              <Cell label={AUDIT.head.who} kind="dim">
                {r.admin_user_id === admin.userId ? AUDIT.you : (r.admin_email ?? NONE)}
              </Cell>
              <Cell label={AUDIT.head.action} kind="strong">
                {r.action}
              </Cell>
              <Cell label={AUDIT.head.centre} kind="dim">
                {r.centre ?? NONE}
              </Cell>
              <Cell label={AUDIT.head.detail} kind="dim">
                {auditDetail(r)}
              </Cell>
              <Cell label={AUDIT.head.from} kind="dim">
                {maskIp(r.ip)}
              </Cell>
            </Row>
          ))}
        </Table>
      </Section>
    </Frame>
  );
}
