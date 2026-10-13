/** The reason an admin gives to open a centre's record: trimmed, 1 to 200 characters (0047's admin_open_record). */
export function reasonOf(form: FormData): string | null {
  const reason = String(form.get("reason") ?? "").trim();
  return reason.length >= 1 && reason.length <= 200 ? reason : null;
}

/** The cookie that carries a fresh open's audit row to the record page (ten minutes, that page's path only). */
export function recordCookie(centre: string): string {
  return `tc-record-${centre}`;
}

/** Where the record page sends a request with no fresh open: back to the ask. Preview mode draws its fixture. */
export function recordAsk(centre: string, audit: string | undefined, previewing: boolean): string | null {
  if (previewing || audit) return null;
  return `/centres/${centre}?ask=1`;
}
