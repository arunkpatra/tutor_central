import type { CSSProperties, ReactNode } from "react";
import { NOTHING_YET } from "@/content/words";
import { ChevronIcon } from "./Icon";

/** The page's head: the eyebrow (where it runs), the title, the lead, and the filters on the right. */
export function Title({
  eyebrow,
  title,
  lead,
  badge,
  children,
}: {
  eyebrow: string;
  title: string;
  lead?: ReactNode;
  badge?: ReactNode;
  children?: ReactNode;
}) {
  return (
    <div className="wrap">
      <div className="pageHead">
        <div className="pageTitle">
          <div className="eyebrow">{eyebrow}</div>
          <h1 className="t1">{title}</h1>
          {lead ? <p className="lead">{lead}</p> : null}
          {badge ? <div>{badge}</div> : null}
        </div>
        {children ? <div className="filters">{children}</div> : null}
      </div>
    </div>
  );
}

/** A section: an h2 with its small lead and an optional action, then the content. */
export function Section({
  title,
  lead,
  action,
  children,
}: {
  title?: string;
  lead?: ReactNode;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="wrap">
      <div className="sec">
        {title ? (
          <div className="secHead">
            <div className="secTitle">
              <h2 className="h2">{title}</h2>
              {lead ? <p className="lead small">{lead}</p> : null}
            </div>
            {action}
          </div>
        ) : null}
        {children}
      </div>
    </section>
  );
}

export type Tone = "ok" | "due" | "overdue" | "accent" | "neutral";

export function Tiles({ children }: { children: ReactNode }) {
  return <div className="tiles">{children}</div>;
}

export function Tile({ value, label, tone }: { value: ReactNode; label: string; tone?: "due" | "overdue" }) {
  return (
    <div className="tile">
      <div className={`tileValue${tone ? ` ${tone}` : ""}`}>{value}</div>
      <div className="tileLabel">{label}</div>
    </div>
  );
}

export function Chip({ tone = "neutral", children }: { tone?: Tone; children: ReactNode }) {
  return <span className={`chip${tone === "neutral" ? "" : ` ${tone}`}`}>{children}</span>;
}

/** The list card: a header row and grid rows; under 760 px each row is two labelled columns. */
export type Column = { label: string; right?: boolean };
export function Table({
  cols,
  head,
  children,
  empty,
  bare,
}: {
  cols: string;
  head: Column[];
  children: ReactNode[];
  empty?: string;
  /** A table of facts: its header row is drawn empty, as the board's (the labels stay for phone width). */
  bare?: boolean;
}) {
  const style = { "--cols": cols } as CSSProperties;
  return (
    <div className="card">
      <div className="grid head" style={style}>
        {head.map((c) => (
          <div key={c.label} className={c.right ? "cell r" : "cell"}>
            {bare ? null : c.label}
          </div>
        ))}
      </div>
      {children.length > 0 ? children : <div className="empty">{empty ?? NOTHING_YET}</div>}
    </div>
  );
}

export function Row({ cols, children }: { cols: string; children: ReactNode }) {
  return (
    <div className="grid" style={{ "--cols": cols } as CSSProperties}>
      {children}
    </div>
  );
}

export type CellKind = "main" | "strong" | "r" | "dim" | "wide" | "acts" | "";
export function Cell({
  label,
  kind = "",
  sub,
  children,
}: {
  label: string;
  kind?: CellKind;
  sub?: ReactNode;
  children: ReactNode;
}) {
  if (kind === "acts") return <div className="acts">{children}</div>;
  return (
    <div className={kind ? `cell ${kind}` : "cell"}>
      <span className="k">{label}</span>
      {children}
      {sub ? <span className="sub">{sub}</span> : null}
    </div>
  );
}

/** A filter as a select pill (P19 boards): the menu is a list of links that change the page's query, no script. */
export type Option = { label: string; href: string; current: boolean };
export function Pill({ label, options }: { label: string; options: Option[] }) {
  const current = options.find((o) => o.current) ?? options[0];
  return (
    <details className="pillMenu">
      <summary className="pill">
        <span className="pillLabel">{label}</span>
        <span className="pillValue">{current?.label}</span>
        <ChevronIcon />
      </summary>
      <div className="menu">
        {options.map((o) => (
          <a key={o.href} href={o.href} aria-current={o.current ? "true" : undefined}>
            {o.label}
          </a>
        ))}
      </div>
    </details>
  );
}

/** The allowance bar: a share of ₹499 (`due` past 80%). */
export function Meter({ share }: { share: number }) {
  const pct = Math.max(0, Math.min(100, Math.round(share * 100)));
  return (
    <span className="meter">
      <span className={pct > 80 ? "meterFill due" : "meterFill"} style={{ width: `${pct}%` }} />
    </span>
  );
}

export type ButtonKind = "primary" | "secondary" | "destructive" | "quiet";
export function Button({ kind, big, children }: { kind: ButtonKind; big?: boolean; children: ReactNode }) {
  return (
    <button type="submit" className={`btn ${kind}${big ? " big" : ""}`}>
      {children}
    </button>
  );
}

export function LinkButton({
  kind,
  big,
  href,
  children,
}: {
  kind: ButtonKind;
  big?: boolean;
  href: string;
  children: ReactNode;
}) {
  return (
    <a href={href} className={`btn ${kind}${big ? " big" : ""}`}>
      {children}
    </a>
  );
}

export function Field({
  label,
  name,
  type = "text",
  placeholder,
  code,
  autoComplete,
  required,
  defaultValue,
  maxLength,
}: {
  label: string;
  name: string;
  type?: string;
  placeholder?: string;
  code?: boolean;
  autoComplete?: string;
  required?: boolean;
  defaultValue?: string;
  maxLength?: number;
}) {
  return (
    <label className="field">
      <span className="fieldLabel">{label}</span>
      <input
        className={code ? "input code" : "input"}
        name={name}
        type={type}
        placeholder={placeholder}
        autoComplete={autoComplete}
        required={required}
        defaultValue={defaultValue}
        maxLength={maxLength}
        inputMode={code ? "numeric" : undefined}
        pattern={code ? "[0-9]{6}" : undefined}
      />
    </label>
  );
}

export function Code({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div>
      <div className="h3 codeTitle">{title}</div>
      <pre className="code">{children}</pre>
    </div>
  );
}

/** A dialog over the dimmed page (P19-Centre-OpenAsk): the question, a lead, its form. */
export function Dialog({ title, lead, children }: { title: string; lead: string; children: ReactNode }) {
  return (
    <div className="scrim">
      <div className="dialog" role="dialog" aria-modal="true" aria-labelledby="dialog-title">
        <h2 className="h2" id="dialog-title">
          {title}
        </h2>
        <p className="lead small">{lead}</p>
        {children}
      </div>
    </div>
  );
}
