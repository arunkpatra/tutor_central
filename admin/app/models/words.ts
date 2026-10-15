import { MODEL } from "@/content/models";
import { dayMonth, when } from "@/lib/format";

/** "Today 09:40", "Yesterday 18:02", else "13 Oct" (P22-Models' Changed). */
export function changedWhen(iso: string, at: Date): string {
  const w = when(iso, at);
  return w.startsWith("Today ") || w.startsWith("Yesterday ") ? w : dayMonth(iso);
}

/** "you" for the viewer's own row, "seed 0052" for a migration's, else the admin's email. */
export function changedBy(by: string, note: string | null, me: string | null): string {
  if (by === "seed") return MODEL.seed(note);
  return me && by === me ? MODEL.you : by;
}
