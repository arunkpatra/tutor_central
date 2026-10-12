import { createClient } from "@supabase/supabase-js";
import type { Database, Json } from "../generated/database.js";
import type { PlanRead, PlanRecordSource } from "./kinds/plan.js";
import type { ClassLevel, NextStep, PlanDraft, Session, SkillState, TrackStatus } from "../plan/types.js";
import type { SchoolItem } from "../plan/school.js";

/** The first day of the month before the day's, and the last of the day's month: the sessions PlanMaker reads. */
export function sessionSpan(date: string): { from: string; to: string } {
  const [y, m] = date.split("-").map(Number) as [number, number];
  const from = new Date(Date.UTC(y, m - 2, 1)).toISOString().slice(0, 10);
  const to = new Date(Date.UTC(y, m, 0)).toISOString().slice(0, 10);
  return { from, to };
}

/** make_plan's groups as the app writes them (PlanGroup's Codable keys), so the phone reads them back. */
export function planParams(centre: string, draft: PlanDraft) {
  return {
    p_centre: centre,
    p_class: draft.classID,
    p_date: draft.date,
    p_groups: draft.groups.map((g) => JSON.parse(JSON.stringify(g))) as Json,
    p_subjects: Object.fromEntries(draft.groups.map((g) => [String(g.number), g.subject])) as Json,
    p_items: draft.lines.map((l) => ({
      group_no: l.groupNo,
      kind: l.kind,
      words: l.words,
      ...(l.studentID ? { student_id: l.studentID } : {}),
      ...(l.skillID ? { skill_id: l.skillID } : {}),
    })) as Json,
  };
}

