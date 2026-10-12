import type { StudentRecord } from "../export/record.js";
import { istDay } from "../plan/dates.js";
import { rupees, shortWeekdayText } from "../reminders/planner.js";
import { str, t } from "./typst.js";

/** The student's file for the parent (P18-Export-File, D92): A4, paper only; the head, a marigold rule, the line for the
 *  parent, then sections of label and value rows; "Page n of m" in the foot. Nothing the record does not hold. */

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const LANGUAGES: Record<string, string> = { en: "English", hinglish: "Hinglish", hi: "Hindi", kn: "Kannada" };
const HOW: Record<string, string> = { in_person: "in person", call: "on a call", whatsapp: "on WhatsApp" };
const BOARDS: Record<string, string> = { cbse: "CBSE", icse: "ICSE", karnataka: "Karnataka State Board" };
const KINDS: Record<string, string> = {
  reminder: "Fee reminder",
  receipt: "Fee receipt",
  absence: "Absence message",
  progress: "Progress note",
  progress_note: "Progress note",
  note: "Weekly note",
  can_do: "Can now do",
  test_tomorrow: "Test tomorrow",
  homework: "Homework",
  consent: "Consent ask",
  forward_ask: "Ask to forward",
  not_on_track: "Not on track",
  gap_report: "What the mock showed",
};
const HOMEWORK: Record<string, string> = { given: "given", done: "done", partial: "partly done", not_done: "not done" };
const SHORT_DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

/** "+91 98450 12345" for an Indian mobile number; any other as it is. */
export function phoneWords(phone: string): string {
  const m = /^\+91(\d{5})(\d{5})$/.exec(phone);
  return m ? `+91 ${m[1]} ${m[2]}` : phone;
}

const dayWords = (day: string) => shortWeekdayText(day);
const dayYear = (day: string) => `${shortWeekdayText(day)} ${day.slice(0, 4)}`;
const onDay = (instant: string) => istDay(new Date(instant));
const monthYear = (day: string) => `${MONTHS[Number(day.slice(5, 7)) - 1]} ${day.slice(0, 4)}`;

/** "Mon to Fri" for a run of days, else "Mon, Wed, Fri". */
function daysWords(days: number[]): string {
  const sorted = [...days].sort((a, b) => a - b);
  const run = sorted.length > 2 && sorted.every((d, i) => i === 0 || d === (sorted[i - 1] as number) + 1);
  if (run) return `${SHORT_DAYS[(sorted[0] as number) - 1]} to ${SHORT_DAYS[(sorted.at(-1) as number) - 1]}`;
  return sorted.map((d) => SHORT_DAYS[d - 1]).join(", ");
}

/** The words for the student: him, her, or their first name when no gender is kept. */
function words(student: StudentRecord["student"]) {
  const first = student.name.trim().split(/\s+/)[0] ?? student.name;
  if (student.gender === "male") return { first, obj: "him", pos: "his", Pos: "His" };
  if (student.gender === "female") return { first, obj: "her", pos: "her", Pos: "Her" };
  return { first, obj: first, pos: `${first}’s`, Pos: `${first}’s` };
}

type Row = [label: string, value: string];
const ACCENT = 'rgb("#A35F00")';
const LABEL = 'rgb("#625A52")';
const LINE = 'rgb("#E8E0D5")';

function section(heading: string, rows: Row[]): string {
  const body = rows.length === 0 ? [["", "Nothing kept"] as Row] : rows;
  const cells = body.flatMap(([label, value]) => [`text(fill: ${LABEL})[${t(label)}]`, `[${t(value)}]`]);
  return [
    `#v(14pt)`,
    // A heading stays with its first row: never alone at a page's foot.
    `#block(sticky: true, below: 4pt)[#text(10pt, weight: "bold", fill: ${ACCENT}, tracking: 0.06em)[#upper(${str(heading)})]]`,
    `#table(columns: (130pt, 1fr), stroke: (x, y) => (top: if y > 0 { 0.5pt + ${LINE} }), inset: (x: 0pt, y: 7pt), column-gutter: 12pt, ${cells.join(", ")})`,
  ].join("\n");
}

