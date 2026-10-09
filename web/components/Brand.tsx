import { Icon } from "./Icon";

/** The book on the icon's ground and the wordmark: 28 px in the header, 24 px in the footer (the boards' sizes). */
export function Brand({ small = false }: { small?: boolean }) {
  const mark = small ? { size: 24, radius: 6, icon: 13 } : { size: 28, radius: 8, icon: 16 };
  return (
    <a href="/" className="brand">
      <span
        className="brandMark"
        aria-hidden="true"
        style={{ width: mark.size, height: mark.size, borderRadius: mark.radius }}
      >
        <Icon name="book" size={mark.icon} width={2} />
      </span>
      Tutor Central
    </a>
  );
}
