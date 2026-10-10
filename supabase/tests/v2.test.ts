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

async function bookFor(school: string, classLevel: string, subject: string, chapters: unknown[]) {
  return (
    await a
      .from("textbooks")
      .insert({ centre_id: centre, school_id: school, class_level: classLevel, subject, title: `${subject} ${classLevel}`, chapters })
      .select("id")
      .single()
  ).data!.id as string;
}
async function studentIn(school: string | null, classLevel: string | null, name: string) {
  return (await a.from("students").insert({ centre_id: centre, name, class_level: classLevel, school_id: school }).select("id").single()).data!.id as string;
}
const two = [
  { position: 1, name: "Fractions", skills: ["Compare fractions", "Add like fractions"] },
  { position: 2, name: "Decimals", skills: ["Read decimals"] },
];

test("copy_textbook_to_class copies the book to every student of that school and class and to no one else", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Copy School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s1 = await studentIn(school, "6", "C1");
  const s2 = await studentIn(school, "6", "C2");
  const other = await studentIn(school, "7", "C3");
  const { data, error } = await a.rpc("copy_textbook_to_class", { p_centre: centre, p_textbook: book });
  expect(error).toBeNull();
  expect(data).toBe(2);
  for (const s of [s1, s2]) expect((await a.from("chapters").select("id").eq("student_id", s)).data).toHaveLength(2);
  expect((await a.from("chapters").select("id").eq("student_id", other)).data).toHaveLength(0);
  const twice = await a.rpc("copy_textbook_to_class", { p_centre: centre, p_textbook: book });
  expect(twice.data).toBe(2);
  expect((await a.from("skills").select("id").eq("student_id", s1)).data).toHaveLength(3);
});

test("copy_textbooks_to_student gives a student who joins later every book of their school and class", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Later School" }).select("id").single()).data!.id;
  await bookFor(school, "6", "Mathematics", two);
  await bookFor(school, "6", "Science", [{ position: 1, name: "Food", skills: ["Sources of food"] }]);
  await bookFor(school, "7", "Mathematics", two);
  const late = await studentIn(school, "6", "Late Joiner");
  const { data, error } = await a.rpc("copy_textbooks_to_student", { p_centre: centre, p_student: late });
  expect(error).toBeNull();
  expect(data).toBe(2);
  const subjects = (await a.from("chapters").select("subject").eq("student_id", late)).data!.map((c) => c.subject).sort();
  expect(subjects).toEqual(["Mathematics", "Mathematics", "Science"]);
  const none = await a.rpc("copy_textbooks_to_student", { p_centre: centre, p_student: await studentIn(null, "6", "No School") });
  expect(none.data).toBe(0);
});

test("a recapture keeps a tutor's own chapter after the book's chapters", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Own School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "Own Chapter");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  await a.from("chapters").insert({ centre_id: centre, student_id: s, subject: "Mathematics", position: 3, name: "Tutor's extra" });
  const three = [...two, { position: 3, name: "Integers", skills: ["Order integers"] }];
  await a.from("textbooks").update({ chapters: three }).eq("id", book);
  const { error } = await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  expect(error).toBeNull();
  const rows = (await a.from("chapters").select("position, name").eq("student_id", s).order("position")).data!;
  expect(rows.map((r) => r.name)).toEqual(["Fractions", "Decimals", "Integers", "Tutor's extra"]);
});