/** A chapter's states: "Secure, 4 of 4 skills"; "3 of 4 secure, 1 practising"; "2 to come". */
function chapterWords(states: string[]): string {
  const n = (s: string) => states.filter((x) => x === s).length;
  if (states.length > 0 && n("secure") === states.length) return `Secure, ${states.length} of ${states.length} skills`;
  const parts = [
    n("secure") > 0 ? `${n("secure")} of ${states.length} secure` : undefined,
    n("practising") > 0 ? `${n("practising")} practising` : undefined,
    n("taught") > 0 ? `${n("taught")} taught` : undefined,
    n("revisit") > 0 ? `${n("revisit")} to revisit` : undefined,
    n("not_started") > 0 ? `${n("not_started")} to come` : undefined,
  ].filter((p): p is string => p !== undefined);
  return parts.length ? parts.join(", ") : "No skills yet";
}

function feeWords(f: StudentRecord["fees"][number]): string {
  const amount = rupees(f.amount);
  if (f.status === "paid") {
    const how = f.paidMethod === "upi" ? " by UPI" : f.paidMethod === "cash" ? " in cash" : "";
    return `${amount} · paid${how}${f.paidAt ? ` on ${dayWords(onDay(f.paidAt))}` : ""}`;
  }
  if (f.status === "waived") return `${amount} · waived${f.waivedReason ? `: ${f.waivedReason}` : ""}`;
  const reminded = [...f.reminded].sort().at(-1);
  return `${amount} · due${reminded ? ` · reminded ${dayWords(onDay(reminded))}` : ""}`;
}

