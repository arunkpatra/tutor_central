import type { ClaudeAnswer, ClaudeClient, ClaudeRequest } from "./claude.js";
import type { CheckOutput, NoteOutput, PaperOutput, QuestionSetOutput, ScanOutput } from "./schemas.js";

export type FakeScript = { answer?: unknown; refuse?: boolean; fail?: string; delayMs?: number };

/** A ClaudeClient that answers by script, for tests and for local runs with AI_FAKE=1 (nothing costs money). Every
 *  request is recorded; an answer is still parsed by the request's schema, as the real client's is. */
export function fakeClaude(
  script: FakeScript | ((request: ClaudeRequest<unknown>) => FakeScript),
): ClaudeClient & { requests: ClaudeRequest<unknown>[] } {
  const requests: ClaudeRequest<unknown>[] = [];
  return {
    requests,
    async complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> {
      requests.push(request as ClaudeRequest<unknown>);
      const step = typeof script === "function" ? script(request as ClaudeRequest<unknown>) : script;
      if (step.delayMs) await new Promise((resolve) => setTimeout(resolve, step.delayMs));
      if (step.fail) return { kind: "failed", reason: step.fail };
      if (step.refuse) return { kind: "refused", model: request.model, tokensIn: 100, tokensOut: 0 };
      return { kind: "ok", parsed: request.schema.parse(step.answer), model: request.model, tokensIn: 812, tokensOut: 1460 };
    },
  };
}

const paper: PaperOutput = {
  title: "Quadratic equations",
  sections: [
    {
      title: "Section A",
      marksEach: 1,
      questions: [
        {
          number: 1,
          text: "Which of the following is a quadratic equation in x? (a) x² + 3 = 0 (b) 2x + 1 = 0 (c) x³ − x = 0 (d) 1/x + x = 2",
          marks: 1,
          answer: "(a) x² + 3 = 0",
        },
        { number: 2, text: "Write the discriminant of 2x² − 4x + 3 = 0.", marks: 1, answer: "−8" },
        { number: 3, text: "If one root of x² − 5x + k = 0 is 2, find k.", marks: 1, answer: "k = 6" },
        { number: 4, text: "State the nature of the roots of x² + 4x + 4 = 0.", marks: 1, answer: "Real and equal (both −2)" },
      ],
    },
    {
      title: "Section B",
      marksEach: 2,
      questions: [
        { number: 5, text: "Solve x² − 7x + 12 = 0 by factorisation.", marks: 2, answer: "x = 3 or x = 4" },
        { number: 6, text: "Find the roots of 3x² − 2√6 x + 2 = 0.", marks: 2, answer: "√6/3, twice (the roots are equal)" },
        { number: 7, text: "Find k so that x² + kx + 9 = 0 has equal roots.", marks: 2, answer: "k = 6 or k = −6" },
        { number: 8, text: "Find the roots of 2x² + x − 6 = 0 using the quadratic formula.", marks: 2, answer: "x = 3/2 or x = −2" },
      ],
    },
    {
      title: "Section C",
      marksEach: 4,
      questions: [
        {
          number: 9,
          text: "A train travels 360 km at a uniform speed. Had the speed been 5 km/h more, it would have taken 1 hour less. Find the speed of the train.",
          marks: 4,
          answer: "40 km/h",
        },
        {
          number: 10,
          text: "The product of two consecutive odd natural numbers is 195. Find the numbers.",
          marks: 4,
          answer: "13 and 15",
        },
      ],
    },
  ],
};

const homework: QuestionSetOutput = {
  title: "Cell structure",
  instructions: "Answer in two or three sentences each.",
  questions: [
    { number: 1, text: "What is a cell? Why is it called the basic unit of life?", answer: "The smallest unit that can carry out all life processes; every living thing is made of cells." },
    { number: 2, text: "Name the three main parts of a cell.", answer: "Cell membrane, cytoplasm and nucleus." },
    { number: 3, text: "Give two differences between a plant cell and an animal cell.", answer: "A plant cell has a cell wall and chloroplasts; an animal cell has neither." },
    { number: 4, text: "What is the function of the nucleus?", answer: "It controls the cell's activities and carries the genes." },
    { number: 5, text: "Why are chloroplasts found only in plant cells?", answer: "They hold chlorophyll for photosynthesis, which only plants carry out." },
  ],
};

