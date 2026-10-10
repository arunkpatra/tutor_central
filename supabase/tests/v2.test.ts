import { beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { anonClient, type Local, local, userClient } from "./client";

let l: Local;
let a: SupabaseClient;
let centre: string;
const stamp = Date.now();

beforeAll(async () => {
  l = await local();
  a = await userClient(l, `v2-a-${stamp}@example.com`);
  const { data, error } = await a.rpc("create_centre", { p_name: "Centre V2", p_whatsapp: "+919999999901" });
  if (error) throw error;
  centre = data as string;
});

test("a V1 student reads back with V2 defaults", async () => {
  const { data, error } = await a
    .from("students")
    .insert({ centre_id: centre, name: "Old Student" })
    .select("class_level, school_id, board, message_language, consent_at, consent_how, track_status, track_reasons, track_since")
    .single();
  expect(error).toBeNull();
  expect(data).toEqual({
    class_level: null,
    school_id: null,
    board: null,
    message_language: "en",
    consent_at: null,
    consent_how: null,
    track_status: "not_known",
    track_reasons: [],
    track_since: null,
  });
});

test("class level, board, language and how consent was given are checked", async () => {
  expect((await a.from("students").insert({ centre_id: centre, name: "X", class_level: "11" })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centre, name: "X", board: "state" })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centre, name: "X", message_language: "ta" })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centre, name: "X", consent_how: "letter" })).error).not.toBeNull();
  expect((await a.from("students").insert({ centre_id: centre, name: "Y", class_level: "lkg", message_language: "kn" })).error).toBeNull();
  const agreed = await a
    .from("students")
    .insert({ centre_id: centre, name: "Agreed", consent_at: "2026-10-07T11:00:00+00:00", consent_phone: "+919811111111", consent_how: "in_person" })
    .select("consent_how")
    .single();
  expect(agreed.data).toEqual({ consent_how: "in_person" });
});

test("one textbook per school, class and subject serves two students; deleting one keeps the other's chapters", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Vidya School" }).select("id").single()).data!;
  const book = (
    await a
      .from("textbooks")
      .insert({ centre_id: centre, school_id: school.id, class_level: "5", subject: "Mathematics", title: "Maths 5" })
      .select("id")
      .single()
  ).data!;
  const dup = await a.from("textbooks").insert({ centre_id: centre, school_id: school.id, class_level: "5", subject: "Mathematics", title: "Again" });
  expect(dup.error).not.toBeNull();
  const s1 = (await a.from("students").insert({ centre_id: centre, name: "S1", class_level: "5", school_id: school.id }).select("id").single()).data!;
  const s2 = (await a.from("students").insert({ centre_id: centre, name: "S2", class_level: "5", school_id: school.id }).select("id").single()).data!;
  for (const s of [s1, s2]) {
    const ch = (
      await a
        .from("chapters")
        .insert({ centre_id: centre, student_id: s.id, textbook_id: book.id, subject: "Mathematics", position: 1, name: "Fractions" })
        .select("id")
        .single()
    ).data!;
    expect((await a.from("skills").insert({ centre_id: centre, chapter_id: ch.id, student_id: s.id, position: 1, name: "Equivalent fractions" })).error).toBeNull();
  }
  expect((await a.from("students").delete().eq("id", s1.id)).error).toBeNull();
  expect((await a.from("chapters").select("id").eq("student_id", s2.id)).data?.length).toBe(1);
  expect((await a.from("skills").select("state").eq("student_id", s2.id)).data).toEqual([{ state: "not_started" }]);
  expect((await a.from("chapters").select("id").eq("student_id", s1.id)).data).toEqual([]);
});

