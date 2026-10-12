/** Days as the plan reads them, "YYYY-MM-DD" civil dates in India's calendar (+05:30 all year, no DST), without a
 *  library: the weekday and the day after are the date's own, whatever the server's zone. */

const SHORT = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

function parts(day: string): [number, number, number] {
  const [y, m, d] = day.split("-").map(Number);
  return [y as number, m as number, d as number];
}

/** ISO weekday, 1 Monday to 7 Sunday. */
export function weekday(day: string): number {
  const [y, m, d] = parts(day);
  return ((new Date(Date.UTC(y, m - 1, d)).getUTCDay() + 6) % 7) + 1;
}

export function shortWeekday(day: string): string {
  return SHORT[weekday(day) - 1] as string;
}

export function addDays(day: string, days: number): string {
  const [y, m, d] = parts(day);
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/** The day an instant falls on in India. */
export function istDay(instant: Date): string {
  return new Date(instant.getTime() + 5.5 * 3_600_000).toISOString().slice(0, 10);
}
