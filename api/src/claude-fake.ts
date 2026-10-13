import type { BatchItem, ClaudeAnswer, ClaudeClient, ClaudeRequest } from "./claude.js";
import { CheckVerdict } from "./schemas.js";
import type {
  BriefOutput,
  CheckOutput,
  ChecksOutput,
  Figure,
  FigureKind,
  FigureOutput,
  GapReportOutput,
  MockOutput,
  NoteOutput,
  PaperOutput,
  ParseSchoolOutput,
  PlacementOutput,
  PlanOutput,
  QuestionSetOutput,
  ScanOutput,
  SheetOutput,
  MessageOutput,
  ReadMarksOutput,
  TestTomorrowOutput,
  TextbookOutput,
  WorkedExampleOutput,
} from "./schemas.js";

export type FakeScript = { answer?: unknown; refuse?: boolean; truncate?: boolean; fail?: string; delayMs?: number };

/** A ClaudeClient that answers by script, for tests and for local runs with AI_FAKE=1 (nothing costs money). Every
 *  request is recorded; an answer is still parsed by the request's schema, as the real client's is. */
export function fakeClaude(
  script: FakeScript | ((request: ClaudeRequest<unknown>) => FakeScript),
  options: { batchPolls?: number } = {},
): ClaudeClient & { requests: ClaudeRequest<unknown>[]; batches: BatchItem[][] } {
  const requests: ClaudeRequest<unknown>[] = [];
  const batches: BatchItem[][] = [];
  const polls = new Map<string, number>();
  const client = {
    requests,
    batches,
    /** A batch is answered as each request would be, after `batchPolls` reads that find it running. */
    async batch(items: BatchItem[]) {
      batches.push(items);
      return { id: `batch-${batches.length}` };
    },
    async batchResults(id: string, items: BatchItem[]): Promise<"running" | Map<string, ClaudeAnswer<unknown>>> {
      const seen = (polls.get(id) ?? 0) + 1;
      polls.set(id, seen);
      if (seen <= (options.batchPolls ?? 0)) return "running";
      const answers = new Map<string, ClaudeAnswer<unknown>>();
      for (const item of items) answers.set(item.customId, await client.complete(item.request));
      return answers;
    },
    async complete<T>(request: ClaudeRequest<T>): Promise<ClaudeAnswer<T>> {
      requests.push(request as ClaudeRequest<unknown>);
      const step = typeof script === "function" ? script(request as ClaudeRequest<unknown>) : script;
      if (step.delayMs) await new Promise((resolve) => setTimeout(resolve, step.delayMs));
      const latencyMs = step.delayMs ?? 0;
      if (step.fail) return { kind: "failed", reason: step.fail, latencyMs };
      const answered = { model: request.model, tokensIn: 812, tokensOut: 1460, tokensCached: 0, tokensWritten: 0, stopReason: "end_turn", latencyMs };
      if (step.refuse) return { kind: "refused", reason: "refused", ...answered, tokensIn: 100, tokensOut: 0, stopReason: "refusal" };
      if (step.truncate) return { kind: "truncated", ...answered, tokensOut: 16000, stopReason: "max_tokens" };
      // A script written for a draft passes an agent's check (D99): a check is scripted only where a test means it.
      const answer = isCheckRequest(request) && !CheckVerdict.safeParse(step.answer).success ? PASS : step.answer;
      // An answer the schema refuses (a figure that does not add up) is refused, as the real client reports an unfit one.
      const parsed = request.schema.safeParse(answer);
      if (!parsed.success) return { kind: "refused", reason: "unfit", ...answered };
      return { kind: "ok", parsed: parsed.data, ...answered };
    },
  };
  return client;
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
  ].map(([text, answer], i) => ({ number: i + 1, text: `Balance: ${text}`, answer: answer ?? "", proof: null })),
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
  proof: null,
};

