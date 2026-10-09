/** A legal page's parts: a sub-heading, or a paragraph that may end in one link. */
export type Part =
  | { kind: "h3"; text: string }
  | { kind: "p"; text: string; link?: { label: string; href: string; after: string } };

export type LegalPage = {
  eyebrow: string;
  title: string;
  line: string;
  updated: string;
  sections: { heading: string; parts: Part[] }[];
};