test("copy_textbook_chapters gives a student the book's chapters and skills once, however often it runs", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Copy School", board: "cbse" }).select("id").single()).data!;
  const chapters = [
    { position: 1, name: "Shapes", skills: ["Circles", "Squares"] },
    { position: 2, name: "Numbers", skills: ["Counting", "Tens"] },
  ];
  const book = (
    await a
      .from("textbooks")
      .insert({ centre_id: centre, school_id: school.id, class_level: "2", subject: "Mathematics", title: "Maths 2", chapters })
      .select("id, chapters")
      .single()
  ).data!;
  expect(book.chapters).toEqual(chapters);
  const st = (await a.from("students").insert({ centre_id: centre, name: "Copied", class_level: "2", school_id: school.id }).select("id").single()).data!;
  const own = (await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "English", position: 1, name: "Own chapter" }).select("id").single()).data!;
  const copy = () => a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book.id, p_student: st.id });
  expect((await copy()).error).toBeNull();
  expect((await copy()).error).toBeNull();
  const mine = await a.from("chapters").select("subject, position, name").eq("student_id", st.id).eq("textbook_id", book.id).order("position");
  expect(mine.data).toEqual([
    { subject: "Mathematics", position: 1, name: "Shapes" },
    { subject: "Mathematics", position: 2, name: "Numbers" },
  ]);
  const skills = await a.from("skills").select("name, position, state").eq("student_id", st.id).order("name");
  expect(skills.data).toEqual([
    { name: "Circles", position: 1, state: "not_started" },
    { name: "Counting", position: 1, state: "not_started" },
    { name: "Squares", position: 2, state: "not_started" },
    { name: "Tens", position: 2, state: "not_started" },
  ]);
  expect((await a.from("chapters").select("id").eq("id", own.id)).data?.length).toBe(1);
  const other = await userClient(l, `v2-copy-${stamp}@example.com`);
  expect((await other.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book.id, p_student: st.id })).error).not.toBeNull();
});

test("the ladder is a chapter per domain with its steps as skills, one per student and domain", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Young", class_level: "ukg" }).select("id").single()).data!;
  const reading = await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Reading", position: 1, name: "Reading", ladder: "reading" });
  expect(reading.error).toBeNull();
  expect((await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Reading", position: 2, name: "Again", ladder: "reading" })).error).not.toBeNull();
  expect((await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Art", position: 1, name: "Art", ladder: "drawing" })).error).not.toBeNull();
});

test("close_session writes the session, the checks, the homework and the tracking status, and a second close replaces them", async () => {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "Evening batch", meeting_days: [1, 2, 3] }).select("id").single()).data!;
  const st = (await a.from("students").insert({ centre_id: centre, name: "Closer", class_level: "4", class_id: cls.id }).select("id").single()).data!;
  const ch = (await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Mathematics", position: 1, name: "Fractions" }).select("id").single()).data!;
  const sk = (await a.from("skills").insert({ centre_id: centre, chapter_id: ch.id, student_id: st.id, position: 1, name: "Halves" }).select("id").single()).data!;
  const art = (await a.from("artefacts").insert({ centre_id: centre, kind: "sheet", source: "own", title: "My sheet" }).select("id").single()).data!;
  const plan = (await a.from("plans").insert({ centre_id: centre, class_id: cls.id, date: "2026-10-12" }).select("id").single()).data!;
  const close = (marks: object, correct: boolean) =>
    a.rpc("close_session", {
      p_centre: centre,
      p_class: cls.id,
      p_date: "2026-10-12",
      p_marks: marks,
      p_checks: [{ student_id: st.id, skill_id: sk.id, question: { text: "Half of 8?" }, correct }],
      p_homework: [{ student_id: st.id, artefact_id: art.id, status: "given" }],
      p_track: { [st.id]: { status: "on_track", reasons: ["checks"] } },
    });
  const first = await close({ [st.id]: "present" }, true);
  expect(first.error).toBeNull();
  const since = (await a.from("students").select("track_since").eq("id", st.id).single()).data!.track_since;
  expect(since).not.toBeNull();
  const second = await close({ [st.id]: "absent" }, false);
  expect(second.error).toBeNull();
  expect(second.data).toBe(first.data);
  const sid = first.data as string;
  expect((await a.from("checks").select("correct, kind").eq("session_id", sid)).data).toEqual([{ correct: false, kind: "check" }]);
  expect((await a.from("homework").select("status").eq("session_id", sid)).data).toEqual([{ status: "given" }]);
  expect((await a.from("attendance_marks").select("status").eq("session_id", sid)).data).toEqual([{ status: "absent" }]);
  expect((await a.from("students").select("track_status, track_reasons, track_since").eq("id", st.id).single()).data).toEqual({
    track_status: "on_track",
    track_reasons: ["checks"],
    track_since: since,
  });
  expect((await a.from("skills").select("last_checked_at").eq("id", sk.id).single()).data?.last_checked_at).not.toBeNull();
  const session = (await a.from("attendance_sessions").select("closed_at, plan_id").eq("id", sid).single()).data!;
  expect(session.closed_at).not.toBeNull();
  expect(session.plan_id).toBe(plan.id);
  expect((await a.from("plans").select("session_id").eq("id", plan.id).single()).data).toEqual({ session_id: sid });
});

test("close_session with attendance alone is a close", async () => {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "Alone", meeting_days: [4] }).select("id").single()).data!;
  const st = (await a.from("students").insert({ centre_id: centre, name: "Alone S", class_id: cls.id }).select("id").single()).data!;
  const r = await a.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-13", p_marks: { [st.id]: "present" }, p_checks: [], p_homework: [], p_track: {} });
  expect(r.error).toBeNull();
  expect((await a.from("checks").select("id").eq("session_id", r.data as string)).data).toEqual([]);
  expect((await a.from("attendance_sessions").select("plan_id").eq("id", r.data as string).single()).data).toEqual({ plan_id: null });
});

