import { createClient } from "@supabase/supabase-js";
import type { Database, Json } from "../generated/database.js";
import type { PlanRead, PlanRecordSource } from "./kinds/plan.js";
import type { GapReport, PrepItem } from "../plan/exam-prep.js";
import type { ClassLevel, NextStep, PlanDraft, Session, SkillState, TrackStatus } from "../plan/types.js";
import type { OutboxDb } from "../push/db.js";
import { settingsOf } from "../reminders/settings.js";

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

/** The record through the service role (D83): every read and write names the job's centre. The outbox queues the plan's
 *  pushes. */
export function makeRecordSource(url: string, serviceKey: string, outbox?: OutboxDb): PlanRecordSource {
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
    const r = await client.from("plans").select("id, session_id").eq("centre_id", centre).eq("class_id", classId).eq("date", date).maybeSingle();
    if (r.error) throw new Error(`plans: ${r.error.message}`);
    return r.data ? { id: r.data.id, closed: r.data.session_id !== null } : null;
  };
  return {
    existingPlan,
    async read(centre, classId, date) {
      const span = sessionSpan(date);
      const [room, members, sessions, items, plan, briefs, exams] = await Promise.all([
        client.from("classes").select("id, name, subject, plan_groups, plan_pattern, meeting_days, start_time, end_time").eq("centre_id", centre).eq("id", classId).single(),
        client.from("students").select("id, name, class_level, track_status, next_step, gender, school_id").eq("centre_id", centre).eq("class_id", classId).is("archived_at", null),
        client
          .from("attendance_sessions")
          .select("class_id, date, closed_at, attendance_marks(student_id, status)")
          .eq("centre_id", centre)
          .gte("date", span.from)
          .lte("date", span.to),
        client.from("school_items").select("id, kind, student_id, school_id, class_level, date, end_date, subject, title, portions, received_at, window_days").eq("centre_id", centre),
        existingPlan(centre, classId, date),
        client.from("artefacts").select("title").eq("centre_id", centre).eq("kind", "brief"),
        client.from("artefacts").select("id, kind, student_id, school_item_id, content, created_at").eq("centre_id", centre).in("kind", ["mock", "gap_report"]).not("school_item_id", "is", null).order("created_at"),
      ]);
      const classroom = must(room, "classes");
      const students = must(members, "students");
      const ids = students.map((s) => s.id);
      const [chapters, skills] = ids.length
        ? await Promise.all([
            client.from("chapters").select("id, student_id, subject, position, name, ladder").eq("centre_id", centre).in("student_id", ids).order("position"),
            client.from("skills").select("id, student_id, chapter_id, position, name, state, state_at").eq("centre_id", centre).in("student_id", ids).order("position"),
          ])
        : [{ data: [], error: null }, { data: [], error: null }];
      const byStudent = <T extends { student_id: string }>(rows: T[]) => {
        const out: Record<string, T[]> = {};
        for (const row of rows) (out[row.student_id] ??= []).push(row);
        return out;
      };
      // The mock made for each exam, and each member's gap report used for an exam (PlanMaker.examArtefacts).
      const mocks: Record<string, string> = {};
      const gapReports: Record<string, GapReport> = {};
      for (const a of must(exams, "artefacts")) {
        const item = a.school_item_id as string;
        if (a.kind === "mock") mocks[item] ??= a.id;
        const content = a.content as { used_at?: string | null; days?: { line: string }[]; by_skill?: { skill: string; right: number; of: number }[] };
        if (a.kind === "gap_report" && a.student_id && ids.includes(a.student_id) && content.used_at && !gapReports[a.student_id]) {
          gapReports[a.student_id] = { schoolItemID: item, days: content.days ?? [], bySkill: content.by_skill ?? [] };
        }
      }
      const read: PlanRead = {
        classroom: {
          id: classroom.id,
          ...(classroom.subject ? { subject: classroom.subject } : {}),
          ...(classroom.plan_groups ? { planGroups: classroom.plan_groups } : {}),
          patterns: (classroom.plan_pattern ?? {}) as PlanRead["classroom"]["patterns"],
          name: classroom.name,
          meetingDays: classroom.meeting_days,
          start: classroom.start_time,
          end: classroom.end_time,
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
          Object.entries(byStudent(must(chapters, "chapters"))).map(([k, rows]) => [
            k,
            rows.map(({ id, subject, position, name, ladder }) => ({ id, subject, position, name, ...(ladder ? { ladder } : {}) })),
          ]),
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
        ),
        closed: must(sessions, "attendance_sessions").some((s) => s.class_id === classId && s.date === date && s.closed_at !== null),
        existingPlan: plan,
        briefChapters: must(briefs, "artefacts").map((a) => (a.title.startsWith("Your brief · ") ? a.title.slice("Your brief · ".length) : a.title)),
        gapReports,
        mocks,
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
    async keep(centre, artefact, place, key) {
      const kept = await client.rpc("keep_artefact", {
        p_centre: centre,
        p_artefact: artefact as unknown as Json,
        p_plan: place.plan,
        p_group_no: place.groupNo,
        // A group's material names no student: null, never left out (PostgREST matches a function by the names sent).
        p_student: (place.student ?? null) as string,
        p_item_kind: place.itemKind,
        p_school_item: (place.schoolItem ?? null) as string,
        p_key: key,
      });
      return must(kept, "keep_artefact") as string;
    },
    async link(centre, plan, groupNo, itemKind, artefact) {
      const r = await client.from("plan_items").update({ artefact_id: artefact }).eq("centre_id", centre).eq("plan_id", plan).eq("group_no", groupNo).eq("kind", itemKind).is("student_id", null);
      if (r.error) throw new Error(`plan_items: ${r.error.message}`);
      const own = await client.from("plan_items").update({ artefact_id: artefact }).eq("centre_id", centre).eq("plan_id", plan).eq("group_no", groupNo).eq("kind", itemKind);
      if (own.error) throw new Error(`plan_items: ${own.error.message}`);
    },
    async mockFor(centre, schoolItem) {
      const r = await client.from("artefacts").select("id").eq("centre_id", centre).eq("kind", "mock").eq("school_item_id", schoolItem).order("created_at").limit(1).maybeSingle();
      if (r.error) throw new Error(`artefacts: ${r.error.message}`);
      return r.data?.id ?? null;
    },
    async pushUsers(centre) {
      const [members, settings] = await Promise.all([
        client.from("centre_members").select("user_id").eq("centre_id", centre),
        client.from("reminder_settings").select("user_id, class_on, class_minutes, events_on, event_lead, fees_on, fees_day, plan_ready_on, notes_ready_on").eq("centre_id", centre),
      ]);
      const ids = must(members, "centre_members").map((m) => m.user_id);
      // A member is reachable with a live token (0038's live_tokens: tokens are the user's, not a centre's).
      const reachable: string[] = [];
      for (const user of ids) {
        const tokens = await client.rpc("live_tokens", { p_user: user });
        if (tokens.error) throw new Error(`live_tokens: ${tokens.error.message}`);
        if ((tokens.data ?? []).length > 0) reachable.push(user);
      }
      const rows = must(settings, "reminder_settings");
      return reachable.map((user) => {
        const own = settingsOf(rows.find((r) => r.user_id === user) ?? null);
        return { user, planReady: own.planReadyOn, notesReady: own.notesReadyOn };
      });
    },
    async notify(centre, user, rows) {
      if (!outbox) throw new Error("no outbox");
      await outbox.replace(centre, user, [], new Date().toISOString(), rows);
    },
  };
}
