import type { ReactNode } from "react";
import type { LegalPage, Part } from "@/content/legal";
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

/** A section of a page. `tight`: no top padding and 40 below (the legal pages' sections); `flush`: no top padding (a
 *  section that follows a title); `cta`: no top padding and 48 below (Support's email). */
export function Section({
  children,
  space = "normal",
}: {
  children: ReactNode;
  space?: "normal" | "tight" | "flush" | "cta";
}) {
  return (
    <section className="wrap">
      <div className={space === "normal" ? "sec" : `sec ${space}`}>{children}</div>
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
      <div className="plain featureText">
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

function PartView({ part }: { part: Part }) {
  if (part.kind === "h3") return <h3 className="h3">{part.text}</h3>;
  return (
    <p>
      {part.text}
      {part.link ? (
        <>
          <TextLink href={part.link.href}>{part.link.label}</TextLink>
          {part.link.after}
        </>
      ) : null}
    </p>
  );
}

/** /privacy and /terms: the title, the date, then each section's heading and parts at the column's width, 28 apart. */
export function LegalDocument({ page, current }: { page: LegalPage; current: Current }) {
  return (
    <Page current={current}>
      <PageTitle eyebrow={page.eyebrow} title={page.title} line={page.line} />
      <Section space="tight">
        <p className="small updated">{page.updated}</p>
      </Section>
      {page.sections.map((section) => (
        <Section key={section.heading} space="tight">
          <h2 className="h2">{section.heading}</h2>
          {section.parts.map((part) => (
            <PartView key={part.text} part={part} />
          ))}
        </Section>
      ))}
    </Page>
  );
}
