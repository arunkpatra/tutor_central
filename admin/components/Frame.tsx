import type { ReactNode } from "react";
import { PAGES, type PageLabel, SITE } from "@/content/site";
import { FRAME } from "@/content/words";
import { commit, environment } from "@/lib/env";
import { BookIcon } from "./Icon";
import { PageLink } from "./PageLink";

function Brand() {
  return (
    <PageLink href="/centres" className="brand">
      <span className="brandTile" aria-hidden="true">
        <BookIcon />
      </span>
      <span className="brandName">{FRAME.brand}</span>
      <span className="brandMark">{FRAME.mark}</span>
    </PageLink>
  );
}

/** A signed-in page: the header with the nav and Sign out, the page, the footer (P19 boards, "the frame"). */
export function Frame({ current, children }: { current: PageLabel | ""; children: ReactNode }) {
  return (
    <div className="tc">
      <header className="wrap">
        <div className="hdr ruled">
          <Brand />
          <nav className="nav" aria-label={FRAME.navLabel}>
            {PAGES.map((p) => (
              <PageLink key={p.href} href={p.href} aria-current={p.label === current ? "page" : undefined}>
                {p.label}
              </PageLink>
            ))}
          </nav>
          <form action="/sign-out" method="post" className="signoutForm">
            <button type="submit" className="signout">
              {FRAME.signOut}
            </button>
          </form>
        </div>
      </header>
      <main>{children}</main>
      <footer className="wrap">
        <div className="ftr">
          <span>{FRAME.footer(environment(), commit().slice(0, 7))}</span>
          <span>{FRAME.audited}</span>
        </div>
      </footer>
    </div>
  );
}

/** The sign-in pages: the brand alone, the form centred, the staff footer. */
export function AuthFrame({ children }: { children: ReactNode }) {
  return (
    <div className="tc">
      <header className="wrap">
        <div className="hdr">
          <Brand />
        </div>
      </header>
      <main className="centered">
        <div className="auth">{children}</div>
      </main>
      <footer className="wrap">
        <div className="ftr flush">
          <span>{FRAME.authFooter}</span>
          <span>{SITE}</span>
        </div>
      </footer>
    </div>
  );
}
