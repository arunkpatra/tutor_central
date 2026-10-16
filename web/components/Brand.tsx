import { Mark } from "./Mark";

/** The brand kit's mark on its tile and the wordmark: 28 px with the mark at 16 in the header, 24 px with 14 in the
 *  footer (P23-Web). The tile follows the scheme through `--logoTile` and `--logoMark` (D122). */
export function Brand({ small = false }: { small?: boolean }) {
  const mark = small ? { size: 24, radius: 6, icon: 14 } : { size: 28, radius: 8, icon: 16 };
  return (
    <a href="/" className="brand">
      <span
        className="brandMark"
        aria-hidden="true"
        style={{ width: mark.size, height: mark.size, borderRadius: mark.radius }}
      >
        <Mark size={mark.icon} />
      </span>
      Tutor Central
    </a>
  );
}