test("the close keeps homework given without a sheet and the placement's answers; a placement can stand without a session", async () => {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "Placed", meeting_days: [5] }).select("id").single()).data!;
  const st = (await a.from("students").insert({ centre_id: centre, name: "New one", class_level: "6", class_id: cls.id }).select("id").single()).data!;
  const ch = (await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Science", position: 1, name: "Cells" }).select("id").single()).data!;
  const sk = (await a.from("skills").insert({ centre_id: centre, chapter_id: ch.id, student_id: st.id, position: 1, name: "Parts of a cell" }).select("id").single()).data!;
  const r = await a.rpc("close_session", {
    p_centre: centre,
    p_class: cls.id,
    p_date: "2026-10-14",
    p_marks: { [st.id]: "present" },
    p_checks: [{ student_id: st.id, skill_id: sk.id, question: { text: "Name a part" }, correct: true, kind: "placement" }],
    p_homework: [{ student_id: st.id, status: "given" }],
    p_track: {},
  });
  expect(r.error).toBeNull();
  expect((await a.from("checks").select("kind").eq("session_id", r.data as string)).data).toEqual([{ kind: "placement" }]);
  expect((await a.from("homework").select("artefact_id, status").eq("session_id", r.data as string)).data).toEqual([{ artefact_id: null, status: "given" }]);
  const alone = await a.from("checks").insert({ centre_id: centre, student_id: st.id, skill_id: sk.id, question: {}, correct: false, kind: "placement" });
  expect(alone.error).toBeNull();
  const stray = await a.from("checks").insert({ centre_id: centre, student_id: st.id, skill_id: sk.id, question: {}, correct: false });
  expect(stray.error).not.toBeNull();
});

test("close_session refuses a non-member and a malformed list, and leaves nothing behind", async () => {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "Refused", meeting_days: [6] }).select("id").single()).data!;
  const other = await userClient(l, `v2-close-${stamp}@example.com`);
  expect((await other.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-15", p_marks: {}, p_checks: [], p_homework: [], p_track: {} })).error).not.toBeNull();
  const bad = await a.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-15", p_marks: {}, p_checks: {}, p_homework: [], p_track: {} });
  expect(bad.error).not.toBeNull();
  expect((await a.from("attendance_sessions").select("id").eq("class_id", cls.id)).data).toEqual([]);
});

test("syllabi: a member reads, cannot write; anonymous reads nothing; a chapter can name its syllabus", async () => {
  const sql = new (await import("bun")).SQL(l.db);
  const [row] = await sql`insert into public.syllabi (board, class_level, subject, edition, chapters)
    values ('cbse', '9', 'Test subject', '2026-27', '[{"position":1,"name":"One","skills":["a"]}]')
    on conflict (board, class_level, subject, edition) do update set subject = excluded.subject returning id`;
  await sql.close();
  const mine = await a.from("syllabi").select("board, class_level, subject").eq("subject", "Test subject");
  expect(mine.data).toEqual([{ board: "cbse", class_level: "9", subject: "Test subject" }]);
  expect((await a.from("syllabi").insert({ board: "cbse", class_level: "9", subject: "Nope", edition: "x", chapters: [] })).error).not.toBeNull();
  const upd = await a.from("syllabi").update({ subject: "Changed" }).eq("subject", "Test subject").select("id");
  expect(upd.data ?? []).toEqual([]);
  expect((await a.from("syllabi").delete().eq("subject", "Test subject").select("id")).data ?? []).toEqual([]);
  expect((await anonClient(l).from("syllabi").select("id")).data ?? []).toEqual([]);
  const st = (await a.from("students").insert({ centre_id: centre, name: "Board student", class_level: "9", board: "cbse" }).select("id").single()).data!;
  const ch = await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Test subject", position: 1, name: "One", syllabus_id: row.id });
  expect(ch.error).toBeNull();
  const nowhere = await a.from("chapters").insert({ centre_id: centre, student_id: st.id, subject: "Test subject", position: 2, name: "Two", syllabus_id: crypto.randomUUID() });
  expect(nowhere.error).not.toBeNull();
  // Reference data: leave only the boards' rows for the syllabus count test.
  const cleanup = new (await import("bun")).SQL(l.db);
  await cleanup`delete from public.syllabi where subject = 'Test subject'`;
  await cleanup.close();
});

