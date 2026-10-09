import type { Metadata } from "next";
import { ListCard, Page, PageTitle, PrimaryLink, Prose, QuestionRow, Section, TextLink } from "@/components/parts";
import { EMAIL, ROUTES } from "@/content/site";
import { SUPPORT } from "@/content/support";

export const metadata: Metadata = { title: "Support" };

/** /support (P8-Support): Help's content on the web. */
export default function Support() {
  return (
    <Page current="Support">
      <PageTitle eyebrow={SUPPORT.eyebrow} title={SUPPORT.title} line={SUPPORT.line} />
      <Section space="cta">
        <div className="actions">
          <PrimaryLink href={`mailto:${EMAIL}`} icon="mail">
            Email {EMAIL}
          </PrimaryLink>
          <p className="small">{SUPPORT.emailLine}</p>
        </div>
      </Section>
      <Section space="flush">
        <h2 className="h2">Common questions</h2>
        <ListCard>
          {SUPPORT.questions.map((q) => (
            <QuestionRow key={q.question} question={q.question} answer={q.answer} />
          ))}
        </ListCard>
      </Section>
      <Section space="flush">
        <h2 className="h2">{SUPPORT.alsoHeading}</h2>
        <Prose>
          <p>
            <TextLink href={ROUTES.privacy}>{SUPPORT.alsoPrivacy}</TextLink>
            {SUPPORT.alsoAnd}
            <TextLink href={ROUTES.terms}>{SUPPORT.alsoTerms}</TextLink>
            {SUPPORT.alsoAfter}
          </p>
        </Prose>
      </Section>
    </Page>
  );
}
