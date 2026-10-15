import { createClient } from "@supabase/supabase-js";
import type { Figures, Reasons } from "./text.js";

/** What the weekly report reads, through 0067's and 0047's named functions as the platform (D83). */
export type ReportSource = {
  /** `admin_figures`: the last `weeks` weeks, the current one first. */
  figures(weeks: number): Promise<Figures[]>;
  reasons(monday: string): Promise<Reasons>;
  centres(): Promise<{ total: number; inUse: number }>;
  openAlerts(): Promise<number>;
};

export function makeReportSource(url: string, serviceKey: string): ReportSource {
  const db = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const rpc = async <T>(fn: string, args: Record<string, unknown> = {}): Promise<T> => {
    const { data, error } = await db.rpc(fn, args);
    if (error) throw new Error(`the weekly report could not read ${fn}: ${error.message}`);
    return data as T;
  };
  return {
    figures: (weeks) => rpc<Figures[]>("admin_figures", { p_weeks: weeks }),
    reasons: (monday) => rpc<Reasons>("admin_reasons_week", { p_monday: monday }),
    async centres() {
      const today = new Date().toLocaleDateString("en-CA", {
        timeZone: "Asia/Kolkata",
      });
      const c = await rpc<{
        tiles: { centres: number };
        rows: { in_use: boolean }[];
      }>("admin_centres", { p_month: `${today.slice(0, 8)}01` });
      return {
        total: Number(c.tiles.centres),
        inUse: c.rows.filter((r) => r.in_use).length,
      };
    },
    async openAlerts() {
      const a = await rpc<{ tiles: { open: number } }>("admin_alerts", {
        p_open_first: true,
      });
      return Number(a.tiles.open);
    },
  };
}

/** Tests: fixed answers; `figures(n)` answers the first n weeks given. */
export function fakeReportSource(given: {
  weeks: Figures[];
  reasons: Reasons;
  centres: { total: number; inUse: number };
  openAlerts: number;
}): ReportSource {
  return {
    figures: async (n) => given.weeks.slice(0, n),
    reasons: async () => given.reasons,
    centres: async () => given.centres,
    openAlerts: async () => given.openAlerts,
  };
}
