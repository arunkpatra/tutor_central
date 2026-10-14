/** The shapes of migration 0047's answers (the `admin_*` functions), as the pages read them. Times are ISO strings;
 *  money is paise. Mirrors `supabase/migrations/20261121000047_v3_admin_reads.sql`. */

export type CentreRow = {
  id: string;
  name: string;
  owner_name: string | null;
  since: string;
  students: number;
  tutors: number;
  last_opened: string | null;
  cost_paise: number;
  in_use: boolean;
  jobs_today: number;
  failed_today: number;
};
export type Centres = {
  tiles: { centres: number; active_week: number; cost_paise: number; failed_today: number };
  rows: CentreRow[];
};

export type Tutor = {
  user_id: string;
  name: string | null;
  role: "owner" | "teacher";
  /** From the Auth admin API (not SQL), filled by the real `Data`. */
  email: string | null;
  last_sign_in: string | null;
  push: { build: number | null; env: string } | null;
};
export type Centre = {
  id: string;
  name: string;
  owner_name: string | null;
  since: string;
  students: number;
  batches: number;
  in_use: boolean;
  cost_paise: number;
  calls: number;
  allowance: number | null;
  allowance_paise: number | null;
  cost_by_kind: { plan: number; notes: number; exams: number; other: number };
  cost_by_model: { model: string; paise: number }[];
  jobs_today: number;
  failed_today: number;
  last_close: string | null;
  tutors: Tutor[];
};

export type Activity = {
  id: string;
  at: string;
  kind: string;
  screen: string | null;
  what: string | null;
  who: string | null;
};

export type JobState = "queued" | "running" | "waiting" | "done" | "failed" | "cancelled";
export type JobRow = {
  id: string;
  kind: string;
  centre_id: string | null;
  centre: string | null;
  /** Null for a kind with nothing to name (an artefact, an eval run). */
  subject: string | null;
  state: JobState;
  step: string | null;
  run_at: string;
  started_at: string | null;
  finished_at: string | null;
  created_at: string;
  seconds: number | null;
  attempts: number;
  cost_paise: number;
  made: number | null;
  not_made: number | null;
  reason: string | null;
  by_member: boolean;
};

export type Consent = { state: "given" | "withdrawn" | "asked" | "not_asked"; day: string | null };
export type RecordStudent = {
  id: string;
  name: string;
  class_level: string | null;
  batch: string | null;
  consent: Consent;
  tracking: string | null;
};
export type RecordBatch = {
  name: string;
  days: number[] | null;
  start_time: string | null;
  end_time: string | null;
  students: number;
};
export type Record = {
  centre: { id: string; name: string };
  audit_id: string;
  opened_at: string;
  reason: string;
  students: RecordStudent[];
  batches: RecordBatch[];
  made: { id: string; at: string; kind: string; title: string | null; student: string | null; cost_paise: number }[];
};

export type Cost = {
  tiles: { month_paise: number; per_active_centre_paise: number; today_paise: number; active_centres: number };
  byDay: { day: string; paise: number }[];
  byCentre: { id: string; name: string; calls: number; paise: number; per_student_paise: number | null }[];
  byStep: { kind: string; step: string; model: string; batched: boolean; calls: number; paise: number }[];
  byMonth: {
    month: string;
    calls: number;
    paise: number;
    batched_paise: number;
    active_centres: number;
    per_active_centre_paise: number;
  }[];
};

export type CallRow = {
  id: string;
  created_at: string;
  centre_id: string;
  centre: string | null;
  kind: string;
  model: string | null;
  prompt_version: string | null;
  status: "ok" | "failed" | "pending";
  error_reason: string | null;
  tokens_in: number | null;
  tokens_out: number | null;
  latency_ms: number | null;
  cost_paise: number | null;
  student: boolean;
  started_by: string;
  /** The agent's step (0052, D99): a draft, its check, its repair, or the nightly's grade. */
  agent_step: "draft" | "check" | "repair" | "grade";
};
export type Calls = {
  tiles: { calls: number; failed: number; refused: number; median_latency_ms: number | null };
  rows: CallRow[];
};
export type Call = CallRow & {
  input_held: boolean;
  input: unknown;
  output: string | null;
  request_id: string | null;
  idempotency_key: string | null;
  fallback_model: string | null;
  stop_reason: string | null;
  prompt_hash: string | null;
  finished_at: string | null;
  job: { id: string; kind: string; subject: string | null; step: string | null } | null;
};

