import type { Metadata } from "next";
import { Page, PrimaryLink, SecondaryLink } from "@/components/parts";
import { NOT_FOUND } from "@/content/notFound";
import { ROUTES } from "@/content/site";

export const metadata: Metadata = { title: "Not found" };

/** Vercel serves this as 404.html for any path the export does not have: a page with the frame, never a redirect. */
export default function NotFound() {
  return (
    <Page current="">
      <section className="wrap">
        <div className="sec notFound">
          <div className="notFoundBody">
            <h1 className="t1">{NOT_FOUND.title}</h1>
            <p className="lead2">{NOT_FOUND.line}</p>
            <div className="actions notFoundActions">
              <PrimaryLink href={ROUTES.home}>{NOT_FOUND.home}</PrimaryLink>
              <SecondaryLink href={ROUTES.support}>{NOT_FOUND.support}</SecondaryLink>
            </div>
          </div>
        </div>
      </section>
    </Page>
  );
}
