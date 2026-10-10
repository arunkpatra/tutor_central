import type { ClaudeAnswer, ClaudeClient, ClaudeRequest } from "./claude.js";
import type {
  BriefOutput,
  CheckOutput,
  ChecksOutput,
  Figure,
  FigureKind,
  FigureOutput,
  NoteOutput,
  PaperOutput,
  PlacementOutput,
  PlanOutput,
  QuestionSetOutput,
  ScanOutput,
  SheetOutput,
  TextbookOutput,
  WorkedExampleOutput,
} from "./schemas.js";

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
      // An answer the schema refuses (a figure that does not add up) is refused, as the real client reports an unfit one.
      const parsed = request.schema.safeParse(step.answer);
      if (!parsed.success) return { kind: "refused", model: request.model, tokensIn: null, tokensOut: null };
      return { kind: "ok", parsed: parsed.data, model: request.model, tokensIn: 812, tokensOut: 1460 };
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

/** The CBSE class 5 Mathematics contents page read (P10-Textbook-Chapters): five chapters, three skills each. */
const textbook: TextbookOutput = {
  title: "Math-Magic 5",
  chapters: [
    { name: "The Fish Tale", skills: ["Compare lengths and weights", "Read large numbers", "Use units of measure"] },
    { name: "Shapes and Angles", skills: ["Name angles in shapes", "Tell right, acute and obtuse angles", "Measure turns"] },
    { name: "How Many Squares?", skills: ["Count squares in a shape", "Find the area on squared paper", "Draw shapes of equal area"] },
    { name: "Parts and Wholes", skills: ["Name a fraction of a whole", "Find equivalent fractions", "Compare simple fractions"] },
    { name: "Does it Look the Same?", skills: ["Spot mirror symmetry", "Find a shape's lines of symmetry", "Complete a symmetric figure"] },
  ],
};

/** The close's three checks on three class 8 Science skills (P10-Close). */
const checks: ChecksOutput = {
  questions: [
    { skill: "Balance a chemical equation", question: "Balance H₂ + O₂ → H₂O.", answer: "2H₂ + O₂ → 2H₂O" },
    { skill: "Name the reactants", question: "In magnesium burning in air, what are the reactants?", answer: "Magnesium and oxygen" },
    { skill: "Tell a physical from a chemical change", question: "Is ice melting a physical or a chemical change?", answer: "Physical: no new substance forms" },
  ],
};

/** The placement's questions on three class 5 Mathematics chapters (P10-Placement). */
const placement: PlacementOutput = {
  questions: [
    { chapter: "The Fish Tale", question: "Which is longer, 1 km or 800 m?", answer: "1 km" },
    { chapter: "Shapes and Angles", question: "Is the corner of a page a right angle?", answer: "Yes" },
    { chapter: "How Many Squares?", question: "A rectangle is 3 squares by 4 squares. How many squares?", answer: "12" },
  ],
};

/** Group 1's sheet (P10-Sheet, P10-Sheet-Key): eight equations to balance, with the key. */
const sheet: SheetOutput = {
  title: "Balancing equations",
  instructions: "Balance each equation",
  questions: [
    ["Mg + O2 → MgO", "2Mg + O2 → 2MgO"],
    ["H2 + Cl2 → HCl", "H2 + Cl2 → 2HCl"],
    ["Na + Cl2 → NaCl", "2Na + Cl2 → 2NaCl"],
    ["Fe + O2 → Fe2O3", "4Fe + 3O2 → 2Fe2O3"],
    ["Al + O2 → Al2O3", "4Al + 3O2 → 2Al2O3"],
    ["CH4 + O2 → CO2 + H2O", "CH4 + 2O2 → CO2 + 2H2O"],
    ["Zn + HCl → ZnCl2 + H2", "Zn + 2HCl → ZnCl2 + H2"],
    ["KClO3 → KCl + O2", "2KClO3 → 2KCl + 3O2"],
  ].map(([text, answer], i) => ({ number: i + 1, text: `Balance: ${text}`, answer: answer ?? "" })),
};

