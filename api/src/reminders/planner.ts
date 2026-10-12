import { addDays, istDay, weekday } from "../plan/dates.js";
import type { NotificationRow } from "../push/db.js";

/** The tutor's reminders (Domain's ReminderPlanner, P7-Reminders): before each batch's meeting, before each event, and
 *  once for the month's fees still due; their words as the phone wrote them. Pure. */
export const REMINDER_DAYS = 14;
export const REMINDER_LIMIT = 60;

export type ReminderClass = { id: string; name: string; days: number[]; start: string | null; end: string | null };
export type ReminderEvent = { id: string; title: string; date: string; start?: string | null; end?: string | null; note?: string | null };
export type ReminderInput = {
  settings: { classOn: boolean; classMinutes: number; eventsOn: boolean; eventLead: string; feesOn: boolean; feesDay: number };
  classes: ReminderClass[];
  memberCounts: Record<string, number>;
  events: ReminderEvent[];
  /** This month's fees still due: how many and the rupees; none when nothing is due. */
  dueFees: { count: number; total: number } | null;
};
export type Reminder = { id: string; kind: "class" | "event" | "fees"; title: string; body: string; at: string; link: string; subject: string };
/** A reminder with its outbox key: a batch's by its day and start, an event's by its time, the fees by the month, so a
 *  plan written again finds its rows and a moved batch's old row is cancelled. */
type Keyed = { reminder: Reminder; key: string };

const SHORT_DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const SHORT_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

/** "Fri 9 Oct" (Day.shortWeekdayText). */
export function shortWeekdayText(day: string): string {
  const [, m, d] = day.split("-").map(Number) as [number, number, number];
  return `${SHORT_DAYS[weekday(day) - 1]} ${d} ${SHORT_MONTHS[m - 1]}`;
}

/** "17:00" from "17:00" or "17:00:00". */
export const hhmm = (time: string) => time.slice(0, 5);

/** The instant of a day's time in India, as "2026-11-02T16:00:00+05:30". */
export function istAt(day: string, time: string): string {
  return `${day}T${hhmm(time)}:00+05:30`;
}

/** An instant moved by minutes, written in India's offset. */
export function istPlus(instant: string, minutes: number): string {
  const ms = Date.parse(instant) + minutes * 60_000 + 5.5 * 3_600_000;
  return `${new Date(ms).toISOString().slice(0, 19)}+05:30`;
}

/** "₹4,000", Indian grouping (Money.formatted). */
export const rupees = (amount: number) => new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 }).format(amount);

const minutesText = (minutes: number) => (minutes === 60 ? "1 hour" : `${minutes} minutes`);
const leadMinutes: Record<string, number | undefined> = { min15: 15, min30: 30, hour1: 60, day_before: undefined };

function meeting(room: ReminderClass, day: string, input: ReminderInput): Keyed | undefined {
  if (!room.days.includes(weekday(day)) || !room.start) return undefined;
  const lead = input.settings.classMinutes;
  const students = input.memberCounts[room.id] ?? 0;
  const start = hhmm(room.start);
  const id = room.id.toLowerCase();
  const reminder: Reminder = {
    id: `class-${id}-${day}`,
    kind: "class",
    title: `${room.name} at ${start}`,
    body: `In ${minutesText(lead)} · ${students} ${students === 1 ? "student" : "students"}. Open for today's plan.`,
    at: istPlus(istAt(day, start), -lead),
    link: "tutorcentral://today",
    subject: room.name,
  };
  return { reminder, key: `class:${id}:${day}T${start}` };
}