const worksheet: QuestionSetOutput = {
  title: "Linear equations in two variables",
  instructions: "Show your working for every question.",
  questions: [
    { number: 1, text: "Write 2x + 3y = 9 in the form ax + by + c = 0.", answer: "2x + 3y − 9 = 0" },
    { number: 2, text: "Is (3, 1) a solution of x + 2y = 5?", answer: "Yes: 3 + 2 = 5" },
    { number: 3, text: "Find two solutions of x − y = 4.", answer: "(4, 0) and (5, 1), for example" },
    { number: 4, text: "Find k if (2, 1) lies on 3x + ky = 8.", answer: "k = 2" },
    { number: 5, text: "Solve x + y = 10 and x − y = 2.", answer: "x = 6, y = 4" },
    { number: 6, text: "Solve 2x + y = 7 and x − y = 2.", answer: "x = 3, y = 1" },
    { number: 7, text: "Solve 3x + 2y = 12 and x + 2y = 8.", answer: "x = 2, y = 3" },
    { number: 8, text: "The sum of two numbers is 25 and their difference is 5. Find them.", answer: "15 and 10" },
    { number: 9, text: "Two pens and three pencils cost ₹40; one pen and one pencil cost ₹16. Find each price.", answer: "Pen ₹8, pencil ₹8" },
    { number: 10, text: "Where does 2x + 3y = 6 cut the x-axis?", answer: "At (3, 0)" },
    { number: 11, text: "Where does 2x + 3y = 6 cut the y-axis?", answer: "At (0, 2)" },
    { number: 12, text: "A father is 3 times as old as his son; in 10 years he will be twice as old. Find their ages.", answer: "Father 30, son 10" },
  ],
};

const note: NoteOutput = {
  note:
    "Hello Lakshmi, a quick note on Hemanth's progress in Class 10 Maths this month. His algebra has improved a lot, and his homework has come in on time. He still loses marks to small sign errors, so some careful practice with word problems before the mock test on 17 October would help. Happy to talk any time.",
};

const scan: ScanOutput = {
  rows: [
    { name: "Aarav Mehta", phone: "9876543210", fee: 1200 },
    { name: "Diya Pillai", phone: "99887 76655", fee: 1200 },
    { name: "Dev Kumar", phone: "+91 98848 43831", fee: 1000 },
    { name: "Kavya Nair", phone: "", fee: 1200 },
    { name: "Rohan Gupta", phone: "90080 11223", fee: 1500 },
    { name: "Sneha Joshi", phone: "98450 33221", fee: 1200 },
    { name: "Ishaan Bose", phone: "97400 55667", fee: 1200 },
    { name: "Tanvi Kulkarni", phone: "99000 44556", fee: 1200 },
  ],
};

const check: CheckOutput = {
  questions: [
    { number: 1, text: "Which of these is a quadratic equation?", note: "Correct", marks: 1, of: 1 },
    { number: 2, text: "Discriminant of 2x² − 4x + 3 = 0", note: "Correct, −8", marks: 1, of: 1 },
    { number: 3, text: "k when one root is 2", note: "Correct, k = 6", marks: 1, of: 1 },
    { number: 4, text: "Nature of the roots", note: "Says real and distinct; they are equal", marks: 0, of: 1 },
    { number: 5, text: "Solve by factorisation", note: "Correct, 3 and 4", marks: 2, of: 2 },
    { number: 6, text: "Roots of 3x² − 2√6 x + 2 = 0", note: "Method right, one root missing", marks: 1, of: 2 },
    { number: 7, text: "k for equal roots", note: "Not attempted", marks: 0, of: 2 },
    { number: 8, text: "Roots by the formula", note: "Correct, 3/2 and −2", marks: 2, of: 2 },
    { number: 9, text: "The train's speed", note: "Equation right, arithmetic slip at the end", marks: 2, of: 4 },
    { number: 10, text: "Two consecutive odd numbers", note: "Correct, 13 and 15", marks: 4, of: 4 },
  ],
  summary: "Sign errors in Q4 and Q6; Q7 not attempted.",
};

/** The boards' results (P6-Result-Paper, P6-Result-ProgressNote, P6-Scan-Review, P6-Check-Result), one per kind. */
export const SAMPLE = { paper, homework, worksheet, progress_note: note, scan_register: scan, check_paper: check };

/** The kind a request is for, read from the prompt's model and words (the fake has no route to ask). */
export function kindOf(request: ClaudeRequest<unknown>): keyof typeof SAMPLE {
  if (request.images?.length) return request.text.includes("register") ? "scan_register" : "check_paper";
  if (request.text.includes("progress note")) return "progress_note";
  if (request.text.includes("homework")) return "homework";
  if (request.text.includes("worksheet")) return "worksheet";
  return "paper";
}

/** What `bun run dev` with AI_FAKE=1 answers: the boards' sample for the kind, after a short wait so the creating
 *  states show; a register photo under 1 KB (tools/samples/blank.png) reads as no rows, for the "No names found"
 *  hand run. */
export function localScript(request: ClaudeRequest<unknown>): FakeScript {
  const kind = kindOf(request);
  const blank = kind === "scan_register" && (request.images?.[0]?.base64.length ?? 0) < 1400;
  return { answer: blank ? { rows: [] } : SAMPLE[kind], delayMs: 1500 };
}