/** The worked example (P10-WorkedExample): four steps and the slip. */
const workedExample: WorkedExampleOutput = {
  problem: "Balance: Fe + O₂ → Fe₂O₃",
  steps: [
    { title: "Count each element on both sides", working: "Left: 1 Fe, 2 O. Right: 2 Fe, 3 O. Nothing matches yet." },
    {
      title: "Fix the element that appears in one place on each side first: oxygen",
      working: "O is 2 on the left and 3 on the right. The smallest number both go into is 6: put 3 before O₂ and 2 before Fe₂O₃.",
    },
    { title: "Now count iron again", working: "Right: 2 × 2 = 4 Fe. Put 4 before Fe on the left: 4Fe + 3O₂ → 2Fe₂O₃." },
    { title: "Check every element once more", working: "Fe: 4 and 4. O: 6 and 6. Balanced." },
  ],
  slip: "A common slip here: changing the small numbers inside a formula. Only the numbers in front change.",
};

/** One spec per template, the figure boards' (P10-Figure-*). */
const FIGURES: Record<FigureKind, { figure: Figure; caption: string }> = {
  number_line: { figure: { kind: "number_line", from: 0, to: 10, step: 1, start: 3, jumps: [1, 1, 1, 1] }, caption: "Start at 3, jump 4 times, land on 7." },
  fraction_bar: { figure: { kind: "fraction_bar", parts: 4, shaded: 3, label: "3/4" }, caption: "3 of 4 parts shaded: three quarters of the whole." },
  place_value: { figure: { kind: "place_value", number: 347 }, caption: "Each digit in its place, with what it is worth." },
  unit_circle: { figure: { kind: "unit_circle", angleDegrees: 60 }, caption: "The angle, the point, the two ratios read off the axes." },
  triangle: { figure: { kind: "triangle", angles: [90, 53, 37], labels: ["5", "4", "3"] }, caption: "A right angle marked, the sides named, the rule beside it." },
  labelled_cell: {
    figure: { kind: "labelled_cell", cell: "plant", labels: ["Cell wall", "Nucleus", "Vacuole", "Chloroplast", "Cell membrane"] },
    caption: "Five parts labelled, nothing more than the chapter names.",
  },
  food_chain: { figure: { kind: "food_chain", links: ["Grass", "Grasshopper", "Frog", "Snake", "Eagle"] }, caption: "The arrow points to the eater; the first link is always a plant." },
};
const figure: FigureOutput = FIGURES.fraction_bar;

/** The brief for Chemical reactions (P10-Brief). */
const brief: BriefOutput = {
  about:
    "A chemical reaction makes a new substance; a physical change does not. Students learn to spot one (gas, colour, heat, a precipitate), to write it as a word equation and then a formula equation, and to balance it so each element counts the same on both sides. Then the kinds: combination, decomposition, displacement, double displacement, and oxidation.",
  mistakes: [
    { title: "Changing the small numbers inside a formula", howToCatch: 'H₂O becomes H₂O₂ to "balance" oxygen. Only the numbers in front may change: the formula is the substance.' },
    { title: "Counting atoms once, not per molecule", howToCatch: "In 2Fe₂O₃ there are 4 Fe and 6 O. Multiply the front number into every element." },
    { title: "Calling melting or dissolving a reaction", howToCatch: "Ask: is there a new substance? Ice to water is not; iron to rust is." },
  ],
  workedExample,
  words: [
    "Reactants on the left, products on the right.",
    "A number in front multiplies the whole formula.",
    "Balanced means the same count of each element on both sides.",
  ],
};

/** A first topic for a group with no record (Group 1, class 8 Science, in October). */
const plan: PlanOutput = { groups: [{ groupNo: 1, chapter: "Chemical reactions", skill: "Balance a chemical equation" }] };

