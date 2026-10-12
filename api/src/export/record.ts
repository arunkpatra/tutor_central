import { createClient } from "@supabase/supabase-js";
import type { Database } from "../generated/database.js";
import type { ExportSource } from "../jobs/kinds/export.js";
import type { SkillState } from "../plan/types.js";

/** Everything Tutor Central keeps about a student (D92), as the export's file lists it. */
export type StudentRecord = {
  student: {
    id: string;
    name: string;
    gender?: "male" | "female" | "other";
    classLevel?: string;
    board?: string;
    school?: string;
    /** When the student was added (an instant). */
    joined: string;
    parentName?: string;
    parentPhone?: string;
    /** The parent's message language: en, hinglish, hi or kn. */
    language: string;
    monthlyFee?: number;
  };
  batch?: { name: string; days: number[]; start?: string | null; end?: string | null };
  consent: { kind: "given" | "withdrawn"; how?: string | null; at: string; phone?: string | null }[];
  attendance: { date: string; status: "present" | "absent" }[];
  fees: { period: string; amount: number; status: string; paidAt?: string | null; paidMethod?: string | null; waivedReason?: string | null; reminded: string[] }[];
  chapters: { subject: string; name: string; position: number; states: SkillState[] }[];
  checks: { at: string; correct: boolean }[];
  marks: { subject: string; test: string; date: string; score: number; max: number }[];
  homework: { given: string; title?: string; status: string }[];
  /** Each message sent or copied to the parent: its time, kind and channel, and its words where the log keeps them. */
  messages: { at: string; kind: string; channel: string; body?: string | null }[];
  /** Each note and message the AI service wrote about the student, with its words. */
  made: { at: string; kind: string; language?: string; words: string }[];
};

/** The words of a call's output about a student: a message, a progress note, a gap report's summary. */
export function wordsOf(output: unknown): string | undefined {
  const o = (output ?? {}) as Record<string, unknown>;
  for (const key of ["message", "note", "summary", "text"]) if (typeof o[key] === "string" && (o[key] as string).trim() !== "") return o[key] as string;
  return undefined;
}

