import { Mark } from "./Mark";

/** The brand kit's mark on its tile and the wordmark: 28 px with the mark at 16 in the header, 24 px with 14 in the
 *  footer (P23-Web). The tile follows the scheme through `--logoTile` and `--logoMark` (D122). */
export function Brand({ small = false }: { small?: boolean }) {
  return (
    <a href="/" className="brand">
      <span className={small ? "brandMark brandMarkSmall" : "brandMark"} aria-hidden="true">
        <Mark size={small ? 14 : 16} />
      </span>
      Tutor Central
    </a>
  );
}
