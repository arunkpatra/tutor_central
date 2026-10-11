import Domain
import Foundation

/// The school's answers the fake gives (the API's `claude-fake.ts` samples): the board's message read as three items,
/// a date sheet's photo as two exams, the mock at the pattern's marks, the gap report, Test tomorrow in Hindi.
public extension AISamples {
    /// P10-School-Confirm's three items.
    static let schoolItems: [ParsedItem] = [
        ParsedItem(
            kind: .exam, title: "Science unit test 3", subject: "Science", date: Day(year: 2026, month: 10, day: 16),
            endDate: nil, classLevel: .eight, school: "Vidya Niketan", studentName: nil,
            portions: "Ch 1 Chemical reactions · Ch 2 Acids, bases and salts"
        ),
        ParsedItem(
            kind: .homework, title: "Maths Ex 3.2, Q1 to 10", subject: "Mathematics",
            date: Day(year: 2026, month: 10, day: 12), endDate: nil, classLevel: .eight, school: "Vidya Niketan",
            studentName: nil, portions: nil
        ),
        ParsedItem(
            kind: .holiday, title: "Dasara holidays", subject: nil, date: Day(year: 2026, month: 10, day: 19),
            endDate: Day(year: 2026, month: 10, day: 21), classLevel: nil, school: "Vidya Niketan", studentName: nil,
            portions: nil
        ),
    ]

    /// A photographed date sheet: two exams on Friday 16 October.
    static let photoItems: [ParsedItem] = [
        ParsedItem(
            kind: .exam, title: "Science unit test", subject: "Science", date: Day(year: 2026, month: 10, day: 16),
            endDate: nil, classLevel: .eight, school: nil, studentName: nil, portions: "Chapters 1 and 2"
        ),
        ParsedItem(
            kind: .exam, title: "Mathematics unit test", subject: "Mathematics", date: Day(
                year: 2026,
                month: 10,
                day: 16
            ),
            endDate: nil, classLevel: .ten, school: nil, studentName: nil, portions: "Chapters 3 and 4"
        ),
    ]

    /// P10-Mock's paper: 25 marks, three sections, each question on one skill.
    static let mockQuestions: [MockContent.Question] = [
        (
            "Which of these is a chemical change? (a) melting ice (b) rusting iron (c) breaking glass "
                + "(d) dissolving salt",
            1,
            "(b) rusting iron",
            "Spot a chemical change"
        ),
        (
            "Name the gas given off when zinc reacts with dilute hydrochloric acid.",
            1,
            "Hydrogen",
            "Spot a chemical change"
        ),
        (
            "Write the word equation for burning magnesium.",
            1,
            "Magnesium + oxygen → magnesium oxide",
            "Write a word equation"
        ),
        ("Write the word equation for iron rusting.", 1, "Iron + oxygen + water → rust", "Write a word equation"),
        ("Name the kind of reaction: CaCO₃ → CaO + CO₂.", 1, "Decomposition", "Name the types of reactions"),
        ("Balance: Al + O₂ → Al₂O₃.", 2, "4Al + 3O₂ → 2Al₂O₃", "Balance a chemical equation"),
        ("Balance: H₂ + O₂ → H₂O.", 2, "2H₂ + O₂ → 2H₂O", "Balance a chemical equation"),
        (
            "Give one example of a combination reaction, with its equation.",
            2,
            "C + O₂ → CO₂",
            "Name the types of reactions"
        ),
        (
            "Give one example of a displacement reaction, with its equation.",
            2,
            "Fe + CuSO₄ → FeSO₄ + Cu",
            "Name the types of reactions"
        ),
        (
            "Write the word equation for zinc and dilute hydrochloric acid.",
            2,
            "Zinc + hydrochloric acid → zinc chloride + hydrogen",
            "Write a word equation"
        ),
        (
            "A shiny strip of copper is left in moist air for a week. Describe what happens, name the change "
                + "and write its "
                + "equation.",
            5,
            "A green coat forms; a chemical change",
            "Spot a chemical change"
        ),
        (
            "Balance Fe + H₂O → Fe₃O₄ + H₂, showing each count.",
            5,
            "3Fe + 4H₂O → Fe₃O₄ + 4H₂",
            "Balance a chemical equation"
        ),
    ].enumerated().map { index, row in
        MockContent.Question(number: index + 1, text: row.0, marks: row.1, answer: row.2, skill: row.3)
    }

    /// The sample's questions scaled to the pattern's marks: each in proportion, at least one, the last taking the
    /// remainder (as the API's local script does).
    static func mock(_ request: MockRequest) -> MockContent {
        let total = mockQuestions.reduce(0) { $0 + $1.marks }
        let target = request.pattern.marks
        var scaled = mockQuestions.map { question in
            MockContent.Question(
                number: question.number, text: question.text, marks: max(1, question.marks * target / total),
                answer: question.answer, skill: question.skill
            )
        }
        while scaled.count > 1, scaled.dropLast().reduce(0, { $0 + $1.marks }) >= target {
            scaled.remove(at: scaled.count - 2)
        }
        if let last = scaled.popLast() {
            let rest = scaled.reduce(0) { $0 + $1.marks }
            scaled.append(MockContent.Question(
                number: last.number, text: last.text, marks: target - rest, answer: last.answer, skill: last.skill
            ))
        }
        let names = ["Section A": 1 ... 5, "Section B": 6 ... 10, "Section C": 11 ... 12]
        let sections = names.sorted { $0.key < $1.key }.compactMap { name, numbers -> MockContent.Section? in
            let questions = scaled.filter { numbers.contains($0.number) }
            guard let first = questions.first else { return nil }
            return MockContent.Section(name: name, marksEach: first.marks, questions: questions)
        }
        return MockContent(
            title: request.title, durationMinutes: request.pattern.durationMinutes, sections: sections,
            pattern: request.pattern, portions: request.portions, schoolItemID: request.schoolItemID
        )
    }

    /// P10-GapReport's summary and two days.
    static let gapSummary =
        "Spotting and word equations are secure; balancing and the types of reactions need the last two days."
    static let gapDays = [
        GapReportContent.DayPlan(
            title: "Wednesday",
            line: "Balancing equations: the worked example, then a set of 6 · Types of reactions: a sorting set"
        ),
        GapReportContent.DayPlan(
            title: "Thursday morning",
            line: "A short mock, Section B only · the key to read together"
        ),
    ]

    /// P10-TestTomorrow's Hindi message and its English.
    static let testTomorrowHindi = """
    नमस्ते रमेश जी, कल (गुरुवार 8 अक्टूबर) देव का साइंस यूनिट टेस्ट है, अध्याय 1 और 2 से। आज शाम उसे समीकरण संतुलित करना एक \
    बार दोहराने दें। धन्यवाद।
    Meera Nair
    Bright Minds Tuition
    """
    static let testTomorrowEnglish = """
    Hello Ramesh, Dev's science unit test is tomorrow (Thursday 8 October), from chapters 1 and 2. This evening, let \
    him go over balancing equations once. Thank you.
    Meera Nair
    Bright Minds Tuition
    """
}
