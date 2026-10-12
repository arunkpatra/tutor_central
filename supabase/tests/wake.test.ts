import { SQL } from "bun";
import { afterAll, beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, userClient } from "./client";

// The two wakes from inside the database (D85): a job queued posts to /jobs/wake, and pg_cron gets /jobs/tick each
// minute, both with the worker's address and secret from Vault, and neither when the secrets are absent.
let l: Local;
let sql: SQL;
let a: SupabaseClient;
let centreA: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  sql = new SQL(l.db);
  a = await userClient(l, `wake-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Wake A" })).data as string;
});
afterAll(() => sql.close());

/** Runs the body in a transaction that is always rolled back: the secrets and the queued requests never stay. */
async function rolledBack(body: (tx: SQL) => Promise<void>) {
  const done = new Error("rollback");
  await sql
    .begin(async (tx) => {
      await body(tx as unknown as SQL);
      throw done;
    })
    .catch((e) => {
      if (e !== done) throw e;
    });
}

const queued = (tx: SQL, since: number) =>
  tx`select method, url, headers, body from net.http_request_queue where id > ${since} order by id`;
const lastQueued = async (tx: SQL) => Number((await tx`select coalesce(max(id), 0)::bigint as id from net.http_request_queue`)[0].id);

test("queuing a job posts to the worker when the secrets are set, and does nothing when they are not", async () => {
  await rolledBack(async (tx) => {
    const since = await lastQueued(tx);
    await tx`delete from vault.secrets where name in ('worker_url', 'worker_secret')`;
    await tx`insert into public.jobs (centre_id, kind, idempotency_key) values (${centreA}, 'plan', ${`wake-none-${stamp}`})`;
    expect(await queued(tx, since)).toEqual([]);
  });
  await rolledBack(async (tx) => {
    const since = await lastQueued(tx);
    await tx`delete from vault.secrets where name in ('worker_url', 'worker_secret')`;
    await tx`select vault.create_secret('http://127.0.0.1:3000', 'worker_url')`;
    await tx`select vault.create_secret('s3cret', 'worker_secret')`;
    const [job] = await tx`insert into public.jobs (centre_id, kind, idempotency_key) values (${centreA}, 'plan', ${`wake-one-${stamp}`}) returning id`;
    const q = await queued(tx, since);
    expect(q.length).toBe(1);
    expect(q[0]).toMatchObject({ method: "POST", url: "http://127.0.0.1:3000/jobs/wake" });
    // The worker drains for up to 200 s: the request stays open so the database sees its answer (the review's finding 9).
    expect((await tx`select timeout_milliseconds from net.http_request_queue where id > ${since}`)[0].timeout_milliseconds).toBe(290000);
    expect(q[0].headers.Authorization).toBe("Bearer s3cret");
    expect(JSON.parse(Buffer.from(q[0].body).toString())).toEqual({ job: job.id });
  });
});

test("the minute wake is scheduled and reads the same secrets", async () => {
  const job = await sql`select schedule, command, active from cron.job where jobname = 'wake_worker_minute'`;
  expect(job[0]).toEqual({ schedule: "* * * * *", command: "select public.wake_worker_tick()", active: true });
  await rolledBack(async (tx) => {
    const since = await lastQueued(tx);
    await tx`delete from vault.secrets where name in ('worker_url', 'worker_secret')`;
    await tx`select public.wake_worker_tick()`;
    expect(await queued(tx, since)).toEqual([]);
    await tx`select vault.create_secret('http://127.0.0.1:3000', 'worker_url')`;
    await tx`select vault.create_secret('s3cret', 'worker_secret')`;
    await tx`select public.wake_worker_tick()`;
    const q = await queued(tx, since);
    expect(q[0]).toMatchObject({ method: "GET", url: "http://127.0.0.1:3000/jobs/tick" });
    expect(q[0].headers.Authorization).toBe("Bearer s3cret");
  });
});

test("the wakes are nobody's to call", async () => {
  expect((await a.rpc("wake_worker_tick")).error).not.toBeNull();
  expect((await a.rpc("wake_worker")).error).not.toBeNull();
});