/** One spec per template, the figure boards' (P10-Figure-*). */
export const FIGURES: Record<FigureKind, { figure: Figure; caption: string }> = {
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


/** The board's message read (P10-School-Confirm): the exam, the homework and the holiday. */
const parseSchool: ParseSchoolOutput = {
  items: [
    {
      kind: "exam",
      title: "Science unit test 3",
      subject: "Science",
      date: "2026-10-16",
      endDate: null,
      classLevel: "8",
      school: "Vidya Niketan",
      studentName: null,
      portions: "Ch 1 Chemical reactions · Ch 2 Acids, bases and salts",
    },
    { kind: "homework", title: "Maths Ex 3.2, Q1 to 10", subject: "Mathematics", date: "2026-10-12", endDate: null, classLevel: "8", school: "Vidya Niketan", studentName: null, portions: null },
    { kind: "holiday", title: "Dasara holidays", subject: null, date: "2026-10-19", endDate: "2026-10-21", classLevel: null, school: "Vidya Niketan", studentName: null, portions: null },
  ],
};

/** A photographed date sheet read: two exams on one day. */
const PHOTO_ITEMS: ParseSchoolOutput = {
  items: [
    { kind: "exam", title: "Science unit test", subject: "Science", date: "2026-10-16", endDate: null, classLevel: "8", school: null, studentName: null, portions: "Chapters 1 and 2" },
    { kind: "exam", title: "Mathematics unit test", subject: "Mathematics", date: "2026-10-16", endDate: null, classLevel: "10", school: null, studentName: null, portions: "Chapters 3 and 4" },
  ],
};

/** The mock (P10-Mock): 25 marks in 40 minutes, three sections, each question on one skill. */
const mockQuestion = (number: number, text: string, marks: number, answer: string, skill: string) => ({ number, text, marks, answer, skill, proof: null });
const mock: MockOutput = {
  title: "Science unit test 3",
  durationMinutes: 40,
  sections: [
    {
      name: "Section A",
      marksEach: 1,
      questions: [
        mockQuestion(1, "Which of these is a chemical change? (a) melting ice (b) rusting iron (c) breaking glass (d) dissolving salt", 1, "(b) rusting iron", "Spot a chemical change"),
        mockQuestion(2, "Name the gas given off when zinc reacts with dilute hydrochloric acid.", 1, "Hydrogen", "Spot a chemical change"),
        mockQuestion(3, "Write the word equation for burning magnesium.", 1, "Magnesium + oxygen → magnesium oxide", "Write a word equation"),
        mockQuestion(4, "Write the word equation for iron rusting.", 1, "Iron + oxygen + water → rust", "Write a word equation"),
        mockQuestion(5, "Name the kind of reaction: CaCO₃ → CaO + CO₂.", 1, "Decomposition", "Name the types of reactions"),
      ],
    },
    {
      name: "Section B",
      marksEach: 2,
      questions: [
        mockQuestion(6, "Balance: Al + O₂ → Al₂O₃.", 2, "4Al + 3O₂ → 2Al₂O₃", "Balance a chemical equation"),
        mockQuestion(7, "Balance: H₂ + O₂ → H₂O.", 2, "2H₂ + O₂ → 2H₂O", "Balance a chemical equation"),
        mockQuestion(8, "Give one example of a combination reaction, with its equation.", 2, "C + O₂ → CO₂", "Name the types of reactions"),
        mockQuestion(9, "Give one example of a displacement reaction, with its equation.", 2, "Fe + CuSO₄ → FeSO₄ + Cu", "Name the types of reactions"),
        mockQuestion(10, "Write the word equation for zinc and dilute hydrochloric acid.", 2, "Zinc + hydrochloric acid → zinc chloride + hydrogen", "Write a word equation"),
      ],
    },
    {
      name: "Section C",
      marksEach: 5,
      questions: [
        mockQuestion(11, "A shiny strip of copper is left in moist air for a week. Describe what happens, name the change and write its equation.", 5, "A green coat forms; a chemical change; 2Cu + H₂O + CO₂ + O₂ → Cu(OH)₂·CuCO₃", "Spot a chemical change"),
        mockQuestion(12, "Balance Fe + H₂O → Fe₃O₄ + H₂, showing each count.", 5, "3Fe + 4H₂O → Fe₃O₄ + 4H₂", "Balance a chemical equation"),
      ],
    },
  ],
};

/** The gap report (P10-GapReport): the summary and the last two days. */
const gapReport: GapReportOutput = {
  summary: "Spotting and word equations are secure; balancing and the types of reactions need the last two days.",
  days: [
    { title: "Wednesday", line: "Balancing equations: the worked example, then a set of 6 · Types of reactions: a sorting set" },
    { title: "Thursday morning", line: "A short mock, Section B only · the key to read together" },
  ],
};

/** Test tomorrow in Hindi with the English beside it (P10-TestTomorrow). */
const testTomorrow: TestTomorrowOutput = {
  message:
    "नमस्ते रमेश जी, कल (गुरुवार 8 अक्टूबर) देव का साइंस यूनिट टेस्ट है, अध्याय 1 और 2 से। आज शाम उसे समीकरण संतुलित करना एक बार दोहराने दें। धन्यवाद।",
  english:
    "Hello Ramesh, Dev's science unit test is tomorrow (Thursday 8 October), from chapters 1 and 2. This evening, let him go over balancing equations once. Thank you.",
};

/** Dev's weekly note in Hindi with the English beside it (P10-Note). */
const weeklyNote: MessageOutput = {
  message:
    "नमस्ते रमेश जी, इस हफ़्ते देव ने रासायनिक समीकरण संतुलित करना सीखा। 12 में से 8 सवाल सही किए। समीकरण के आगे की संख्या बदलना अभी अभ्यास में है। घर पर रोज़ 5 समीकरण करवाएँ। अगले हफ़्ते अम्ल और क्षार शुरू होंगे। धन्यवाद।",
  english:
    "Hello Ramesh, this week Dev learnt to balance chemical equations. He got 8 of 12 questions right. Changing the numbers in front is still being practised. At home, have him do 5 equations a day. Next week we start acids and bases. Thank you.",
};

/** Sahil's can-now-do in Kannada with the English beside it (P10-CanNowDo). */
const canDo: MessageOutput = {
  message: "ನಮಸ್ಕಾರ ದೀಪಕ್ ಅವರೇ, ಈ ವಾರ ಸಾಹಿಲ್ ಚಿಕ್ಕ ವಾಕ್ಯಗಳನ್ನು ಓದಲು ಕಲಿತಿದ್ದಾನೆ. 1 ರಿಂದ 99 ರವರೆಗೆ ಎಣಿಸುತ್ತಾನೆ. ಮನೆಯಲ್ಲಿ ದಿನಕ್ಕೆ ಒಂದು ಪುಟ ಓದಿಸಿ. ಧನ್ಯವಾದಗಳು.",
  english: "Hello Deepak, this week Sahil learnt to read short sentences. He counts from 1 to 99. At home, have him read one page a day. Thank you.",
};

/** Dev's not-on-track message in Hindi with the English beside it (P10-NotOnTrack-Message). */
const notOnTrack: MessageOutput = {
  message:
    "नमस्ते रमेश जी, देव को समीकरण संतुलित करने में कठिनाई हो रही है और इस महीने वह दो बार अनुपस्थित रहा। हम इसे अगली कक्षा में उदाहरण के साथ फिर से पढ़ाएँगे। घर पर रोज़ शाम 10 मिनट अभ्यास से बहुत फ़र्क पड़ेगा। क्या हम इस हफ़्ते 5 मिनट बात कर सकते हैं? धन्यवाद।",
  english:
    "Hello Ramesh, Dev is finding balancing equations hard and was absent twice this month. We will teach it again with a worked example in the next class. Ten minutes of practice each evening at home will make a big difference. Could we talk for five minutes this week? Thank you.",
};

/** Hemanth's report card read (P14-Marks-Confirm): two subjects with a date, Hindi without one. */
const readMarks: ReadMarksOutput = {
  marks: [
    { subject: "Mathematics", test: "Unit test 2", date: "2026-09-28", score: 14, max: 25 },
    { subject: "Science", test: "Unit test 2", date: "2026-09-29", score: 18, max: 25 },
    { subject: "Hindi", test: "Unit test 2", date: null, score: 11, max: 25 },
  ],
};

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
  parse_school: parseSchool,
  mock,
  gap_report: gapReport,
  test_tomorrow: testTomorrow,
  note: weeklyNote,
  can_do: canDo,
  not_on_track: notOnTrack,
  read_marks: readMarks,
};