test("school items and marks are checked and belong to the centre", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Item School" }).select("id").single()).data!;
  const ok = await a
    .from("school_items")
    .insert({ centre_id: centre, school_id: school.id, class_level: "6", kind: "exam", subject: "Science", date: "2026-11-02", portions: "Chapters 1 to 3" })
    .select("id")
    .single();
  expect(ok.error).toBeNull();
  expect((await a.from("school_items").insert({ centre_id: centre, kind: "party", date: "2026-11-02" })).error).not.toBeNull();
  expect((await a.from("artefacts").insert({ centre_id: centre, kind: "mock", title: "Science mock", school_item_id: ok.data!.id })).error).toBeNull();
  const st = (await a.from("students").insert({ centre_id: centre, name: "Marked", class_level: "6" }).select("id").single()).data!;
  expect((await a.from("marks").insert({ centre_id: centre, student_id: st.id, subject: "Science", test: "FA2", date: "2026-09-20", score: 18, max: 20 })).error).toBeNull();
  expect((await a.from("marks").insert({ centre_id: centre, student_id: st.id, subject: "Science", test: "FA2", date: "2026-09-20", score: 25, max: 20 })).error).not.toBeNull();
});

test("message_log takes the V2 kinds with a language and a body", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Noted" }).select("id").single()).data!;
  for (const kind of ["note", "can_do", "test_tomorrow", "homework", "consent"]) {
    const r = await a.from("message_log").insert({ centre_id: centre, student_id: st.id, kind, channel: "whatsapp_link", language: "kn", body: "ಈ ವಾರ" });
    expect({ kind, error: r.error }).toEqual({ kind, error: null });
  }
  expect((await a.from("message_log").insert({ centre_id: centre, student_id: st.id, kind: "note", language: "ta" })).error).not.toBeNull();
});

test("photos bucket: a member reads their centre's folder and not another's", async () => {
  const b = await userClient(l, `v2-b-${stamp}@example.com`);
  const bytes = new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xd9])], { type: "image/jpeg" });
  expect((await a.storage.from("photos").upload(`${centre}/textbooks/one.jpg`, bytes)).error).toBeNull();
  expect((await b.storage.from("photos").download(`${centre}/textbooks/one.jpg`)).error).not.toBeNull();
  expect((await b.storage.from("photos").upload(`${centre}/textbooks/two.jpg`, bytes)).error).not.toBeNull();
  expect((await b.storage.from("photos").remove([`${centre}/textbooks/one.jpg`])).data ?? []).toEqual([]);
  expect((await a.storage.from("photos").download(`${centre}/textbooks/one.jpg`)).error).toBeNull();
  expect((await anonClient(l).storage.from("photos").download(`${centre}/textbooks/one.jpg`)).error).not.toBeNull();
  expect((await a.storage.from("photos").upload(`not-a-centre/one.jpg`, bytes)).error).not.toBeNull();
  expect((await a.storage.from("photos").remove([`${centre}/textbooks/one.jpg`])).error).toBeNull();
});

test("the V2 kinds share a monthly allowance; a personal kind needs the student's consent; V1 kinds keep their daily rule", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Allowed" }).select("id").single()).data!;
  const start = (kind: string, student?: string) =>
    a.rpc("start_ai_generation", { p_centre: centre, p_kind: kind, p_input: {}, p_model: "claude-haiku-5-5", ...(student ? { p_student: student } : {}) });
  expect((await start("sheet")).error).toBeNull();
  for (const kind of ["note", "can_do", "test_tomorrow", "gap_report"]) {
    expect({ kind, message: (await start(kind, st.id)).error?.message }).toEqual({ kind, message: "ai_consent_missing" });
  }
  expect((await start("note")).error?.message).toContain("ai_consent_missing");
  await a.from("students").update({ consent_at: new Date().toISOString(), consent_phone: "+919999999902", consent_how: "call" }).eq("id", st.id);
  expect((await start("note", st.id)).error).toBeNull();
  const sql = new (await import("bun")).SQL(l.db);
  try {
    await sql`insert into public.ai_generations (centre_id, kind, input, model, status)
              select ${centre}::uuid, 'sheet', '{}', 'claude-haiku-5-5', 'ok' from generate_series(1, 598)`;
    // Last month's calls do not count against this month.
    await sql`insert into public.ai_generations (centre_id, kind, input, model, status, created_at)
              values (${centre}::uuid, 'sheet', '{}', 'm', 'ok', now() - interval '40 days')`;
  } finally {
    await sql.close();
  }
  const last = await start("check");
  expect(last.error?.message).toContain("ai_limit_reached");
  expect(last.error?.details).toBe("600");
  const paper = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "paper", p_input: {}, p_model: "claude-sonnet-5-5" });
  expect(paper.error).toBeNull();
});

