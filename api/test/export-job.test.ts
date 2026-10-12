import { expect, test } from "bun:test";
import { fakeClaude } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import type { StudentRecord } from "../src/export/record.js";
import { fakeClock, fakeJobsDb } from "../src/jobs/db-fake.js";
import { type ExportSource, exportJob } from "../src/jobs/kinds/export.js";
import type { Job, StepContext } from "../src/jobs/types.js";
import { exportPdf, phoneWords } from "../src/pdf/export.js";
import { renderPdf } from "../src/pdf/render.js";
import { str } from "../src/pdf/typst.js";

// The student's export (D92; P18-Export-File): everything kept about a student, for the parent, as a PDF in `exports`.
const CENTRE = "c0000000-0000-4000-8000-0000000000aa";
const HEMANTH = "a0000000-0000-4000-8000-000000000001";
const CENTRE_META = { name: "Bright Minds Tuition", tutor: "Meera Nair", phone: "+919845012345" };
function record(over: Partial<StudentRecord> = {}): StudentRecord {
  return {
    student: { id: HEMANTH, name: "Hemanth Reddy", gender: "male", classLevel: "10", board: "cbse", school: "Vidya Niketan", joined: "2026-06-01T10:00:00+05:30", parentName: "Lakshmi Reddy", parentPhone: "+919380260871", language: "hi", monthlyFee: 1200 },
    batch: { name: "Class 10 Maths", days: [1, 2, 3, 4, 5], start: "17:00:00", end: "18:30:00" },
    consent: [{ kind: "given", how: "in_person", at: "2026-10-01T10:00:00+05:30", phone: "+919380260871" }],
    attendance: [
      { date: "2026-09-28", status: "absent" },
      { date: "2026-09-29", status: "present" },
      { date: "2026-10-02", status: "absent" },
    ],
    fees: [{ period: "2026-10-01", amount: 1200, status: "due", reminded: ["2026-10-06"] }, { period: "2026-09-01", amount: 1200, status: "paid", paidAt: "2026-09-04T10:00:00+05:30", paidMethod: "upi", reminded: [] }],
    chapters: [{ subject: "Mathematics", name: "Real numbers", position: 1, states: ["secure", "secure", "secure", "secure"] }, { subject: "Mathematics", name: "Polynomials", position: 2, states: ["secure", "secure", "secure", "practising"] }],
    checks: [{ at: "2026-10-05T12:00:00+05:30", correct: true }, { at: "2026-10-06T12:00:00+05:30", correct: false }],
    marks: [{ subject: "Mathematics", test: "Unit test 2", date: "2026-10-09", score: 14, max: 25 }],
    homework: [{ given: "2026-10-05", title: "Polynomials · sheet 1", status: "done" }],
    messages: [{ at: "2026-10-06T09:00:00+05:30", kind: "reminder", channel: "whatsapp_link", body: null }],
    made: [{ at: "2026-10-11T18:00:00+05:30", kind: "note", language: "hi", words: "हेमंत ने इस हफ्ते भिन्न सीखे।" }],
    ...over,
  };
}
const note = (day: string, language: string, words: string) => ({ at: `${day}T18:00:00+05:30`, kind: "note", language, words });

test("the export renders a Hindi message and pages", async () => {
  const rec = record({ made: Array.from({ length: 30 }, (_, i) => note(`2026-0${(i % 9) + 1}-04`, "hi", "हेमंत ने इस हफ्ते भिन्न सीखे। अगले हफ्ते दशमलव।")) });
  const { pages } = await renderPdf(exportPdf(rec, CENTRE_META, "2026-10-13"));
  expect(pages).toBeGreaterThan(1);
});

test("the file holds each section the record has and none it does not", () => {
  const src = exportPdf(record({ marks: [] }), CENTRE_META, "2026-10-13");
  for (const s of ["About him", "Consent", "Attendance", "Fees", "His record", "Homework", "Messages to his parent", "Made about him"]) expect(src).toContain(str(s));
  expect(src).not.toContain("School marks");
  expect(exportPdf(record(), CENTRE_META, "2026-10-13")).toContain(str("School marks"));
});

