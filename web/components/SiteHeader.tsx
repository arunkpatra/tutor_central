import { ROUTES } from "@/content/site";
import { Brand } from "./Brand";

export type Current = "Support" | "Privacy" | "Terms" | "";
const LINKS: [Current, string][] = [
  ["Support", ROUTES.support],
  ["Privacy", ROUTES.privacy],
  ["Terms", ROUTES.terms],
];

export function SiteHeader({ current }: { current: Current }) {
  return (
    <header className="wrap">
      <div className="hdr">
        <Brand />
        <nav className="nav" aria-label="Pages">
          {LINKS.map(([label, href]) => (
            <a key={href} href={href} aria-current={label === current ? "page" : undefined}>
              {label}
            </a>
          ))}
        </nav>
      </div>
    </header>
  );
}
