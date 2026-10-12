import { createClient } from "@supabase/supabase-js";
import type { Database, Json } from "../generated/database.js";
import { type NoteRead, type NoteSource, weekEnding } from "../jobs/kinds/note-day.js";
import { addDays } from "../plan/dates.js";
import type { PrepItem } from "../plan/exam-prep.js";
import type { SkillState } from "../plan/types.js";
import type { PlanRecordSource } from "../jobs/kinds/plan.js";

/** The note day's reads through the service role (D83), as NoteRecordReader read them; every query names the job's
 *  centre. Tutors and the outbox are the plan's (`pushUsers`, `notify`). */
export function makeNoteSource(url: string, serviceKey: string, plans: Pick<PlanRecordSource, "pushUsers" | "notify">): NoteSource {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const must = <T>(r: { data: T; error: { message: string } | null }, what: string): NonNullable<T> => {
    if (r.error || r.data === null || r.data === undefined) throw new Error(`${what}: ${r.error?.message ?? "nothing"}`);
    return r.data as NonNullable<T>;
  };
  const columns = "id, name, parent_name, class_level, message_language, school_id, class_id";
  return {
    async read(centre, input) {
      type Row = { id: string; name: string; parent_name: string | null; class_level: string | null; message_language: string; school_id: string | null; class_id: string | null };
      let rows: Row[];
      let weekOf: (row: Row) => Promise<{ from: string; to: string }>;
      if ("classId" in input) {
        rows = must(
          await client.from("students").select(columns).eq("centre_id", centre).eq("class_id", input.classId).is("archived_at", null).not("parent_phone", "is", null),
          "students",
        ) as Row[];
        const week = weekEnding(input.date);
        weekOf = async () => week;
      } else {
        rows = must(await client.from("students").select(columns).eq("centre_id", centre).eq("id", input.studentId), "students") as Row[];
        // The student's batch note day in that week (Sunday when unset).
        weekOf = async (row) => {
          const room = row.class_id ? (await client.from("classes").select("note_weekday").eq("centre_id", centre).eq("id", row.class_id).maybeSingle()).data : null;
          return weekEnding(addDays(input.week, (room?.note_weekday ?? 7) - 1));
        };
      }
      const centreRow = must(await client.from("centres").select("name").eq("id", centre).single(), "centres");
      const items = must(
        await client.from("school_items").select("id, kind, student_id, school_id, class_level, date, end_date, subject, title, portions, received_at, window_days").eq("centre_id", centre),
        "school_items",
      ).map(
        (i): PrepItem => ({
          id: i.id,
          kind: i.kind as PrepItem["kind"],
          audience: i.student_id ? { student: i.student_id } : { ...(i.school_id ? { school: i.school_id } : {}), ...(i.class_level ? { classLevel: i.class_level } : {}) },
          title: i.title,
          ...(i.subject ? { subject: i.subject } : {}),
          date: i.date,
          ...(i.end_date ? { endDate: i.end_date } : {}),
          ...(i.portions ? { portions: i.portions } : {}),
          receivedAt: i.received_at,
          ...(i.window_days !== null ? { windowDays: i.window_days } : {}),
        }),
      );
      const students: NoteRead["students"] = [];
      for (const row of rows) {
        const week = await weekOf(row);
        const since = `${week.from}T00:00:00+05:30`;
        const [chapters, skills, checks, marks, sessions, notes] = await Promise.all([
          client.from("chapters").select("id, subject, position, name, ladder").eq("centre_id", centre).eq("student_id", row.id).order("position"),
          client.from("skills").select("id, chapter_id, position, name, state, state_at").eq("centre_id", centre).eq("student_id", row.id).order("position"),
          client.from("checks").select("skill_id, created_at, correct, kind").eq("centre_id", centre).eq("student_id", row.id).gte("created_at", since),
          client.from("marks").select("subject, test, date, score, max").eq("centre_id", centre).eq("student_id", row.id),
          client.from("attendance_marks").select("status, attendance_sessions!inner(date)").eq("centre_id", centre).eq("student_id", row.id).gte("attendance_sessions.date", week.from).lte("attendance_sessions.date", week.to),
          client.from("artefacts").select("content").eq("centre_id", centre).eq("student_id", row.id).in("kind", ["note", "can_do"]).gte("created_at", `${addDays(week.from, -7)}T00:00:00+05:30`),
        ]);
        // The week's Monday as the app and the job keep it, an ISO day (noteContent).
        const kept = must(notes, "artefacts").some((n) => (n.content as { week_monday?: unknown }).week_monday === week.from);
        const student = { id: row.id, name: row.name, ...(row.class_level ? { classLevel: row.class_level } : {}), ...(row.school_id ? { schoolID: row.school_id } : {}) };
        students.push({
          student: { id: row.id, name: row.name, ...(row.parent_name ? { parentName: row.parent_name } : {}), ...(row.class_level ? { classLevel: row.class_level } : {}), language: row.message_language },
          week,
          kept,
          record: {
            student,
            chapters: must(chapters, "chapters").map((c) => ({ id: c.id, subject: c.subject, position: c.position, name: c.name, ...(c.ladder ? { ladder: c.ladder } : {}) })),
            skills: must(skills, "skills").map((s) => ({ id: s.id, chapterID: s.chapter_id, position: s.position, name: s.name, state: s.state as SkillState, stateAt: s.state_at })),
            checks: must(checks, "checks").map((c) => ({ skillID: c.skill_id, at: c.created_at, correct: c.correct, isPlacement: c.kind === "placement" })),
            sessions: must(sessions, "attendance_marks").map((a) => ({ date: (a.attendance_sessions as unknown as { date: string }).date, mark: a.status as "present" | "absent" })),
            marks: must(marks, "marks").map((x) => ({ subject: x.subject, test: x.test, date: x.date, score: x.score, max: x.max })),
            items,
          },
        });
      }
      return { centreName: centreRow.name, students };
    },
    async keep(centre, student, artefact, key) {
      const kept = await client.rpc("keep_artefact", {
        p_centre: centre,
        p_artefact: artefact as unknown as Json,
        p_plan: null as unknown as string,
        p_group_no: 0,
        p_student: student,
        p_item_kind: "practise",
        p_school_item: null as unknown as string,
        p_key: key,
      });
      return must(kept, "keep_artefact") as string;
    },
    pushUsers: (centre) => plans.pushUsers(centre),
    notify: (centre, user, rows) => plans.notify(centre, user, rows),
  };
}
