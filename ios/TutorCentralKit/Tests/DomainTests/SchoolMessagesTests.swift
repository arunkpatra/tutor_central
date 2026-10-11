import Foundation
import Testing
@testable import Domain

struct MessageCadenceTests {
    let calendar = DayHeading.india
    let wed = FakeClock.oct7at1635

    func entry(_ kind: MessageKind, daysAgo: Int) -> MessageEntry {
        MessageEntry(
            id: UUID(), kind: kind, openedAt: calendar.date(byAdding: .day, value: -daysAgo, to: wed)!, language: nil
        )
    }

    @Test func threeSuggestedThisWeekSpendTheWeek() {
        let entries = [entry(.note, daysAgo: 2), entry(.testTomorrow, daysAgo: 1), entry(.canDo, daysAgo: 0)]
        #expect(MessageCadence.suggestedCount(entries, now: wed, calendar: calendar) == 3)
        #expect(!MessageCadence.canSuggest(entries, now: wed, calendar: calendar))
        #expect(MessageCadence.canSuggest(Array(entries.prefix(2)), now: wed, calendar: calendar))
    }

    @Test func aCopiedNoteIsNotASendAndDoesNotCount() {
        let copied = MessageEntry(
            id: UUID(), kind: .note, openedAt: wed, language: .hindi, channel: .copied
        )
        let entries = [entry(.testTomorrow, daysAgo: 1), entry(.notOnTrack, daysAgo: 0), copied]
        #expect(MessageCadence.suggestedCount(entries, now: wed, calendar: calendar) == 2)
        #expect(MessageCadence.suggested(entries, now: wed, calendar: calendar).count == 2)
    }

    @Test func lastWeeksAndHandSendsDoNotCount() {
        let entries = [
            entry(.note, daysAgo: 4), entry(.reminder, daysAgo: 1), entry(.absence, daysAgo: 0),
            entry(.consent, daysAgo: 0), entry(.forwardAsk, daysAgo: 0),
        ]
        // Monday 5 October starts the week.
        #expect(MessageCadence.suggestedCount(entries, now: wed, calendar: calendar) == 0)
    }
}

