/** Numbers and times as the boards write them: rupees from paise, India's clock (IST), counts with commas. */
const IST = "Asia/Kolkata";
const DAY_MS = 86_400_000;

/** ₹0.07, ₹2.84 under ₹10; ₹182, ₹1,240 above; nothing is ₹0. */
export function rupees(paise: number): string {
  if (paise === 0) return "₹0";
  const r = paise / 100;
  if (Math.abs(r) < 10) return `₹${r.toFixed(2)}`;
  return `₹${Math.round(r).toLocaleString("en-IN")}`;
}

/** Counts as the boards write them: 1,842 and 110,004. */
/** A cost per student: whole rupees, or the paise when it is under ₹1 (₹0.27, not ₹0). */
export function perStudent(paise: number): string {
  if (paise === 0) return "₹0";
  return paise < 100 ? rupees(paise) : `₹${Math.round(paise / 100)}`;
}

export function count(n: number): string {
  return n.toLocaleString("en-US");
}

/** The calendar day in India, as YYYY-MM-DD. */
export function istDay(at: Date): string {
  return at.toLocaleDateString("en-CA", { timeZone: IST });
}

function clock(at: Date, seconds = false): string {
  return at.toLocaleTimeString("en-GB", {
    timeZone: IST,
    hour: "2-digit",
    minute: "2-digit",
    ...(seconds ? { second: "2-digit" } : {}),
    hour12: false,
  });
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** "12 Oct", "23 Sep" in India: three letters always (en-GB's short September is "Sept"). */
export function dayMonth(at: Date | string): string {
  const d = typeof at === "string" ? new Date(at.length === 10 ? `${at}T12:00:00+05:30` : at) : at;
  const [, month, day] = istDay(d).split("-").map(Number) as [number, number, number];
  return `${day} ${MONTHS[month - 1]}`;
}

function daysBetween(at: Date, now: Date): number {
  return Math.round((Date.parse(istDay(now)) - Date.parse(istDay(at))) / DAY_MS);
}

/** "Today 06:48", "Yesterday 19:20", "11 Oct 18:10" (with seconds when asked: "Today 10:42:16"). */
export function when(iso: string, now: Date, withSeconds = false): string {
  const at = new Date(iso);
  const days = daysBetween(at, now);
  const time = clock(at, withSeconds);
  if (days === 0) return `Today ${time}`;
  if (days === 1) return `Yesterday ${time}`;
  return `${dayMonth(at)} ${time}`;
}

/** The time alone ("05:31", or "05:33:10"). */
export function time(iso: string, withSeconds = false): string {
  return clock(new Date(iso), withSeconds);
}

/** "Today 06:48", "Yesterday 19:20", then "3 days ago": how long since a centre was last opened. */
export function ago(iso: string, now: Date): string {
  const days = daysBetween(new Date(iso), now);
  if (days <= 1) return when(iso, now);
  return `${days} days ago`;
}

/** Whole days since a moment (for "idle past 14 days"). */
export function daysSince(iso: string, now: Date): number {
  return daysBetween(new Date(iso), now);
}

/** "56 s", "0.4 s", "3 min". */
export function seconds(s: number): string {
  if (s >= 120) return `${Math.round(s / 60)} min`;
  return s < 10 && !Number.isInteger(s) ? `${s.toFixed(1)} s` : `${Math.round(s)} s`;
}

/** Milliseconds as the calls list writes latency: "2.2 s", "12.4 s", "41 s". */
export function latency(ms: number): string {
  const s = ms / 1000;
  return s < 20 ? `${s.toFixed(1)} s` : `${Math.round(s)} s`;
}

/** The first day of the month an ISO day (or a "YYYY-MM" query) is in, as YYYY-MM-01. */
export function monthOf(value: string | undefined, now: Date): string {
  if (value && /^\d{4}-(0[1-9]|1[0-2])$/.test(value)) return `${value}-01`;
  return `${istDay(now).slice(0, 7)}-01`;
}

/** "October" for a month's first day. */
export function monthName(first: string): string {
  return new Date(`${first}T12:00:00+05:30`).toLocaleDateString("en-GB", { timeZone: IST, month: "long" });
}

/** An id cut as the boards show it: "7a1e…c0d4". */
export function shortId(id: string): string {
  const plain = id.replace(/-/g, "");
  return plain.length <= 10 ? id : `${plain.slice(0, 4)}…${plain.slice(-4)}`;
}

/** An address with its last two parts hidden: "49.207.x.x". */
export function maskIp(ip: string | null): string {
  if (!ip) return "—";
  const v4 = ip.split(".");
  if (v4.length === 4) return `${v4[0]}.${v4[1]}.x.x`;
  const v6 = ip.split(":");
  return v6.length > 2 ? `${v6.slice(0, 2).join(":")}:…` : ip;
}

/** Today's time alone ("05:31", or "10:41:08"); else "Yesterday 19:20" or "11 Oct 16:02". */
export function short(iso: string, now: Date, withSeconds = false): string {
  const today = when(iso, now, withSeconds);
  return today.startsWith("Today ") ? today.slice(6) : when(iso, now);
}
