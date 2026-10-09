import type { ReactNode } from "react";
import { Icon, type IconName } from "./Icon";
import { SiteFooter } from "./SiteFooter";
import { type Current, SiteHeader } from "./SiteHeader";

/** Every page: the header (with its own page marked), the content, the footer. */
export function Page({ current, children }: { current: Current; children: ReactNode }) {
  return (
    <>
      <SiteHeader current={current} />
      <main>{children}</main>
      <SiteFooter />
    </>
  );
}

export function PageTitle({ eyebrow, title, line }: { eyebrow: string; title: string; line: string }) {
  return (
    <div className="wrap">
      <div className="title">
        <div className="eyebrow">{eyebrow}</div>
        <h1 className="t1">{title}</h1>
        <p className="lead2">{line}</p>
      </div>
    </div>
  );
}

export function Section({ children, tight = false }: { children: ReactNode; tight?: boolean }) {
  return (
    <section className="wrap">
      <div className={tight ? "sec tight" : "sec"}>{children}</div>
    </section>
  );
}

export function Prose({ children }: { children: ReactNode }) {
  return <div className="prose">{children}</div>;
}

export function ListCard({ children }: { children: ReactNode }) {
  return <div className="card">{children}</div>;
}

export function FeatureRow({ icon, title, line }: { icon: IconName; title: string; line: string }) {
  return (
    <div className="row">
      <span className="tile">
        <Icon name={icon} size={22} width={1.9} />
      </span>
      <div className="plain">
        <div className="rowTitle">{title}</div>
        <div className="rowLine">{line}</div>
      </div>
    </div>
  );
}

export function QuestionRow({ question, answer }: { question: string; answer: string }) {
  return (
    <div className="row question">
      <div className="rowTitle">{question}</div>
      <div className="rowLine">{answer}</div>
    </div>
  );
}

export function PlainRow({ title, line }: { title: string; line: string }) {
  return (
    <div className="plain">
      <div className="rowTitle">{title}</div>
      <div className="rowLine">{line}</div>
    </div>
  );
}

export function PrimaryLink({ href, icon, children }: { href: string; icon?: IconName; children: ReactNode }) {
  return (
    <a href={href} className="btn btnPrimary">
      {icon ? <Icon name={icon} width={2} /> : null}
      {children}
    </a>
  );
}

export function SecondaryLink({ href, icon, children }: { href: string; icon?: IconName; children: ReactNode }) {
  return (
    <a href={href} className="btn btnSecondary">
      {icon ? <Icon name={icon} width={2} /> : null}
      {children}
    </a>
  );
}

export function TextLink({ href, children }: { href: string; children: ReactNode }) {
  return (
    <a href={href} className="textLink">
      {children}
    </a>
  );
}
