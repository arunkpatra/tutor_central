import type { Observe, RequestRow } from "./observe.js";

/** An in-memory Observe for tests: keeps the rows, answers `recent` for the rate limit, or fails every call. */
export function fakeObserve(options: { failing?: boolean } = {}): Observe & { rows: RequestRow[]; recent: number } {
  const fake = {
    rows: [] as RequestRow[],
    recent: 0,
    async recordRequest(row: RequestRow) {
      if (options.failing) throw new Error("observe unreachable");
      fake.rows.push(row);
    },
    async recentCount() {
      if (options.failing) throw new Error("observe unreachable");
      return fake.recent;
    },
  };
  return fake;
}