/** The file's Typst source. `asOf` is the day it is made (India). */
export function exportPdf(record: StudentRecord, centre: { name: string; tutor: string; phone: string }, asOf: string): string {
  const s = record.student;
  const w = words(s);
  const about: Row[] = [];
  const level = s.classLevel ? (/^\d+$/.test(s.classLevel) ? `Class ${s.classLevel}` : s.classLevel.toUpperCase()) : undefined;
  const classLine = [level, s.board ? (BOARDS[s.board] ?? undefined) : undefined, s.school].filter((p): p is string => !!p).join(" · ");
  if (classLine) about.push(["Class", classLine]);
  if (record.batch) {
    const b = record.batch;
    const times = b.start && b.end ? ` ${b.start.slice(0, 5)}–${b.end.slice(0, 5)}` : b.start ? ` ${b.start.slice(0, 5)}` : "";
    about.push(["Batch", b.days.length ? `${b.name}, ${daysWords(b.days)}${times}` : b.name]);
  }
  about.push(["Joined", dayYear(onDay(s.joined))]);
  const parent = [s.parentName, s.parentPhone ? phoneWords(s.parentPhone) : undefined, `messages in ${LANGUAGES[s.language] ?? s.language}`].filter((p): p is string => !!p);
  about.push(["Parent", parent.join(" · ")]);
  if (s.monthlyFee !== undefined) about.push(["Fee", `${rupees(s.monthlyFee)} a month`]);

  const who = s.parentName ?? `${w.first}’s parent`;
  const consent: Row[] = record.consent.map((c) => [
    dayYear(onDay(c.at)),
    c.kind === "given"
      ? `${who} agreed${c.how ? `, ${HOW[c.how] ?? c.how}` : ""}, for ${w.pos} own notes, marking and messages`
      : `${who} withdrew${c.how ? `, ${HOW[c.how] ?? c.how}` : ""}`,
  ]);

  const attendance: Row[] = [];
  if (record.attendance.length) {
    const days = record.attendance.map((a) => a.date).sort();
    const span = monthYear(days[0] as string) === monthYear(days.at(-1) as string) ? monthYear(days[0] as string) : `${MONTHS[Number((days[0] as string).slice(5, 7)) - 1]} to ${MONTHS[Number((days.at(-1) as string).slice(5, 7)) - 1]}`;
    const present = record.attendance.filter((a) => a.status === "present").length;
    attendance.push([span, `${present} of ${record.attendance.length} classes`]);
    const absent = record.attendance.filter((a) => a.status === "absent").map((a) => a.date).sort().reverse();
    if (absent.length) attendance.push(["Absent", absent.map(dayWords).join(", ")]);
  }

  const fees: Row[] = record.fees.map((f) => [monthYear(f.period), feeWords(f)]);

  const recordRows: Row[] = record.chapters.map((c) => [c.name, chapterWords(c.states)]);
  if (record.checks.length) {
    const first = record.checks.map((c) => onDay(c.at)).sort()[0] as string;
    recordRows.push(["Checks", `${record.checks.filter((c) => c.correct).length} of ${record.checks.length} right since ${dayWords(first)}`]);
  }
  if (record.marks.length) {
    const marks = [...record.marks].sort((a, b) => b.date.localeCompare(a.date));
    recordRows.push(["School marks", marks.map((m) => `${m.test}, ${m.score} of ${m.max}`).join(" · ")]);
  }

  const homework: Row[] = record.homework.map((h) => [dayWords(h.given), [h.title, HOMEWORK[h.status] ?? h.status].filter((p): p is string => !!p).join(" · ")]);
  const messages: Row[] = record.messages.map((m) => [
    dayWords(onDay(m.at)),
    `${KINDS[m.kind] ?? m.kind}, ${m.channel === "copied" ? "copied" : "on WhatsApp"}${m.body ? `\n${m.body}` : ""}`,
  ]);
  const made: Row[] = record.made.map((m) => [dayWords(onDay(m.at)), `${KINDS[m.kind] ?? m.kind}${m.language && LANGUAGES[m.language] ? ` (${LANGUAGES[m.language]})` : ""}\n${m.words}`]);

  return [
    `#set page(paper: "a4", margin: (x: 40pt, top: 40pt, bottom: 56pt), footer: context [#set text(8pt, fill: ${LABEL}); ${t(`${s.name} · Everything ${centre.name} keeps, as of ${dayYear(asOf)}`)} #h(1fr) Page #counter(page).display() of #counter(page).final().first()])`,
    `#set text(font: ("Noto Sans", "Noto Sans Devanagari", "Noto Sans Kannada"), size: 10pt, fill: rgb("#1F1B17"))`,
    `#set par(leading: 0.55em)`,
    `#text(20pt, weight: "bold")[${t(s.name)}]`,
    `#v(-4pt)`,
    `#text(fill: ${LABEL})[${t(`Everything ${centre.name} keeps about ${w.obj}, as of ${dayYear(asOf)}`)}]`,
    `#v(6pt)`,
    `#text(weight: "bold")[${t(centre.name)}] #h(1fr) #text(fill: ${LABEL})[${t([centre.tutor, centre.phone ? phoneWords(centre.phone) : ""].filter(Boolean).join(" · "))}]`,
    `#v(-2pt)`,
    `#line(length: 100%, stroke: 2pt + rgb("#FFAB38"))`,
    `#text(fill: ${LABEL})[${t(`This file is for ${w.first}’s parent. It lists what is kept about ${w.obj} in Tutor Central, the app ${w.pos} tutor uses. To correct or remove anything, ask ${centre.tutor}; deleting ${w.first} removes all of it.`)}]`,
    section(`About ${w.obj}`, about),
    section("Consent", consent),
    section("Attendance", attendance),
    section("Fees", fees),
    section(`${w.Pos} record`, recordRows),
    section("Homework", homework),
    section(`Messages to ${w.pos} parent`, messages),
    section(`Made about ${w.obj}`, made),
  ].join("\n\n");
}