struct TestTomorrowMessageTests {
    @Test func theEnglishMessageReadsAsTheBoardWrote() throws {
        let message = try TestTomorrowMessage(
            parentName: "Ramesh Kumar", studentName: "Dev Kumar", gender: .male, title: "Science unit test",
            date: #require(Day(year: 2026, month: 10, day: 8)), portions: "chapters 1 and 2",
            revise: "balancing equations",
            tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
        )
        #expect(message.text == """
        Hello Ramesh, Dev's science unit test is tomorrow (Thursday 8 October), from chapters 1 and 2. \
        This evening, let him go over balancing equations once. Thank you.

        Meera Nair
        Bright Minds Tuition
        Made with Tutor Central
        """)
    }

    @Test func withoutPortionsOrASkillTheSentencesAdapt() throws {
        let message = try TestTomorrowMessage(
            parentName: nil, studentName: "Riya Sharma", gender: nil, title: "FA2",
            date: #require(Day(year: 2026, month: 10, day: 8)), portions: nil, revise: nil, tutorName: nil,
            centreName: "Bright Minds Tuition"
        )
        #expect(message.text == """
        Hello, Riya's FA2 is tomorrow (Thursday 8 October). This evening, a short revision will help. Thank you.

        Bright Minds Tuition
        Made with Tutor Central
        """)
    }

    @Test func portionsWithChapterMarkersReadAsAList() throws {
        let message = try TestTomorrowMessage(
            parentName: "Ramesh Kumar", studentName: "Dev Kumar", gender: .male, title: "Science unit test 3",
            date: #require(Day(year: 2026, month: 10, day: 16)),
            portions: "Ch 1 Chemical reactions · Ch 2 Acids, bases and salts",
            revise: nil, tutorName: "Meera Nair", centreName: "B"
        )
        #expect(message.text.contains("from Chemical reactions and Acids, bases and salts."))
        #expect(message.text.contains("This evening, a short revision will help."))
    }

    @Test func aGirlAndAStudentWithoutAGenderTakeTheirPronoun() throws {
        let her = try TestTomorrowMessage(
            parentName: nil, studentName: "Meher Shah", gender: .female, title: "Test", date: #require(Day(
                year: 2026,
                month: 10,
                day: 8
            )),
            portions: nil, revise: "fractions", tutorName: nil, centreName: "B"
        )
        #expect(her.text.contains("let her go over fractions once."))
        let them = try TestTomorrowMessage(
            parentName: nil, studentName: "Nikhil Das", gender: nil, title: "Test", date: #require(Day(
                year: 2026,
                month: 10,
                day: 8
            )),
            portions: nil, revise: "fractions", tutorName: nil, centreName: "B"
        )
        #expect(them.text.contains("let them go over fractions once."))
    }
}

struct ForwardAskMessageTests {
    @Test func theMessageNamesTheTutorAndTheCentre() {
        let text = ForwardAskMessage.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
        #expect(text.hasPrefix("""
        Hello, this is Meera from Bright Minds Tuition. Please forward me whatever the school sends about tests, \
        portions, homework and holidays, as soon as it comes.
        """))
        #expect(text.hasSuffix("Thank you.\n\nMeera Nair\nBright Minds Tuition\nMade with Tutor Central"))
        #expect(text.storedCount <= ForwardAskMessage.limit)
    }

    @Test func withoutATutorNameTheCentreSpeaks() {
        let text = ForwardAskMessage.text(tutorName: nil, centreName: "Bright Minds Tuition")
        #expect(text.hasPrefix("Hello, this is Bright Minds Tuition. Please forward me"))
        #expect(text.hasSuffix("Thank you.\n\nBright Minds Tuition\nMade with Tutor Central"))
    }
}

struct MarkRulesTests {
    func mark(_ test: String, _ score: Int, _ max: Int, daysAgo: Int, subject: String = "Mathematics") -> MarkRecord {
        MarkRecord(
            id: UUID(), studentID: UUID(), subject: subject, test: test,
            date: Day(year: 2026, month: 10, day: 7)!.adding(days: -daysAgo, calendar: DayHeading.india), score: score,
            max: max, photoPath: nil, schoolItemID: nil, artefactID: nil, questions: nil
        )
    }

    @Test func belowUsualNeedsTwoEarlierMarksInTheSubjectAndTenPointsUnderTheirMean() {
        let earlier = [mark("Unit test 1", 19, 25, daysAgo: 44), mark("FA1", 18, 25, daysAgo: 80)] // mean 74%
        #expect(MarkRules.belowUsual(mark("Unit test 2", 14, 25, daysAgo: 9), earlier: earlier)) // 56%
        #expect(!MarkRules.belowUsual(mark("Unit test 2", 17, 25, daysAgo: 9), earlier: earlier)) // 68%
        #expect(!MarkRules.belowUsual(mark("Unit test 2", 10, 25, daysAgo: 9), earlier: [earlier[0]]))
        #expect(!MarkRules.belowUsual(mark("Unit test 2", 10, 25, daysAgo: 9, subject: "Science"), earlier: earlier))
        #expect(!MarkRules.belowUsual(mark("Unit test 2", 10, 25, daysAgo: 90), earlier: earlier)) // before them
    }

    @Test func theLineReadsTheScoreOfTheMax() {
        #expect(mark("Unit test 2", 14, 25, daysAgo: 9).line == "14 of 25")
    }
}

struct GapTalliesTests {
    @Test func talliesGroupTheMarkingBySkillInTheMocksOrder() {
        let tallies = GapTallies.bySkill(.markedFixture, mock: .fixture)
        #expect(tallies.map(\.skill) == [
            "Spot a chemical change", "Write a word equation", "Balance a chemical equation",
            "Name the types of reactions",
        ])
        #expect(tallies.map(\.right) == [4, 3, 3, 4] && tallies.map(\.of) == [4, 4, 10, 7])
        #expect(GapTallies.weakest(tallies, count: 2) == ["Balance a chemical equation", "Name the types of reactions"])
    }

    @Test func aQuestionTheMarkingMissedCountsNothing() {
        let marking = CheckResult(questions: Array(CheckResult.markedFixture.questions.dropLast()), summary: "")
        let tallies = GapTallies.bySkill(marking, mock: .fixture)
        #expect(tallies.first { $0.skill == "Balance a chemical equation" }?.of == 10)
    }
}

struct SchemeSourceMockTests {
    @Test func aMockSchemeIsValid() {
        #expect(SchemeSource.mock(generationID: UUID(), artefactID: UUID()).isValid)
    }
}

extension MockContent {
    /// The board's mock: Spot 4, Word 4, Balance 10, Types 7 marks, first seen in that order; 25 in all.
    static let fixture: MockContent = {
        let spot = "Spot a chemical change", word = "Write a word equation"
        let balance = "Balance a chemical equation", types = "Name the types of reactions"
        // Number, section, marks, skill.
        let rows: [[String]] = [
            ["1", "A", "1", spot], ["2", "A", "1", spot], ["3", "A", "1", word], ["4", "A", "1", word],
            ["5", "A", "1", balance], ["6", "B", "2", spot], ["7", "B", "2", word], ["8", "B", "2", balance],
            ["9", "B", "2", types], ["10", "B", "2", balance], ["11", "C", "5", types], ["12", "C", "5", balance],
        ]
        let sections = ["A": 1, "B": 2, "C": 5].sorted { $0.key < $1.key }.map { name, each in
            Section(name: "Section \(name)", marksEach: each, questions: rows.filter { $0[1] == name }.map { row in
                let number = Int(row[0]) ?? 0
                return Question(
                    number: number, text: "Question \(number)", marks: Int(row[2]) ?? 0, answer: "Answer \(number)",
                    skill: row[3]
                )
            })
        }
        return MockContent(
            title: "Science unit test 3", durationMinutes: 40, sections: sections,
            pattern: MockPattern(marks: 25, durationMinutes: 40), portions: [
                "Chemical reactions",
                "Acids, bases and salts",
            ],
            schoolItemID: UUID(uuidString: "66666666-6666-6666-6666-666666666661")
        )
    }()
}

extension CheckResult {
    /// The board's marking: 14 of 25.
    static let markedFixture: CheckResult = {
        let right = [1: 1, 2: 1, 3: 1, 4: 0, 5: 1, 6: 2, 7: 2, 8: 0, 9: 2, 10: 2, 11: 2, 12: 0]
        let questions = MockContent.fixture.sections.flatMap(\.questions).map { question in
            CheckResult.QuestionMark(
                number: question.number, text: question.text, note: "", marks: right[question.number] ?? 0,
                of: question.marks, changedFrom: nil
            )
        }
        return CheckResult(questions: questions, summary: "Balancing needs work.")
    }()
}

extension GapReportContent {
    static let fixture = GapReportContent(
        summary: "Spotting and word equations are secure; balancing and the types of reactions need the last two days.",
        bySkill: GapTallies.bySkill(.markedFixture, mock: .fixture),
        days: [
            DayPlan(title: "Wednesday", line: "Balancing equations: the worked example, then a set of 6"),
            DayPlan(title: "Thursday morning", line: "A short mock, Section B only · the key to read together"),
        ],
        usedAt: nil, score: 14, max: 25,
        schoolItemID: UUID(uuidString: "66666666-6666-6666-6666-666666666661")!
    )
}