test("close_session moves the skill states it is given and leaves the others", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "States School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "States");
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "States batch" }).select("id").single()).data!.id;
  await a.from("students").update({ class_id: cls }).eq("id", s);
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  const skills = (await a.from("skills").select("id, name").eq("student_id", s).order("position")).data!;
  const first = skills.find((k) => k.name === "Compare fractions")!.id;
  const { data: sid, error } = await a.rpc("close_session", {
    p_centre: centre, p_class: cls, p_date: "2026-10-07",
    p_marks: { [s]: "present" },
    p_checks: [{ student_id: s, skill_id: first, question: { text: "Which is bigger, 1/2 or 1/3?" }, correct: true }],
    p_homework: [{ student_id: s }],
    p_track: { [s]: { status: "on_track", reasons: [] } },
    p_states: [{ skill_id: first, state: "practising" }],
  });
  expect(error).toBeNull();
  expect(sid).toBeTruthy();
  const after = (await a.from("skills").select("name, state, state_at").eq("student_id", s)).data!;
  expect(after.find((k) => k.name === "Compare fractions")?.state).toBe("practising");
  expect(after.find((k) => k.name === "Read decimals")?.state).toBe("not_started");
  // The seven-argument call still works (the app's build 19 sends none).
  const seven = await a.rpc("close_session", {
    p_centre: centre, p_class: cls, p_date: "2026-10-08", p_marks: { [s]: "present" }, p_checks: [], p_homework: [], p_track: {},
  });
  expect(seven.error).toBeNull();
});

test("record_placement writes placement checks without a session, the states and the status; a non-member is refused", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Place School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "Placed");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  const skills = (await a.from("skills").select("id, name").eq("student_id", s)).data!;
  const id = (name: string) => skills.find((k) => k.name === name)!.id;
  const { error } = await a.rpc("record_placement", {
    p_centre: centre, p_student: s,
    p_checks: [
      { student_id: s, skill_id: id("Compare fractions"), question: { text: "Which is bigger?" }, correct: true, kind: "check" },
      { student_id: s, skill_id: id("Read decimals"), question: { text: "Read 0.5" }, correct: false },
    ],
    p_states: [{ skill_id: id("Compare fractions"), state: "secure" }, { skill_id: id("Add like fractions"), state: "secure" }],
    p_track: { status: "not_known", reasons: [] },
  });
  expect(error).toBeNull();
  const checks = (await a.from("checks").select("kind, session_id, correct").eq("student_id", s)).data!;
  expect(checks).toHaveLength(2);
  expect(checks.every((c) => c.kind === "placement" && c.session_id === null)).toBe(true);
  const states = (await a.from("skills").select("name, state").eq("student_id", s)).data!;
  expect(states.filter((k) => k.state === "secure").map((k) => k.name).sort()).toEqual(["Add like fractions", "Compare fractions"]);
  const row = (await a.from("students").select("track_status, tracked_at").eq("id", s).single()).data!;
  expect(row.track_status).toBe("not_known");
  expect(row.tracked_at).not.toBeNull();
  const b = await userClient(l, `v2-placement-${stamp}@example.com`);
  const refused = await b.rpc("record_placement", { p_centre: centre, p_student: s, p_checks: [], p_states: [], p_track: {} });
  expect(refused.error?.code).toBe("42501");
});

test("deleting a student takes their chapters, skills, checks and homework with them", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Gone School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "Gone");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  const skill = (await a.from("skills").select("id").eq("student_id", s).limit(1).single()).data!.id;
  await a.rpc("record_placement", {
    p_centre: centre, p_student: s, p_checks: [{ student_id: s, skill_id: skill, question: {}, correct: true }], p_states: [], p_track: {},
  });
  expect((await a.from("students").delete().eq("id", s)).error).toBeNull();
  for (const table of ["chapters", "skills", "checks", "homework"]) {
    expect((await a.from(table).select("id").eq("student_id", s)).data).toHaveLength(0);
  }
  expect((await a.from("textbooks").select("id").eq("id", book)).data).toHaveLength(1);
});

test("a recapture with fewer chapters moves a tutor's own chapter up behind the book's", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Shrink School" }).select("id").single()).data!.id;
  const three = [...two, { position: 3, name: "Integers", skills: ["Order integers"] }];
  const book = await bookFor(school, "6", "Mathematics", three);
  const s = await studentIn(school, "6", "Shrink");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  await a.from("chapters").insert({ centre_id: centre, student_id: s, subject: "Mathematics", position: 4, name: "Tutor's extra" });
  await a.from("textbooks").update({ chapters: [two[0]] }).eq("id", book);
  const { error } = await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  expect(error).toBeNull();
  const rows = (await a.from("chapters").select("position, name").eq("student_id", s).order("position")).data!;
  expect(rows).toEqual([{ position: 1, name: "Fractions" }, { position: 2, name: "Tutor's extra" }]);
});