/** A request's system words as one text (tests read what a prompt says). */
export const systemText = (request: Pick<ClaudeRequest<unknown>, "system">) => `${request.system.shared}\n${request.system.own}`;

/** An agent's check (src/agents/check.ts) or the nightly's grade (src/evals/runner.ts), told apart by its words; the fake
 *  passes every draft (D99). */
export const isCheckRequest = (request: Pick<ClaudeRequest<unknown>, "system">) =>
  request.system.shared.startsWith("You check a draft") || request.system.shared.startsWith("You grade an answer");
export const PASS = { pass: true, findings: [] };

/** The sample for a request: a check passes, a draft gets its kind's sample. */
export const sampleFor = (request: ClaudeRequest<unknown>): unknown => (isCheckRequest(request) ? PASS : SAMPLE[kindOf(request)]);

/** The kind a request is for, read from the prompt's model and words (the fake has no route to ask). */
export function kindOf(request: ClaudeRequest<unknown>): keyof typeof SAMPLE {
  if (request.text.toLowerCase().includes("what the school sent")) return "parse_school";
  if (request.text.includes("Pattern:")) return "mock";
  if (request.text.includes("By skill:")) return "gap_report";
  if (systemText(request).includes("test is tomorrow")) return "test_tomorrow";
  if (systemText(request).includes("weekly note")) return "note";
  if (systemText(request).includes("can now do")) return "can_do";
  if (request.text.includes("Finding hard:")) return "not_on_track";
  if (request.images?.length && systemText(request).includes("report card")) return "read_marks";
  if (request.images?.length) {
    if (request.text.includes("contents page")) return "parse_textbook";
    return request.text.includes("register") ? "scan_register" : "check_paper";
  }
  if (request.text.includes("Fill the template")) return "figure";
  if (request.text.includes("worked example")) return "worked_example";
  if (systemText(request).includes("colleague's note")) return "brief";
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
  return { answer: localAnswer(request), delayMs: isCheckRequest(request) ? 500 : 1500 };
}