/** The boards' results (P6-Result-Paper, P6-Result-ProgressNote, P6-Scan-Review, P6-Check-Result,
 *  P10-Textbook-Chapters, P10-Sheet, P10-WorkedExample, P10-Figure-FractionBar, P10-Brief), one per kind. */
export const SAMPLE = {
  paper,
  homework,
  worksheet,
  progress_note: note,
  scan_register: scan,
  check_paper: check,
  parse_textbook: textbook,
  check: checks,
  placement,
  sheet,
  worked_example: workedExample,
  figure,
  brief,
  plan,
};

/** The kind a request is for, read from the prompt's model and words (the fake has no route to ask). */
export function kindOf(request: ClaudeRequest<unknown>): keyof typeof SAMPLE {
  if (request.images?.length) {
    if (request.text.includes("contents page")) return "parse_textbook";
    return request.text.includes("register") ? "scan_register" : "check_paper";
  }
  if (request.text.includes("Fill the template")) return "figure";
  if (request.text.includes("worked example")) return "worked_example";
  if (request.system.includes("colleague's note")) return "brief";
  if (request.text.includes("Group 1:")) return "plan";
  if (request.text.includes("a practice set on:") || request.text.includes("homework on:")) return "sheet";
  if (request.text.includes("placement")) return "placement";
  if (request.text.includes("for each skill")) return "check";
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
  if (kind === "check" || kind === "placement") return { answer: fitted(kind, quoted(request.text)), delayMs: 1500 };
  if (kind === "figure") return { answer: FIGURES[templateOf(request.text)], delayMs: 1500 };
  if (kind === "sheet") return { answer: counted(Number(request.text.match(/Exactly (\d+) questions/)?.[1] ?? 8)), delayMs: 1500 };
  if (kind === "plan") return { answer: topics(request.text), delayMs: 1500 };
  return { answer: blank ? { rows: [] } : SAMPLE[kind], delayMs: 1500 };
}

/** The names a check or placement prompt quotes, in order. */
function quoted(text: string): string[] {
  return [...text.matchAll(/"([^"]+)"/g)].map((m) => m[1] ?? "");
}

/** One question per skill or chapter the request names, the sample's where it has one: a local close or placement
 *  meets the student's own chapters, not the sample's three. */
function fitted(kind: "check" | "placement", names: string[]): ChecksOutput | PlacementOutput {
  if (kind === "check") {
    return {
      questions: names.map(
        (skill) => SAMPLE.check.questions.find((q) => q.skill === skill) ?? { skill, question: `Show me one example of: ${skill}.`, answer: "One worked example" },
      ),
    };
  }
  return {
    questions: names.map(
      (chapter) =>
        SAMPLE.placement.questions.find((q) => q.chapter === chapter) ?? { chapter, question: `What is the main idea of ${chapter}?`, answer: "The chapter's first idea" },
    ),
  };
}

/** The template a figure prompt names ("Fill the template fraction_bar."). */
function templateOf(text: string): FigureKind {
  const named = text.match(/Fill the template (\w+)/)?.[1];
  return named && named in FIGURES ? (named as FigureKind) : "fraction_bar";
}

/** The sample sheet at the asked count: cut, or its questions repeated and numbered on, so a homework of five reads five. */
function counted(count: number): SheetOutput {
  const questions = Array.from({ length: count }, (_, i) => {
    const q = SAMPLE.sheet.questions[i % SAMPLE.sheet.questions.length] ?? { number: 1, text: "", answer: "" };
    return { ...q, number: i + 1 };
  });
  return { ...SAMPLE.sheet, questions };
}

/** A first topic per group the prompt lists ("Group 2: class 5 Mathematics."). */
function topics(text: string): PlanOutput {
  const groups = [...text.matchAll(/Group (\d): class (\w+) ([^.]+)\./g)].map((m) => ({
    groupNo: Number(m[1]),
    chapter: `${m[3]} for class ${m[2]}`,
    skill: `The first idea of ${m[3]}`,
  }));
  return groups.length > 0 ? { groups } : SAMPLE.plan;
}
