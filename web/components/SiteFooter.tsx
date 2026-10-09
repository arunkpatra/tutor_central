import { EMAIL, MAKER, PROMISE, ROUTES } from "@/content/site";
import { Brand } from "./Brand";

export function SiteFooter() {
  return (
    <footer className="wrap">
      <div className="ftr">
        <div className="ftrBrand">
          <Brand small />
          <p className="small">{PROMISE}</p>
          {/* The year the export was built. */}
          <p className="caption">
            © {new Date().getFullYear()} {MAKER}
          </p>
        </div>
        <nav className="nav ftrNav" aria-label="Footer">
          <a href={ROUTES.support}>Support</a>
          <a href={ROUTES.privacy}>Privacy</a>
          <a href={ROUTES.terms}>Terms</a>
          <a href={`mailto:${EMAIL}`} className="navEmail">
            {EMAIL}
          </a>
        </nav>
      </div>
    </footer>
  );
}