test("the head, the parent's line and the foot are the board's", () => {
  const src = exportPdf(record(), CENTRE_META, "2026-10-13");
  expect(src).toContain(str("Hemanth Reddy"));
  expect(src).toContain(str("Everything Bright Minds Tuition keeps about him, as of Tue 13 Oct 2026"));
  expect(src).toContain(str("Meera Nair · +91 98450 12345"));
  expect(src).toContain(str("This file is for Hemanth’s parent. It lists what is kept about him in Tutor Central, the app his tutor uses. To correct or remove anything, ask Meera Nair; deleting Hemanth removes all of it."));
  expect(src).toContain("Page #counter(page).display() of");
  expect(src).toContain(str("Lakshmi Reddy agreed, in person, for his own notes, marking and messages"));
  expect(src).toContain(str("Secure, 4 of 4 skills"));
  expect(src).toContain(str("3 of 4 secure, 1 practising"));
  expect(src).toContain(str("₹1,200 · due · reminded Tue 6 Oct"));
  expect(src).toContain(str("₹1,200 · paid by UPI on Fri 4 Sep"));
  expect(src).toContain(str("1 of 3 classes"));
});

test("the pronoun follows the student's gender, else the name", () => {
  const her = exportPdf(record({ student: { ...record().student, name: "Riya Shah", gender: "female" } }), CENTRE_META, "2026-10-13");
  expect(her).toContain(str("About her"));
  expect(her).toContain(str("Messages to her parent"));
  const unset = exportPdf(record({ student: { ...record().student, name: "Riya Shah", gender: undefined } }), CENTRE_META, "2026-10-13");
  expect(unset).toContain(str("About Riya"));
  expect(unset).toContain(str("Riya’s record"));
});

test("an Indian number reads as the board writes it", () => {
  expect(phoneWords("+919845012345")).toBe("+91 98450 12345");
  expect(phoneWords("+447700900123")).toBe("+447700900123");
});

function store(rec: StudentRecord | null) {
  const uploads: { bucket: string; path: string; head: string }[] = [];
  const reads: string[] = [];
  const s: ExportSource & { uploads: typeof uploads; reads: string[] } = {
    uploads,
    reads,
    async student(centre) {
      reads.push(centre);
      return rec;
    },
    async centre(centre) {
      reads.push(centre);
      return CENTRE_META;
    },
    async upload(bucket, path, bytes) {
      uploads.push({ bucket, path, head: new TextDecoder("latin1").decode(bytes.slice(0, 5)) });
    },
  };
  return s;
}
const ctx = (): StepContext => {
  const clock = fakeClock(Date.parse("2026-10-13T05:00:00Z"));
  return { db: fakeDb(), jobs: fakeJobsDb(clock), claude: fakeClaude({}), clock, requestId: "r1", worker: "w1" };
};
const job = (input: Record<string, unknown> = { student_id: HEMANTH }): Job => ({ id: "job-1", centreId: CENTRE, kind: "export", attempts: 1, step: {}, input, leaseUntil: "" });

test("the export job uploads under the centre and the student and is done with its path", async () => {
  const s = store(record());
  const out = await exportJob(s).step(job(), ctx());
  expect(s.uploads).toEqual([{ bucket: "exports", path: `${CENTRE}/${HEMANTH}/job-1.pdf`, head: "%PDF-" }]);
  expect(out).toMatchObject({ kind: "done", result: { path: `${CENTRE}/${HEMANTH}/job-1.pdf`, pages: expect.any(Number), made_at: "2026-10-13T05:00:00.000Z" } });
});

test("a student of another centre is never read: the job's centre names every read", async () => {
  const s = store(record());
  await exportJob(s).step(job(), ctx());
  expect(s.reads.every((c) => c === CENTRE)).toBe(true);
  const gone = store(null);
  expect(await exportJob(gone).step(job(), ctx())).toMatchObject({ kind: "fail", error: { reason: "not_found" }, retry: false });
  expect(gone.uploads).toEqual([]);
});

test("a message the log kept with its words gives its words; one without, its day and kind", () => {
  const src = exportPdf(
    record({ messages: [{ at: "2026-10-07T09:00:00+05:30", kind: "note", channel: "whatsapp_link", body: "नमस्ते, हेमंत ने इस हफ्ते…" }, { at: "2026-10-06T09:00:00+05:30", kind: "reminder", channel: "copied", body: null }] }),
    CENTRE_META,
    "2026-10-13",
  );
  expect(src).toContain(str("Weekly note, on WhatsApp\nनमस्ते, हेमंत ने इस हफ्ते…"));
  expect(src).toContain(str("Fee reminder, copied"));
});