/** The answer the local fake gives a request: a check passes; a draft gets its kind's sample fitted to what was asked
 *  (the skills, the chapters, the template, the count, the groups, the pattern, the tutor's words). */
export function localAnswer(request: ClaudeRequest<unknown>): unknown {
  if (isCheckRequest(request)) return PASS;
  const kind = kindOf(request);
  const blank = kind === "scan_register" && (request.images?.[0]?.base64.length ?? 0) < 1400;
  if (kind === "check" || kind === "placement") return fitted(kind, quoted(request.text));
  if (kind === "figure") return FIGURES[templateOf(request.text)];
  if (kind === "sheet") return counted(Number(request.text.match(/Exactly (\d+) questions/)?.[1] ?? 8));
  if (kind === "plan") return topics(request.text);
  if (kind === "parse_school") return request.images?.length ? PHOTO_ITEMS : SAMPLE.parse_school;
  if (kind === "note") return withTutorsWords(request.text);
  if (kind === "mock") return patterned(Number(request.text.match(/Pattern: (\d+) marks/)?.[1] ?? 25));
  return blank ? { rows: [] } : SAMPLE[kind];
}

/** The weekly note, ending with the tutor's own words when the prompt carries them (Make's note, Phase 15). */
function withTutorsWords(text: string): MessageOutput {
  const words = text.match(/^The tutor adds: "(.+)"$/m)?.[1];
  if (!words) return SAMPLE.note;
  return { message: `${SAMPLE.note.message} ${words}`, english: `${SAMPLE.note.english} ${words}` };
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
    const q = SAMPLE.sheet.questions[i % SAMPLE.sheet.questions.length] ?? { number: 1, text: "", answer: "", proof: null };
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

/** The sample mock's questions scaled so the marks sum to the pattern's: each question's marks in proportion, at least
 *  one, the last taking the remainder (at least one too, so a small pattern drops questions from the end). */
function patterned(marks: number): MockOutput {
  const all = SAMPLE.mock.sections.flatMap((s) => s.questions.map((q) => ({ section: s.name, q })));
  const total = all.reduce((n, { q }) => n + q.marks, 0);
  const scaled = all.map(({ section, q }) => ({ section, q: { ...q, marks: Math.max(1, Math.floor((q.marks * marks) / total)) } }));
  while (scaled.length > 1 && scaled.slice(0, -1).reduce((n, { q }) => n + q.marks, 0) >= marks) scaled.splice(scaled.length - 2, 1);
  const last = scaled[scaled.length - 1];
  if (last) last.q.marks = marks - scaled.slice(0, -1).reduce((n, { q }) => n + q.marks, 0);
  const sections = SAMPLE.mock.sections
    .map((s) => {
      const questions = scaled.filter((x) => x.section === s.name).map((x) => x.q);
      return { name: s.name, marksEach: questions[0]?.marks ?? 1, questions };
    })
    .filter((s) => s.questions.length > 0);
  return { ...SAMPLE.mock, sections };
}
