import { commit } from "@/lib/env";

export const dynamic = "force-dynamic";

/** The deploy's smoke reads the commit served; no session, nothing else. */
export function GET() {
  return Response.json({ ok: true, commit: commit() });
}
