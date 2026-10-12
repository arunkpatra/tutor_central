#!/usr/bin/env bun
/** bun tools/run-job.ts --email <owner> --batch <name> [--date YYYY-MM-DD] --out <file> --poll-out <file>: the SQL the
 *  `run-job` workflow runs with `supabase db query --linked` to queue one `plan` job for a batch and day (default:
 *  tomorrow in India), and the SQL it polls. The owner's email and the batch's name are typed at the workflow's prompt,
 *  never written to the repository (D55). The SQL runs as the database's owner with no request, so it inserts the job's
 *  row itself (enqueue_job asks for a member); the insert wakes the worker (0034). */
import { writeFileSync } from "node:fs";

const EMAIL = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const DAY = /^\d{4}-\d{2}-\d{2}$/;
const literal = (s: string) => `'${s.replaceAll("'", "''")}'`;

function checked(email: string, batch: string, date: string) {
  if (!EMAIL.test(email)) throw new Error("that is not an email address");
  if (batch.trim() === "" || batch.length > 80) throw new Error("a batch's name is 1 to 80 characters");
  if (!DAY.test(date)) throw new Error(`"${date}" is not a day as YYYY-MM-DD`);
}

/** The centre the email owns and its batch of that name (one, not archived), as `v_centre` and `v_class`. */
function find(email: string, batch: string): string {
  return `  select c.id into v_centre from public.centres c join auth.users u on u.id = c.owner_id where lower(u.email) = lower(${literal(email)});
  if v_centre is null then raise exception 'run_job: no centre for that email'; end if;
  select count(*) into v_count from public.classes c where c.centre_id = v_centre and c.name = ${literal(batch)} and c.archived_at is null;
  if v_count = 0 then raise exception 'run_job: no batch of that name'; end if;
  if v_count > 1 then raise exception 'run_job: two batches of that name'; end if;
  select c.id into v_class from public.classes c where c.centre_id = v_centre and c.name = ${literal(batch)} and c.archived_at is null;`;
}

export function queueSql(email: string, batch: string, date: string): string {
  checked(email, batch, date);
  return `do $$
declare v_centre uuid; v_class uuid; v_count integer;
begin
${find(email, batch)}
  insert into public.jobs (centre_id, kind, idempotency_key, input)
  values (v_centre, 'plan', 'plan:' || v_class || ':${date}', jsonb_build_object('class_id', v_class, 'date', '${date}'))
  on conflict do nothing;
end $$;
`;
}

/** The job's state, the step reached, the result (the plan's id) and the error: nothing about a student. */
export function pollSql(email: string, batch: string, date: string): string {
  checked(email, batch, date);
  return `select j.state, j.step ->> 'at' as at, j.result, j.error, j.attempts, j.cost_paise
  from public.jobs j
  join public.classes c on j.idempotency_key = 'plan:' || c.id || ':${date}' and j.centre_id = c.centre_id
  join public.centres ce on ce.id = c.centre_id
  join auth.users u on u.id = ce.owner_id
 where lower(u.email) = lower(${literal(email)}) and c.name = ${literal(batch)} and c.archived_at is null;
`;
}

export function tomorrowInIndia(now: Date): string {
  return new Date(now.getTime() + 5.5 * 3_600_000 + 86_400_000).toISOString().slice(0, 10);
}

if (import.meta.main) {
  const args = process.argv.slice(2);
  const flag = (name: string) => {
    const i = args.indexOf(name);
    return i >= 0 ? args[i + 1] : undefined;
  };
  const [email, batch, out, pollOut] = [flag("--email"), flag("--batch"), flag("--out"), flag("--poll-out")];
  const date = flag("--date") || tomorrowInIndia(new Date());
  if (!email || !batch || !out || !pollOut) {
    console.error("usage: bun tools/run-job.ts --email <owner> --batch <name> [--date YYYY-MM-DD] --out <file> --poll-out <file>");
    process.exit(2);
  }
  try {
    writeFileSync(out, queueSql(email, batch, date));
    writeFileSync(pollOut, pollSql(email, batch, date));
    console.log(`a plan job for ${date}`);
  } catch (e) {
    console.error((e as Error).message);
    process.exit(1);
  }
}