test("a student moved up a class gets the new class's book, last year's chapters behind it, and Keep reaches the class", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Promotion School" }).select("id").single()).data!.id;
  const five = await bookFor(school, "5", "Mathematics", two);
  const s = await studentIn(school, "5", "Moved Up");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: five, p_student: s });
  const kept = (await a.from("skills").select("id").eq("student_id", s).eq("name", "Compare fractions").single()).data!;
  await a.from("skills").update({ state: "secure" }).eq("id", kept.id);
  await a.from("students").update({ class_level: "6" }).eq("id", s);
  const six = await bookFor(school, "6", "Mathematics", [
    { position: 1, name: "Knowing our numbers", skills: ["Compare large numbers"] },
    { position: 2, name: "Whole numbers", skills: ["The number line"] },
    { position: 3, name: "Integers", skills: ["Order integers"] },
  ]);
  const classmate = await studentIn(school, "6", "Already Six");
  const keep = await a.rpc("copy_textbook_to_class", { p_centre: centre, p_textbook: six });
  expect(keep.error).toBeNull();
  expect(keep.data).toBe(2);
  const rows = (await a.from("chapters").select("position, name").eq("student_id", s).order("position")).data!;
  expect(rows.map((r) => r.name)).toEqual(["Knowing our numbers", "Whole numbers", "Integers", "Fractions", "Decimals"]);
  expect((await a.from("skills").select("state").eq("id", kept.id).single()).data!.state).toBe("secure");
  expect((await a.from("chapters").select("id").eq("student_id", classmate)).data).toHaveLength(3);
  const again = await a.rpc("copy_textbooks_to_student", { p_centre: centre, p_student: s });
  expect(again.error).toBeNull();
  expect((await a.from("chapters").select("id").eq("student_id", s)).data).toHaveLength(5);
});

// ---- Phase 12: the plan's write, the artefact's keep, the close's done lines ----
async function batchWithTwo() {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: `Batch ${stamp}`, meeting_days: [1, 2, 3, 4, 5], start_time: "17:00", end_time: "18:30" }).select("id").single()).data!;
  const s1 = (await a.from("students").insert({ centre_id: centre, class_id: cls.id, name: "Plan One", class_level: "8" }).select("id").single()).data!;
  const s2 = (await a.from("students").insert({ centre_id: centre, class_id: cls.id, name: "Plan Two", class_level: "5" }).select("id").single()).data!;
  return { cls, s1, s2 };
}
const items = (s1: string, s2: string) => [
  { student_id: s1, group_no: 1, kind: "teach", words: "Teach: Balancing equations" },
  { student_id: s1, group_no: 1, kind: "practise", words: "Practise set 1" },
  { student_id: s1, group_no: 1, kind: "check", words: "Check 3" },
  { student_id: s1, group_no: 1, kind: "homework", words: "Homework sheet 1" },
  { student_id: s2, group_no: 2, kind: "teach", words: "Teach: Compare simple fractions" },
  { student_id: s2, group_no: 2, kind: "homework", words: "Homework sheet 1, light" },
  { student_id: null, group_no: 1, kind: "brief", words: "Your brief · Chemical reactions" },
];

