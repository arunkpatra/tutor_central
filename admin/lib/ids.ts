/** A centre's, job's or call's id from a URL: a UUID, or the preview's names. Anything else is not found. */
export function idOf(value: string, previewing: boolean): string | null {
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) return value.toLowerCase();
  return previewing && /^[a-z0-9-]{1,40}$/.test(value) ? value : null;
}