test("the V2 allowance has a hard cap on calls started, failed ones included", async () => {
  const c = await userClient(l, `v2-cap-${stamp}@example.com`);
  const centreC = (await c.rpc("create_centre", { p_name: "Cap", p_whatsapp: null })).data as string;
  const sql = new (await import("bun")).SQL(l.db);
  try {
    await sql`insert into public.ai_generations (centre_id, kind, input, status)
              select ${centreC}::uuid, 'brief', '{}', 'failed' from generate_series(1, 899)`;
  } finally {
    await sql.close();
  }
  expect((await c.rpc("start_ai_generation", { p_centre: centreC, p_kind: "brief", p_input: {}, p_model: "m" })).error).toBeNull();
  const capped = await c.rpc("start_ai_generation", { p_centre: centreC, p_kind: "parse_school", p_input: {}, p_model: "m" });
  expect(capped.error?.message).toContain("ai_limit_reached");
  expect(capped.error?.details).toBe("600");
});

test("a second capture of the book keeps each student's progress: names follow the book, states and checks stay", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Recapture School" }).select("id").single()).data!;
  const first = [
    { position: 1, name: "Shapes", skills: ["Circles", "Squares"] },
    { position: 2, name: "Numbers", skills: ["Counting"] },
    { position: 3, name: "Money", skills: ["Coins"] },
  ];
  const book = (await a.from("textbooks").insert({ centre_id: centre, school_id: school.id, class_level: "3", subject: "Mathematics", title: "Maths 3", chapters: first }).select("id").single()).data!;
  const st = (await a.from("students").insert({ centre_id: centre, name: "Kept", class_level: "3", school_id: school.id }).select("id").single()).data!;
  const copy = () => a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book.id, p_student: st.id });
  expect((await copy()).error).toBeNull();
  const circles = (await a.from("skills").select("id").eq("student_id", st.id).eq("name", "Circles").single()).data!;
  await a.from("skills").update({ state: "secure" }).eq("id", circles.id);
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "Recapture batch" }).select("id").single()).data!;
  const closed = await a.rpc("close_session", {
    p_centre: centre, p_class: cls.id, p_date: "2026-10-16", p_marks: { [st.id]: "present" },
    p_checks: [{ student_id: st.id, skill_id: circles.id, question: { text: "A round shape?" }, correct: true }],
    p_homework: [], p_track: {},
  });
  expect(closed.error).toBeNull();
  // The tutor photographs the page again: chapter 1 renamed with a skill added, chapter 2 the same, chapter 3 gone.
  const second = [
    { position: 1, name: "Shapes and Patterns", skills: ["Circles and rings", "Squares", "Triangles"] },
    { position: 2, name: "Numbers", skills: ["Counting"] },
  ];
  expect((await a.from("textbooks").update({ chapters: second }).eq("id", book.id)).error).toBeNull();
  expect((await copy()).error).toBeNull();
  const chapters = await a.from("chapters").select("position, name").eq("student_id", st.id).order("position");
  expect(chapters.data).toEqual([{ position: 1, name: "Shapes and Patterns" }, { position: 2, name: "Numbers" }]);
  const skills = await a.from("skills").select("id, name, state").eq("student_id", st.id).order("name");
  expect(skills.data?.map((s) => [s.name, s.state])).toEqual([
    ["Circles and rings", "secure"], ["Counting", "not_started"], ["Squares", "not_started"], ["Triangles", "not_started"],
  ]);
  expect(skills.data?.find((s) => s.name === "Circles and rings")?.id).toBe(circles.id);
  expect((await a.from("checks").select("correct").eq("skill_id", circles.id)).data).toEqual([{ correct: true }]);
});

test("photo paths with the centre's id in capitals reach the centre's folder, and a photo is never overwritten", async () => {
  const bytes = new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xd9])], { type: "image/jpeg" });
  const path = `${centre.toUpperCase()}/textbooks/upper.jpg`;
  expect((await a.storage.from("photos").upload(path, bytes)).error).toBeNull();
  expect((await a.storage.from("photos").upload(path, bytes, { upsert: true })).error).not.toBeNull();
  expect((await a.storage.from("photos").remove([path])).error).toBeNull();
});
