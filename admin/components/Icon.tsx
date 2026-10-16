/** The portal's icons, drawn as the boards draw them (Lucide's paths; the brand's mark the kit's). */
/** The brand kit's mark, its small-size master for the 28 px tile (`docs/design/brand/tc-mark-ink-small.svg`, a held copy of
 *  the kit's at v1.2.0): copied, never redrawn (D120, D122). It takes its colour from the tile. */
const MARK =
  "M107.2 117.6L0 64L128 0L256 64L148.8 117.6L148.8 177.27L107.2 177.27ZM223.92 212.76C222.18 214.73 220.38 216.64 218.51 218.51C194.51 242.51 161.95 256 128 256C94.05 256 61.49 242.51 37.49 218.51C13.49 194.51 0 161.95 0 128C0 119.24 0.9 110.57 2.64 102.12L41.83 121.71C41.68 123.8 41.6 125.9 41.6 128C41.6 150.91 50.7 172.89 66.91 189.09C83.11 205.3 105.09 214.4 128 214.4C148.92 214.4 169.05 206.81 184.73 193.17Z";

export function MarkIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 256 256" aria-hidden="true">
      <path d={MARK} fill="currentColor" />
    </svg>
  );
}

export function ChevronIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="var(--text3)"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M6 9l6 6 6-6" />
    </svg>
  );
}

/** A button's working state (P19-Pending-SignIn): a quarter arc over a faint ring, turning. */
export function SpinnerIcon() {
  return (
    <svg
      className="spinner"
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="3"
      strokeLinecap="round"
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="9" opacity=".25" />
      <path d="M21 12a9 9 0 0 0-9-9" />
    </svg>
  );
}