/** The record through the service role (D83): every read and write names the job's centre. */
export function makeRecordSource(url: string, serviceKey: string): PlanRecordSource {
  const client = createClient<Database>(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const must = <T>(r: { data: T; error: { message: string } | null }, what: string): NonNullable<T> => {
    if (r.error || r.data === null || r.data === undefined) throw new Error(`${what}: ${r.error?.message ?? "nothing"}`);
    return r.data as NonNullable<T>;
  };
  // A name step retaken after a crash writes again: each write first finds what an earlier try wrote (the chapter by
  // its name in any case, the skill by its name), so a student never gets a second "Fractions".
  const addSkill = async (centre: string, chapter: string, student: string, name: string): Promise<string> => {
    const skills = await client.from("skills").select("id, name, position").eq("centre_id", centre).eq("chapter_id", chapter).order("position", { ascending: false });
    const rows = must(skills, "skills");
    const found = rows.find((s) => s.name === name);
    if (found) return found.id;
    const made = await client.from("skills").insert({ centre_id: centre, chapter_id: chapter, student_id: student, position: (rows[0]?.position ?? 0) + 1, name }).select("id").single();
    return must(made, "skills").id;
  };
  const existingPlan = async (centre: string, classId: string, date: string) => {
    const r = await client.from("plans").select("id").eq("centre_id", centre).eq("class_id", classId).eq("date", date).maybeSingle();
    if (r.error) throw new Error(`plans: ${r.error.message}`);
    return r.data?.id ?? null;
  };
  return {
    existingPlan,
    async read(centre, classId, date) {
      const span = sessionSpan(date);
      const [room, members, sessions, items, plan, briefs] = await Promise.all([
        client.from("classes").select("id, subject, plan_groups, plan_pattern").eq("centre_id", centre).eq("id", classId).single(),
        client.from("students").select("id, name, class_level, track_status, next_step, gender, school_id").eq("centre_id", centre).eq("class_id", classId).is("archived_at", null),
        client
          .from("attendance_sessions")
          .select("class_id, date, closed_at, attendance_marks(student_id, status)")
          .eq("centre_id", centre)
          .gte("date", span.from)
          .lte("date", span.to),
        client.from("school_items").select("kind, student_id, school_id, class_level, date, end_date, subject, title, window_days").eq("centre_id", centre),
        existingPlan(centre, classId, date),
        client.from("artefacts").select("title").eq("centre_id", centre).eq("kind", "brief"),
      ]);
      const classroom = must(room, "classes");
      const students = must(members, "students");
      const ids = students.map((s) => s.id);
      const [chapters, skills] = ids.length
        ? await Promise.all([
            client.from("chapters").select("id, student_id, subject, position, name").eq("centre_id", centre).in("student_id", ids).order("position"),
            client.from("skills").select("id, student_id, chapter_id, position, name, state, state_at").eq("centre_id", centre).in("student_id", ids).order("position"),
          ])
        : [{ data: [], error: null }, { data: [], error: null }];
      const byStudent = <T extends { student_id: string }>(rows: T[]) => {
        const out: Record<string, T[]> = {};
        for (const row of rows) (out[row.student_id] ??= []).push(row);
        return out;
      };
      const read: PlanRead = {
        classroom: {
          id: classroom.id,
          ...(classroom.subject ? { subject: classroom.subject } : {}),
          ...(classroom.plan_groups ? { planGroups: classroom.plan_groups } : {}),
          patterns: (classroom.plan_pattern ?? {}) as PlanRead["classroom"]["patterns"],
        },
        members: students.map((s) => ({
          id: s.id,
          name: s.name,
          ...(s.class_level ? { classLevel: s.class_level as ClassLevel } : {}),
          trackStatus: s.track_status as TrackStatus,
          ...(s.next_step ? { nextStep: s.next_step as NextStep } : {}),
          ...(s.gender ? { gender: s.gender } : {}),
          schoolId: s.school_id,
        })),
        chapters: Object.fromEntries(
          Object.entries(byStudent(must(chapters, "chapters"))).map(([k, rows]) => [k, rows.map(({ id, subject, position, name }) => ({ id, subject, position, name }))]),
        ),
        skills: Object.fromEntries(
          Object.entries(byStudent(must(skills, "skills"))).map(([k, rows]) => [
            k,
            rows.map((r) => ({ id: r.id, chapterID: r.chapter_id, position: r.position, name: r.name, state: r.state as SkillState, stateAt: r.state_at })),
          ]),
        ),
        sessions: must(sessions, "attendance_sessions").map(
          (s): Session => ({
            classID: s.class_id ?? "",
            date: s.date,
            marks: Object.fromEntries((s.attendance_marks ?? []).map((m) => [m.student_id, m.status as "present" | "absent"])),
          }),
        ),
        items: must(items, "school_items").map(
          (i): SchoolItem => ({
            kind: i.kind as SchoolItem["kind"],
            studentId: i.student_id,
            schoolId: i.school_id,
            classLevel: i.class_level,
            date: i.date,
            endDate: i.end_date,
            subject: i.subject,
            title: i.title,
            windowDays: i.window_days,
          }),
        ),
        closed: must(sessions, "attendance_sessions").some((s) => s.class_id === classId && s.date === date && s.closed_at !== null),
        existingPlan: plan,
        briefChapters: must(briefs, "artefacts").map((a) => (a.title.startsWith("Your brief · ") ? a.title.slice("Your brief · ".length) : a.title)),
      };
      return read;
    },
    async addChapter(centre, student, subject, name, skill) {
      const chapters = await client.from("chapters").select("id, name, position").eq("centre_id", centre).eq("student_id", student).eq("subject", subject).order("position", { ascending: false });
      const rows = must(chapters, "chapters");
      const found = rows.find((c) => c.name.toLowerCase() === name.toLowerCase());
      if (found) return await addSkill(centre, found.id, student, skill);
      const chapter = must(await client.from("chapters").insert({ centre_id: centre, student_id: student, subject, position: (rows[0]?.position ?? 0) + 1, name }).select("id").single(), "chapters");
      const made = await client.from("skills").insert({ centre_id: centre, chapter_id: chapter.id, student_id: student, position: 1, name: skill }).select("id").single();
      return must(made, "skills").id;
    },
    addSkill,
    async makePlan(centre, draft) {
      const made = must(await client.rpc("make_plan", planParams(centre, draft)), "make_plan") as { plan_id: string };
      return made.plan_id;
    },
  };
}
