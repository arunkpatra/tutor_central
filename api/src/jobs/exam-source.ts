import { createClient } from "@supabase/supabase-js";
import type { Database, Json } from "../generated/database.js";
import type { PrepItem } from "../plan/exam-prep.js";
import { reachesStudent } from "../plan/exam-prep.js";
import type { SkillState } from "../plan/types.js";
import { MockOutput } from "../schemas.js";
import type { ExamRead, ExamSource } from "./kinds/exam-prep.js";

type ItemRow = Database["public"]["Tables"]["school_items"]["Row"];

const prepItem = (i: Pick<ItemRow, "id" | "kind" | "student_id" | "school_id" | "class_level" | "title" | "subject" | "date" | "end_date" | "portions" | "received_at" | "window_days">): PrepItem => ({
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
});

/** The exam job's reach (D106) through the service role (D83), every read and write by the job's own centre: the item,
 *  the students it reaches and their batches, their chapters and skills, the holidays, the mock and the gap reports kept
 *  for it, the marks saved on it; the split written on the item; keep_artefact; request_plan for a replace. */
export function makeExamSource(url: string, serviceKey: string): ExamSource {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const must = <T>(r: { data: T; error: { message: string } | null }, what: string): NonNullable<T> => {
    if (r.error || r.data === null || r.data === undefined) throw new Error(`${what}: ${r.error?.message ?? "nothing"}`);
    return r.data as NonNullable<T>;
  };
  const columns = "id, kind, student_id, school_id, class_level, title, subject, date, end_date, portions, received_at, window_days" as const;
  return {
    async read(centre, itemId, today): Promise<ExamRead | null> {
      const found = await client.from("school_items").select(columns).eq("centre_id", centre).eq("id", itemId).maybeSingle();
      if (found.error) throw new Error(`school_items: ${found.error.message}`);
      if (!found.data || found.data.kind !== "exam") return null;
      const item = prepItem(found.data);
      const [students, holidays, artefacts, marks] = await Promise.all([
        // In the order they were added, so the exam's first batch (its `preparation`) does not change between splits.
        client
          .from("students")
          .select("id, name, class_level, school_id, class_id")
          .eq("centre_id", centre)
          .is("archived_at", null)
          .order("created_at"),
        client.from("school_items").select(columns).eq("centre_id", centre).eq("kind", "holiday"),
        client.from("artefacts").select("id, kind, student_id, content, created_at").eq("centre_id", centre).eq("school_item_id", itemId).in("kind", ["mock", "gap_report"]).order("created_at"),
        client.from("marks").select("student_id, questions").eq("centre_id", centre).eq("school_item_id", itemId).not("questions", "is", null),
      ]);
      const reached = must(students, "students")
        .map((s) => ({ id: s.id, name: s.name, ...(s.class_level ? { classLevel: s.class_level } : {}), ...(s.school_id ? { schoolID: s.school_id } : {}), classId: s.class_id }))
        .filter((s) => reachesStudent(item, s));
      const ids = reached.map((s) => s.id);
      const classIds = [...new Set(reached.map((s) => s.classId).filter((c): c is string => c !== null))];
      const [classes, plans, chapters, skills] = await Promise.all([
        classIds.length ? client.from("classes").select("id, meeting_days").eq("centre_id", centre).in("id", classIds) : Promise.resolve({ data: [], error: null }),
        classIds.length ? client.from("plans").select("class_id, session_id").eq("centre_id", centre).eq("date", today).in("class_id", classIds) : Promise.resolve({ data: [], error: null }),
        ids.length ? client.from("chapters").select("id, student_id, subject, position, name, ladder").eq("centre_id", centre).in("student_id", ids).order("position") : Promise.resolve({ data: [], error: null }),
        ids.length ? client.from("skills").select("id, student_id, chapter_id, position, name, state, state_at").eq("centre_id", centre).in("student_id", ids).order("position") : Promise.resolve({ data: [], error: null }),
      ]);
      const open = new Set(must(plans, "plans").filter((p) => p.session_id === null).map((p) => p.class_id));
      const kept = must(artefacts, "artefacts");
      const mockRow = kept.find((a) => a.kind === "mock");
      const mockContent = mockRow ? MockOutput.safeParse(camel(mockRow.content)) : null;
      const read: ExamRead = {
        item,
        students: reached,
        batches: must(classes, "classes").map((c) => ({ classId: c.id, meetingDays: c.meeting_days, openPlanToday: open.has(c.id) })),
        chapters: group(must(chapters, "chapters"), (c) => ({ id: c.id, subject: c.subject, position: c.position, name: c.name, ...(c.ladder ? { ladder: c.ladder } : {}) })),
        skills: group(must(skills, "skills"), (k) => ({ id: k.id, chapterID: k.chapter_id, position: k.position, name: k.name, state: k.state as SkillState, stateAt: k.state_at })),
        holidays: must(holidays, "school_items").map(prepItem),
        mock: mockRow && mockContent?.success ? { id: mockRow.id, content: mockContent.data } : null,
        marks: must(marks, "marks")
          .filter((m) => ids.includes(m.student_id))
          .map((m) => ({ student: m.student_id, questions: (m.questions as { number: number; marks: number; note?: string | null }[] | null) ?? [] })),
        reports: [...new Set(kept.filter((a) => a.kind === "gap_report" && a.student_id).map((a) => a.student_id as string))],
      };
      return read;
    },
    async writePreparation(centre, item, days, byBatch) {
      const r = await client
        .from("school_items")
        .update({ preparation: days as unknown as Json, preparations: byBatch as unknown as Json })
        .eq("centre_id", centre)
        .eq("id", item);
      if (r.error) throw new Error(`school_items: ${r.error.message}`);
    },
    async keep(centre, artefact, place, key) {
      const kept = await client.rpc("keep_artefact", {
        p_centre: centre,
        p_artefact: artefact as unknown as Json,
        p_plan: null as unknown as string,
        p_group_no: 0,
        p_student: (place.student ?? null) as string,
        p_item_kind: "practise",
        p_school_item: place.schoolItem,
        p_key: key,
      });
      return must(kept, "keep_artefact") as string;
    },
    async replacePlan(centre, classId, date) {
      const r = await client.rpc("request_plan", { p_centre: centre, p_class: classId, p_date: date, p_choices: {} });
      if (r.error) throw new Error(`request_plan: ${r.error.message}`);
    },
  };
}

function group<R extends { student_id: string }, T>(rows: R[], shape: (row: R) => T): Record<string, T[]> {
  const out: Record<string, T[]> = {};
  for (const row of rows) (out[row.student_id] ??= []).push(shape(row));
  return out;
}

/** A kept mock's snake-case content as the schema reads it. */
function camel(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(camel);
  if (!value || typeof value !== "object") return value;
  return Object.fromEntries(Object.entries(value as Record<string, unknown>).map(([k, v]) => [k.replace(/_([a-z])/g, (_, c: string) => c.toUpperCase()), camel(v)]));
}