function event(e: ReminderEvent, lead: string): Keyed {
  const start = e.start ? hhmm(e.start) : undefined;
  const end = e.end ? hhmm(e.end) : undefined;
  const when = start && end ? `${shortWeekdayText(e.date)}, ${start}–${end}` : start ? `${shortWeekdayText(e.date)}, ${start}` : shortWeekdayText(e.date);
  const note = e.note?.split("\n").find((line) => line !== "")?.trim();
  const joined = [when, note].filter((part): part is string => part !== undefined && part !== "").join(" · ");
  const body = joined.endsWith(".") ? joined : `${joined}.`;
  const minutes = leadMinutes[lead];
  let at: string;
  let title: string;
  if (minutes === undefined) {
    at = istAt(addDays(e.date, -1), "18:00");
    title = `${e.title} tomorrow`;
  } else if (start) {
    at = istPlus(istAt(e.date, start), -minutes);
    title = `${e.title} in ${minutesText(minutes)}`;
  } else {
    at = istAt(e.date, "09:00");
    title = `${e.title} today`;
  }
  const id = e.id.toLowerCase();
  return { reminder: { id: `event-${id}`, kind: "event", title, body, at, link: `tutorcentral://event/${id}`, subject: e.title }, key: `event:${id}:${at.slice(0, 16)}` };
}

function fees(due: { count: number; total: number }, feeDay: number, now: string): Keyed {
  const today = istDay(new Date(now));
  const [y, m] = today.split("-").map(Number) as [number, number];
  const nine = (year: number, month: number) => istAt(`${year}-${String(month).padStart(2, "0")}-${String(feeDay).padStart(2, "0")}`, "09:00");
  const [year, month] = Date.parse(nine(y, m)) > Date.parse(now) ? [y, m] : m === 12 ? [y + 1, 1] : [y, m + 1];
  const iso = `${year}-${String(month).padStart(2, "0")}`;
  const reminder: Reminder = {
    id: `fees-${iso}`,
    kind: "fees",
    title: `${due.count} ${due.count === 1 ? "fee" : "fees"} still due for ${MONTHS[month - 1]}`,
    body: `${rupees(due.total)} to collect. Tap to remind parents.`,
    at: nine(year, month),
    link: `tutorcentral://fees?month=${iso}`,
    subject: "Fees still due",
  };
  return { reminder, key: `fees:${iso}` };
}

/** Every reminder from `now` over the next 14 days with its key, soonest first (ties by id), at most 60. */
function planned(input: ReminderInput, now: string): Keyed[] {
  const today = istDay(new Date(now));
  const window = Array.from({ length: REMINDER_DAYS }, (_, i) => addDays(today, i));
  const plan: Keyed[] = [];
  if (input.settings.classOn) {
    for (const day of window) {
      for (const room of input.classes) {
        const r = meeting(room, day, input);
        if (r) plan.push(r);
      }
    }
  }
  if (input.settings.eventsOn) for (const e of input.events) if (window.includes(e.date)) plan.push(event(e, input.settings.eventLead));
  if (input.settings.feesOn && input.dueFees) plan.push(fees(input.dueFees, input.settings.feesDay, now));
  const at = Date.parse(now);
  return plan
    .filter(({ reminder: r }) => Date.parse(r.at) > at)
    .sort(({ reminder: a }, { reminder: b }) => Date.parse(a.at) - Date.parse(b.at) || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
    .slice(0, REMINDER_LIMIT);
}

/** Every reminder from `now` over the next 14 days, soonest first (ties by id), at most 60 (ReminderPlanner.plan). */
export function planReminders(input: ReminderInput, now: string): Reminder[] {
  return planned(input, now).map((k) => k.reminder);
}

/** The outbox's rows for the reminders due within the window (the hourly plan writes 26 hours ahead). */
export function notificationsFor(input: ReminderInput, now: string, windowHours = 26): NotificationRow[] {
  const until = Date.parse(now) + windowHours * 3_600_000;
  return planned(input, now)
    .filter(({ reminder: r }) => Date.parse(r.at) <= until)
    .map(({ reminder: r, key }) => ({ kind: r.kind, key, due_at: r.at, title: r.title, body: r.body, link: r.link }));
}