export type Jobs = { tiles: { today: number; failed: number; running: number; waiting: number }; rows: JobRow[] };
export type JobStep = {
  step: string;
  attempt: number;
  state: JobState;
  error: { reason?: string; message?: string } | null;
  cost_paise: number;
  generation_id: string | null;
  created_at: string;
  seconds: number;
  call: {
    kind: string;
    model: string | null;
    status: string;
    error_reason: string | null;
    latency_ms: number | null;
    replayed: boolean;
  } | null;
};
export type Job = JobRow & {
  error: { reason?: string; message?: string } | null;
  input: { [key: string]: unknown };
  idempotency_key: string;
  steps: JobStep[];
};

export type Errors = {
  tiles: { requests: number; errors: number; rate_pct: number; timeouts: number; median_latency_ms: number | null };
  rows: { route: string; status: number; reason: string | null; last_24h: number; last_7d: number }[];
  recent: {
    created_at: string;
    route: string;
    status: number;
    reason: string | null;
    request_id: string;
    centre: string | null;
  }[];
};

export type AlertRow = {
  id: string;
  kind: string;
  message: string | null;
  centre_id: string | null;
  centre: string | null;
  value: number | null;
  threshold: number | null;
  raised_at: string;
  acknowledged_at: string | null;
  acknowledged_by_email: string | null;
};
export type Alerts = {
  tiles: { open: number; acknowledged_week: number; last_raised: string | null };
  rows: AlertRow[];
};

export type AuditRow = {
  id: string;
  created_at: string;
  admin_user_id: string;
  admin_email: string | null;
  action: string;
  centre_id: string | null;
  centre: string | null;
  target: { [key: string]: unknown };
  reason: string | null;
  ip: string | null;
  subject: string | null;
};

export type CallFilters = { day: string | null; centre: string | null; kind: string | null; status: string | null };
export type JobFilters = { day: string | null; state: string | null; kind: string | null; centre: string | null };
export type AuditFilters = { days: number; admin: string | null; action: string | null };

/** Everything a page reads or writes, one method per section (plan decision 8). The real one calls the `admin_*`
 *  functions as the platform; the preview one answers the boards' figures. */
export type Data = {
  centres(month: string): Promise<Centres>;
  centre(id: string, month: string): Promise<Centre | null>;
  activity(id: string, limit: number): Promise<Activity[]>;
  centreJobs(id: string, limit: number): Promise<JobRow[]>;
  openRecord(admin: string, centre: string, reason: string, ip: string | null): Promise<Record | null>;
  /** The record again for a fresh open by this admin. */
  record(audit: string, admin: string): Promise<Record | null>;
  cost(month: string, centre: string | null): Promise<Cost>;
  calls(filters: CallFilters): Promise<Calls>;
  call(id: string): Promise<Call | null>;
  jobs(filters: JobFilters): Promise<Jobs>;
  job(id: string): Promise<Job | null>;
  errors(hours: number, limit: number): Promise<Errors>;
  alerts(openFirst: boolean): Promise<Alerts>;
  audit(filters: AuditFilters): Promise<AuditRow[]>;
  acknowledge(admin: string, alert: string, ip: string | null): Promise<boolean>;
  retry(admin: string, job: string, ip: string | null): Promise<boolean>;
  cancel(admin: string, job: string, ip: string | null): Promise<boolean>;
  auditWrite(
    admin: string,
    action: string,
    centre: string | null,
    target: { [key: string]: unknown },
    reason: string | null,
    ip: string | null,
  ): Promise<void>;
  /** The admin's own row for the header: the email the audit shows. */
  adminEmail(admin: string): Promise<string | null>;
};
