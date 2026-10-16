/** The deploys' smokes share these (tools/web-smoke.ts, tools/admin-smoke.ts). */

/** A file that must be an image: its status, or the type it came as. */
export function notAnImage(path: string, r: Response): string | undefined {
  const type = r.headers.get("content-type") ?? "no type";
  if (r.status !== 200) return `${path} answered ${r.status}`;
  if (!type.startsWith("image/")) return `${path} answered 200 as ${type.split(";")[0]}, not an image`;
  return undefined;
}

/** The brand kit's icon is known by its cap's path; the book it replaced by its spine (D120, D122). */
const KIT_ICON = "M128 0L256 64L128 128L0 64Z";
const BOOK = "M20.001 19A2";

/** Whether a served /icon.svg is anything but the brand kit's icon. */
export async function notTheKitsIcon(r: Response): Promise<boolean> {
  const svg = r.status === 200 ? await r.text() : "";
  return !svg.includes(KIT_ICON) || svg.includes(BOOK);
}