test("make_plan writes the day's plan with its groups and items in one call, and a second call replaces it", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const groups = [{ group_no: 1, subject: "Science", chapter: "Chemical reactions", skill: "Balancing equations" }, { group_no: 2, subject: "Mathematics", chapter: "Parts and Wholes", skill: "Compare simple fractions" }];
  const first = await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: groups, p_subjects: { "1": "Science", "2": "Mathematics" }, p_items: items(s1.id, s2.id) });
  expect(first.error).toBeNull();
  const made = first.data as { plan_id: string; items: { id: string; student_id: string | null; group_no: number; kind: string }[] };
  expect(made.items).toHaveLength(7);
  expect(made.items.filter((i) => i.kind === "brief")[0]?.student_id).toBeNull();
  const again = await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: [groups[0]], p_subjects: { "1": "Science" }, p_items: items(s1.id, s2.id).slice(0, 4) });
  expect((again.data as { plan_id: string }).plan_id).toBe(made.plan_id);
  const rows = await a.from("plan_items").select("id").eq("plan_id", made.plan_id);
  expect(rows.data).toHaveLength(4);
  const plan = await a.from("plans").select("groups, subjects, made_at").eq("id", made.plan_id).single();
  expect((plan.data!.groups as unknown[]).length).toBe(1);
});

test("make_plan refuses a non-member, a plan for another centre's batch, and a bad item kind", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const b = await userClient(l, `v2-plan-b-${stamp}@example.com`);
  const other = (await b.rpc("create_centre", { p_name: "Other", p_whatsapp: "+919999999902" })).data as string;
  expect((await b.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: [], p_subjects: {}, p_items: [] })).error?.code).toBe("42501");
  expect((await b.rpc("make_plan", { p_centre: other, p_class: cls.id, p_date: "2026-10-07", p_groups: [], p_subjects: {}, p_items: [] })).error).not.toBeNull();
  expect((await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: [], p_subjects: {}, p_items: [{ student_id: s1.id, group_no: 1, kind: "revise" }] })).error).not.toBeNull();
  void s2;
});

test("keep_artefact writes the artefact and links the group's items of its kind; a personal keep links one student; a regenerate relinks and keeps the old", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-08", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string };
  const sheet = { kind: "sheet", source: "made", title: "Balancing equations · sheet 1", content: { title: "Balancing equations", questions: [{ number: 1, text: "Balance H2 + O2", answer: "2H2 + O2 → 2H2O" }], for_homework: true, light: false } };
  const kept = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: sheet, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" });
  expect(kept.error).toBeNull();
  const linked = await a.from("plan_items").select("student_id, artefact_id").eq("plan_id", plan.plan_id).eq("kind", "homework");
  expect(linked.data!.find((r) => r.student_id === s1.id)?.artefact_id).toBe(kept.data as string);
  expect(linked.data!.find((r) => r.student_id === s2.id)?.artefact_id).toBeNull();
  const own = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "check", source: "made", title: "Plan One's checks", content: { questions: [] } }, p_plan: plan.plan_id, p_group_no: 1, p_student: s1.id, p_item_kind: "check" });
  expect(own.error).toBeNull();
  const again = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { ...sheet, regenerated_from: kept.data }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" });
  expect(again.error).toBeNull();
  const relinked = await a.from("plan_items").select("artefact_id").eq("plan_id", plan.plan_id).eq("kind", "homework").eq("student_id", s1.id).single();
  expect(relinked.data!.artefact_id).toBe(again.data as string);
  const old = await a.from("artefacts").select("id, plan_id").eq("id", kept.data as string).single();
  expect(old.data!.plan_id).toBe(plan.plan_id);
});