/** The student's whole record through the service role (D83); every read names the job's centre and the student. */
export function makeExportSource(url: string, serviceKey: string): ExportSource {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const must = <T>(r: { data: T; error: { message: string } | null }, what: string): NonNullable<T> => {
    if (r.error || r.data === null || r.data === undefined) throw new Error(`${what}: ${r.error?.message ?? "nothing"}`);
    return r.data as NonNullable<T>;
  };
  return {
    async student(centre, id): Promise<StudentRecord | null> {
      const row = (await client.from("students").select("id, name, gender, class_level, board, school_id, created_at, parent_name, parent_phone, message_language, monthly_fee, class_id").eq("centre_id", centre).eq("id", id).maybeSingle()).data;
      if (!row) return null;
      const [school, batch, consent, attendance, fees, chapters, skills, checks, marks, homework, messages, notes, generations] = await Promise.all([
        row.school_id ? client.from("schools").select("name").eq("centre_id", centre).eq("id", row.school_id).maybeSingle() : Promise.resolve({ data: null, error: null }),
        row.class_id ? client.from("classes").select("name, meeting_days, start_time, end_time").eq("centre_id", centre).eq("id", row.class_id).maybeSingle() : Promise.resolve({ data: null, error: null }),
        client.from("consent_events").select("kind, how, at, phone").eq("centre_id", centre).eq("student_id", id).order("at"),
        client.from("attendance_marks").select("status, attendance_sessions!inner(date)").eq("centre_id", centre).eq("student_id", id),
        client.from("fee_invoices").select("period, amount, status, paid_at, paid_method, waived_reason").eq("centre_id", centre).eq("student_id", id).order("period", { ascending: false }),
        client.from("chapters").select("id, subject, name, position").eq("centre_id", centre).eq("student_id", id).order("position"),
        client.from("skills").select("chapter_id, position, state").eq("centre_id", centre).eq("student_id", id).order("position"),
        client.from("checks").select("created_at, correct, kind").eq("centre_id", centre).eq("student_id", id),
        client.from("marks").select("subject, test, date, score, max").eq("centre_id", centre).eq("student_id", id).order("date", { ascending: false }),
        client.from("homework").select("given_at, status, artefacts(title)").eq("centre_id", centre).eq("student_id", id).order("given_at", { ascending: false }),
        client.from("message_log").select("created_at, kind, channel, body, about_date").eq("centre_id", centre).eq("student_id", id).order("created_at", { ascending: false }),
        client.from("artefacts").select("created_at, kind, content").eq("centre_id", centre).eq("student_id", id).in("kind", ["note", "can_do"]).order("created_at", { ascending: false }),
        client.from("ai_generations").select("created_at, kind, output").eq("centre_id", centre).eq("student_id", id).eq("status", "ok").not("kind", "in", "(note,can_do)").order("created_at", { ascending: false }),
      ]);
      const skillRows = must(skills, "skills");
      const reminders = must(messages, "message_log").filter((m) => m.kind === "reminder");
      return {
        student: {
          id: row.id,
          name: row.name,
          ...(row.gender ? { gender: row.gender as StudentRecord["student"]["gender"] } : {}),
          ...(row.class_level ? { classLevel: row.class_level } : {}),
          ...(row.board ? { board: row.board } : {}),
          ...(school.data?.name ? { school: school.data.name } : {}),
          joined: row.created_at,
          ...(row.parent_name ? { parentName: row.parent_name } : {}),
          ...(row.parent_phone ? { parentPhone: row.parent_phone } : {}),
          language: row.message_language,
          ...(row.monthly_fee !== null ? { monthlyFee: row.monthly_fee } : {}),
        },
        ...(batch.data ? { batch: { name: batch.data.name, days: batch.data.meeting_days, start: batch.data.start_time, end: batch.data.end_time } } : {}),
        consent: must(consent, "consent_events").map((c) => ({ kind: c.kind as "given" | "withdrawn", how: c.how, at: c.at, phone: c.phone })),
        attendance: must(attendance, "attendance_marks").map((a) => ({ date: (a.attendance_sessions as unknown as { date: string }).date, status: a.status as "present" | "absent" })),
        fees: must(fees, "fee_invoices").map((f) => ({
          period: f.period,
          amount: f.amount,
          status: f.status,
          paidAt: f.paid_at,
          paidMethod: f.paid_method,
          waivedReason: f.waived_reason,
          reminded: reminders.filter((m) => m.about_date === f.period).map((m) => m.created_at),
        })),
        chapters: must(chapters, "chapters").map((c) => ({ subject: c.subject, name: c.name, position: c.position, states: skillRows.filter((s) => s.chapter_id === c.id).map((s) => s.state as SkillState) })),
        checks: must(checks, "checks").filter((c) => c.kind !== "placement").map((c) => ({ at: c.created_at, correct: c.correct })),
        marks: must(marks, "marks").map((m) => ({ subject: m.subject, test: m.test, date: m.date, score: m.score, max: m.max })),
        homework: must(homework, "homework").map((h) => ({ given: h.given_at, ...((h.artefacts as unknown as { title?: string } | null)?.title ? { title: (h.artefacts as unknown as { title: string }).title } : {}), status: h.status })),
        messages: must(messages, "message_log").map((m) => ({ at: m.created_at, kind: m.kind, channel: m.channel, body: m.body })),
        made: [
          ...must(notes, "artefacts").flatMap((n) => {
            const c = n.content as { message?: string; language?: string };
            return c.message ? [{ at: n.created_at, kind: n.kind, ...(c.language ? { language: c.language } : {}), words: c.message }] : [];
          }),
          ...must(generations, "ai_generations").flatMap((g) => {
            const words = wordsOf(g.output ? JSON.parse(g.output as unknown as string) : null);
            return words ? [{ at: g.created_at, kind: g.kind, words }] : [];
          }),
        ].sort((a, b) => b.at.localeCompare(a.at)),
      };
    },
    async centre(centre) {
      const row = must(await client.from("centres").select("name, owner_id, whatsapp_number").eq("id", centre).single(), "centres");
      const profile = (await client.from("profiles").select("display_name").eq("user_id", row.owner_id).maybeSingle()).data;
      return { name: row.name, tutor: profile?.display_name ?? row.name, phone: row.whatsapp_number ?? "" };
    },
    async upload(bucket, path, bytes) {
      const { error } = await client.storage.from(bucket).upload(path, bytes, { contentType: "application/pdf", upsert: true });
      if (error) throw new Error(`${bucket}: ${error.message}`);
    },
  };
}
