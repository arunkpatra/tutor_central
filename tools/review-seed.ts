#!/usr/bin/env bun
/** bun tools/review-seed.ts --email <address> --parent-phone <+91…> --out <file>: the SQL that fills App Review's demo
 *  centre (D51) with a sample centre, written for `supabase db query --linked -f <file>` (the `seed-review` workflow).
 *  The owner makes the account in the app; this finds its centre by the email and refuses one that already has
 *  students, so a real tutor's centre is never touched. Every parent has the one number given, a number the owner
 *  holds, so a reviewer's WhatsApp message reaches no stranger. Dates are relative to the day it runs. */
import { writeFileSync } from "node:fs";

const EMAIL = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const PHONE = /^\+91[6-9][0-9]{9}$/;

const CLASSES = [
  { key: "maths", name: "Class 10 Maths", subject: "Mathematics", fee: 1200, days: "{1,3,5}", start: "17:00", end: "18:00" },
  { key: "science", name: "Class 8 Science", subject: "Science", fee: 1000, days: "{2,4}", start: "16:30", end: "17:30" },
];

/** Name, class key (null: no class yet), own fee (null: the class's), the parent, paid this month. */
const STUDENTS: [string, string | null, number | null, string, boolean][] = [
  ["Akshita Rao", "maths", null, "Priya Rao", true],
  ["Ananya Iyer", "maths", null, "Suresh Iyer", true],
  ["Bir Bikram Singh", "maths", null, "Harjeet Singh", true],
  ["Dev Kumar", "science", null, "Ramesh Kumar", false],
  ["Hemanth Reddy", "maths", null, "Lakshmi Reddy", false],
  ["Lakshmi Menon", "maths", null, "Anil Menon", true],
  ["Meher Shah", "science", null, "Kavita Shah", true],
  ["Nikhil Das", "science", null, "Arup Das", false],
  ["Riya Sharma", "maths", 1500, "Neha Sharma", true],
  ["Sahil Verma", null, 800, "Deepak Verma", false],
];

const literal = (s: string) => `'${s.replaceAll("'", "''")}'`;

export function reviewSeedSql(email: string, parentPhone: string): string {
  if (!EMAIL.test(email)) throw new Error(`"${email}" is not an email address`);
  if (!PHONE.test(parentPhone)) throw new Error(`"${parentPhone}" is not an Indian mobile number as +91 and ten digits`);
  const classes = CLASSES.map(
    (c) => `  insert into public.classes (centre_id, name, subject, monthly_fee, meeting_days, start_time, end_time)
  values (c, ${literal(c.name)}, ${literal(c.subject)}, ${c.fee}, ${literal(c.days)}, ${literal(c.start)}, ${literal(c.end)})
  returning id into ${c.key};`,
  ).join("\n");
  const students = STUDENTS.map(
    ([name, cls, fee, parent]) => `  insert into public.students (centre_id, class_id, name, monthly_fee, parent_name, parent_phone)
  values (c, ${cls ?? "null"}, ${literal(name)}, ${fee ?? "null"}, ${literal(parent)}, ${literal(parentPhone)});`,
  ).join("\n");
  const paid = STUDENTS.filter((s) => s[4]).map((s) => literal(s[0]));
  return `do $$
declare
  u uuid;
  c uuid;
  ${CLASSES.map((cl) => `${cl.key} uuid;`).join("\n  ")}
begin
  select id into u from auth.users where lower(email) = lower(${literal(email)});
  if u is null then raise exception 'No account with the email ${email.replaceAll("'", "''")}: make it in the app first'; end if;
  select centre_id into c from public.centre_members where user_id = u and role = 'owner';
  if c is null then raise exception 'That account has no centre yet: finish the setup screen in the app first'; end if;
  if exists (select 1 from public.students where centre_id = c) then
    raise exception 'That centre already has students: nothing was added';
  end if;

${classes}

${students}

  -- This month's fees for everyone (what generate_fees makes), then six paid by UPI three days ago.
  insert into public.fee_invoices (centre_id, student_id, period, amount)
  select s.centre_id, s.id, date_trunc('month', current_date)::date, coalesce(s.monthly_fee, k.monthly_fee, 0)
  from public.students s left join public.classes k on k.id = s.class_id
  where s.centre_id = c;
  update public.fee_invoices f set status = 'paid', paid_at = now() - interval '3 days', paid_method = 'upi'
  from public.students s
  where s.id = f.student_id and f.centre_id = c and s.name in (${paid.join(", ")});

  -- The last four weeks on each class's meeting days, today left for the reviewer; every fifth mark absent.
  insert into public.attendance_sessions (centre_id, class_id, date)
  select k.centre_id, k.id, d::date
  from public.classes k, generate_series(current_date - 27, current_date - 1, interval '1 day') d
  where k.centre_id = c and extract(isodow from d)::smallint = any (k.meeting_days);
  insert into public.attendance_marks (centre_id, session_id, student_id, status)
  select a.centre_id, a.id, s.id,
         case when row_number() over (order by a.date, s.name) % 5 = 0 then 'absent' else 'present' end::public.attendance_status
  from public.attendance_sessions a join public.students s on s.class_id = a.class_id
  where a.centre_id = c;

  insert into public.calendar_events (centre_id, title, date, start_time, end_time, note)
  values (c, 'Parents'' meeting', current_date + 3, '11:00', '12:00', 'Class 10 parents');
  insert into public.tasks (centre_id, title, due_date) values
    (c, 'Buy chalk and dusters', null),
    (c, 'Call Dev''s father about Saturday', current_date + 2);
end
$$;
`;
}

if (import.meta.main) {
  const argv = process.argv.slice(2);
  const flag = (name: string) => {
    const value = argv[argv.indexOf(name) + 1];
    if (!argv.includes(name) || !value || value.startsWith("--")) {
      console.error("usage: bun tools/review-seed.ts --email <address> --parent-phone <+91…> --out <file>");
      process.exit(2);
    }
    return value;
  };
  try {
    writeFileSync(flag("--out"), reviewSeedSql(flag("--email"), flag("--parent-phone")));
  } catch (e) {
    console.error((e as Error).message);
    process.exit(1);
  }
}