test("keep_artefact refuses a non-member and a kind outside the enum, and links nothing when the row is not written", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-09", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string };
  const b = await userClient(l, `v2-keep-b-${stamp}@example.com`);
  expect((await b.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "sheet", title: "x", content: {} }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" })).error?.code).toBe("42501");
  expect((await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "poster", title: "x", content: {} }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" })).error).not.toBeNull();
  const linked = await a.from("plan_items").select("artefact_id").eq("plan_id", plan.plan_id).eq("kind", "homework");
  expect(linked.data!.every((r) => r.artefact_id === null)).toBe(true);
});

test("close_session marks the plan's done lines and links the plan; the eight-argument call still works", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-12", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string; items: { id: string; kind: string }[] };
  const done = plan.items.filter((i) => i.kind === "teach").map((i) => i.id);
  const sid = (await a.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-12", p_marks: { [s1.id]: "present", [s2.id]: "present" }, p_checks: [], p_homework: [], p_track: {}, p_states: [], p_done: done })).data as string;
  const items2 = await a.from("plan_items").select("kind, done_at").eq("plan_id", plan.plan_id);
  expect(items2.data!.filter((i) => i.kind === "teach").every((i) => i.done_at !== null)).toBe(true);
  expect(items2.data!.filter((i) => i.kind !== "teach").every((i) => i.done_at === null)).toBe(true);
  expect((await a.from("plans").select("session_id").eq("id", plan.plan_id).single()).data!.session_id).toBe(sid);
  const eight = await a.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-12", p_marks: { [s1.id]: "present" }, p_checks: [], p_homework: [], p_track: {}, p_states: [] });
  expect(eight.error).toBeNull();
});

test("a batch keeps its group count and weekday pattern; the count is 1 to 3", async () => {
  const { cls } = await batchWithTwo();
  expect((await a.from("classes").update({ plan_groups: 2, plan_pattern: { "3": { groups: 2, subjects: ["Science", "Mathematics"] } } }).eq("id", cls.id)).error).toBeNull();
  expect((await a.from("classes").update({ plan_groups: 4 }).eq("id", cls.id)).error).not.toBeNull();
  const read = await a.from("classes").select("plan_groups, plan_pattern").eq("id", cls.id).single();
  expect(read.data).toEqual({ plan_groups: 2, plan_pattern: { "3": { groups: 2, subjects: ["Science", "Mathematics"] } } });
});

test("a skipped or moved line keeps its marks", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-13", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string; items: { id: string; kind: string; student_id: string | null }[] };
  const homework = plan.items.find((i) => i.kind === "homework" && i.student_id === s1.id)!;
  expect((await a.from("plan_items").update({ skipped_at: new Date().toISOString() }).eq("id", homework.id)).error).toBeNull();
  expect((await a.from("plan_items").update({ group_no: 2, moved_from: 1 }).eq("plan_id", plan.plan_id).eq("student_id", s1.id)).error).toBeNull();
  const moved = await a.from("plan_items").select("group_no, moved_from").eq("plan_id", plan.plan_id).eq("student_id", s1.id);
  expect(moved.data!.every((r) => r.group_no === 2 && r.moved_from === 1)).toBe(true);
});

test("a group's worked example and figure link to their own lines, beside the teach lines", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const lines = [...items(s1.id, s2.id), { student_id: null, group_no: 1, kind: "worked_example", words: "Worked example" }, { student_id: null, group_no: 1, kind: "figure", words: "Figure" }];
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-14", p_groups: [], p_subjects: {}, p_items: lines })).data as { plan_id: string };
  expect(plan.plan_id).toBeDefined();
  const example = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "worked_example", title: "Balancing equations", content: { problem: "p", steps: [], slip: "s" } }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "worked_example" });
  const figure = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "figure", title: "Fraction bar", content: { figure: { kind: "fraction_bar", parts: 4, shaded: 3, label: "3/4" }, caption: "c" } }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "figure" });
  expect(example.error).toBeNull();
  expect(figure.error).toBeNull();
  const linked = await a.from("plan_items").select("kind, artefact_id").eq("plan_id", plan.plan_id).in("kind", ["worked_example", "figure", "teach"]);
  expect(linked.data!.find((r) => r.kind === "worked_example")?.artefact_id).toBe(example.data as string);
  expect(linked.data!.find((r) => r.kind === "figure")?.artefact_id).toBe(figure.data as string);
  expect(linked.data!.filter((r) => r.kind === "teach").every((r) => r.artefact_id === null)).toBe(true);
});
