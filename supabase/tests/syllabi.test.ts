import { beforeAll, expect, test } from "bun:test";
import type { SupabaseClient } from "@supabase/supabase-js";
import { type Local, local, userClient } from "./client";

let a: SupabaseClient;
beforeAll(async () => {
  const l: Local = await local();
  a = await userClient(l, `syl-${Date.now()}@example.com`);
});

const SUBJECTS = ["Mathematics", "Science", "Social Science", "English"];
type Chapter = { position: number; name: string; skills: string[] };

test("every board, class and subject has a syllabus with at least eight chapters, each with at least three skills", async () => {
  for (const board of ["cbse", "karnataka"]) {
    for (const cls of ["8", "9", "10"]) {
      const { data, error } = await a.from("syllabi").select("subject, chapters, blueprint").eq("board", board).eq("class_level", cls);
      expect(error).toBeNull();
      expect({ board, cls, subjects: data?.map((r) => r.subject).sort() }).toEqual({ board, cls, subjects: [...SUBJECTS].sort() });
      for (const row of data ?? []) {
        const where = { board, cls, subject: row.subject };
        const chapters = row.chapters as Chapter[];
        expect({ ...where, chapters: chapters.length >= 8 }).toEqual({ ...where, chapters: true });
        for (const ch of chapters) expect({ ...where, chapter: ch.name, skills: ch.skills.length >= 3 }).toEqual({ ...where, chapter: ch.name, skills: true });
        expect({ ...where, blueprint: row.blueprint !== null }).toEqual({ ...where, blueprint: cls === "10" });
      }
    }
  }
});
