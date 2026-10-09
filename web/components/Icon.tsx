const PATHS = {
  book: '<path d="M12 5v16"/><path d="M20.001 19A2 2 0 0022 17V5a2 2 0 00-1.999-2L16 3.002A5 5 0 0012 5a5 5 0 00-4-2H4a2 2 0 00-2 2v12a2 2 0 001.999 2H8a5 5 0 014 2 5 5 0 014-2z"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M3.5 7l8.5 6 8.5-6"/>',
  apple:
    '<path d="M15.5 3c-.2 1.4-1 2.5-2.2 3.1M12.1 7.5c1.2-.1 2.5-.8 3.9-.7 1.4.1 2.5.7 3.2 1.7-2.8 1.8-2.4 5.9.6 7.1-.6 1.6-1.4 3.1-2.6 4.3-1 1-2.3.8-3.3.3-1-.5-2-.5-3 0-1.1.6-2.4.7-3.4-.4C5 17.3 3.6 13 5.3 9.7c.9-1.7 2.5-2.4 4.1-2.3 1 .1 1.8.6 2.7.1z" fill="currentColor" stroke="none"/>',
  students:
    '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><circle cx="17" cy="9" r="2.8"/><path d="M16 15.5a5 5 0 0 1 5.5 4.5"/>',
  checkCircle: '<circle cx="12" cy="12" r="9"/><path d="M8.5 12.5l2.5 2.5 4.5-5"/>',
  rupee: '<path d="M6 4h12M6 9h12M9 4c3.5 0 5 2 5 5s-1.5 5-5 5H6l8 6"/>',
  calendar: '<rect x="4" y="6" width="16" height="14" rx="3"/><path d="M8 6V4M16 6V4M4 11h16"/>',
  paper: '<path d="M6 3h9l4 4v14H6z"/><path d="M15 3v4h4M9 12h6M9 16h6"/>',
  sparkles:
    '<path d="M12 3l1.8 4.7L18.5 9.5l-4.7 1.8L12 16l-1.8-4.7L5.5 9.5l4.7-1.8z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
  scan: '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M7 12h10"/>',
} as const;

export type IconName = keyof typeof PATHS;

/** The boards' stroke icons, inline. Decorative unless given a `label`. */
export function Icon({
  name,
  size = 20,
  width = 1.8,
  label,
}: {
  name: IconName;
  size?: number;
  width?: number;
  label?: string;
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={width}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden={label ? undefined : true}
      role={label ? "img" : undefined}
      aria-label={label}
      // biome-ignore lint/security/noDangerouslySetInnerHtml: the paths are this file's own constants, not user content.
      dangerouslySetInnerHTML={{ __html: PATHS[name] }}
    />
  );
}
