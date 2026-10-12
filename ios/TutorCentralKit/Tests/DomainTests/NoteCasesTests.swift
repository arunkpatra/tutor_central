import Foundation
import Testing
@testable import Domain

/// The shared note-week cases (D80; plan/phase-18-plan.md Task 7): the week's facts (`NoteWeek.facts`), the Notes
/// card's
/// topic, a young student's can-now-do (`CanDoWeek.facts`) and which of the two a student gets, so the note day's job
/// (api/src/notes/week.ts) writes what the phone wrote.
struct NoteCaseFile: Codable {
    var cases: [NoteCase]
}

struct NoteCase: Codable {
    struct ChapterJSON: Codable {
        var id: String
        var subject: String
        var position: Int
        var name: String
        var ladder: String?
    }

    struct CheckJSON: Codable {
        var skillID: String
        var at: String
        var correct: Bool
        var isPlacement: Bool
    }

    struct SessionJSON: Codable {
        var date: String
        var mark: String
    }

    struct MarkJSON: Codable {
        var subject: String
        var test: String
        var date: String
        var score: Int
        var max: Int
    }

    struct Input: Codable {
        var student: SplitCase.StudentJSON
        var chapters: [ChapterJSON]
        var skills: [InputJSON.SkillJSON]
        var checks: [CheckJSON]
        /// The batch's sessions with this student's mark.
        var sessions: [SessionJSON]
        var marks: [MarkJSON]
        var items: [SplitCase.ItemJSON]
        /// The week's Monday and its note day.
        var from: String
        var to: String
    }

    struct RowJSON: Codable, Equatable {
        var label: String
        var fact: String
        var symbol: String
    }

    struct FactsJSON: Codable, Equatable {
        var taught: [String]
        var taughtLine: String
        var right: String?
        var practise: [String]
        var coming: [String]
        var attendance: String?
        var absentAllWeek: Bool
        var rows: [RowJSON]
    }

    struct MovedJSON: Codable, Equatable {
        var area: String
        var step: String
    }

    struct CanDoJSON: Codable, Equatable {
        var movedUp: [MovedJSON]
        var canDo: [String]
        var atHome: String
        var next: [String]
        var ladderHeading: String
        var movedUpLine: String
        var rows: [RowJSON]
    }

    struct Expected: Codable, Equatable {
        var facts: FactsJSON
        var topic: String?
        var isLadder: Bool
        var canDo: CanDoJSON?
    }

    var name: String
    var input: Input
    var expected: Expected
}

private let file = CaseJSON.read("note-cases", as: NoteCaseFile.self)

private func rows(_ rows: [NoteContent.FactRow]) -> [NoteCase.RowJSON] {
    rows.map { .init(label: $0.label, fact: $0.fact, symbol: $0.symbol) }
}

extension NoteCase.Input {
    /// The record as Domain reads it.
    func record() throws -> NoteRecord {
        let student = try Student(
            id: CaseJSON.uuid(student.id), name: student.name, classID: nil, monthlyFee: nil, parentName: nil,
            parentPhone: nil, dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil,
            classLevel: student.classLevel.flatMap { ClassLevel(rawValue: $0) },
            schoolID: student.schoolID.map(CaseJSON.uuid)
        )
        let chapters = try chapters.map {
            try Chapter(
                id: CaseJSON.uuid($0.id), subject: $0.subject, position: $0.position, name: $0.name,
                ladder: $0.ladder.flatMap(Ladder.Area.init(rawValue:))
            )
        }
        let skills = try skills.map {
            try Skill(
                id: CaseJSON.uuid($0.id), chapterID: CaseJSON.uuid($0.chapterID), position: $0.position, name: $0.name,
                state: SkillState(rawValue: $0.state) ?? .notStarted, stateAt: CaseJSON.instant($0.stateAt),
                lastCheckedAt: nil
            )
        }
        let checks = try checks.map {
            try CheckRecord(
                id: UUID(), studentID: student.id, skillID: CaseJSON.uuid($0.skillID), sessionID: nil, question: "Q",
                correct: $0.correct, at: CaseJSON.instant($0.at), isPlacement: $0.isPlacement
            )
        }
        let sessions = try sessions.map {
            try AttendanceSession(
                id: UUID(), classID: nil, date: CaseJSON.day($0.date), savedAt: Date(),
                marks: [student.id: AttendanceStatus(rawValue: $0.mark) ?? .present]
            )
        }
        let marks = try marks.map {
            try MarkRecord(
                id: UUID(), studentID: student.id, subject: $0.subject, test: $0.test, date: CaseJSON.day($0.date),
                score: $0.score, max: $0.max, photoPath: nil, schoolItemID: nil, artefactID: nil, questions: nil
            )
        }
        let items = try SplitCase.Input(
            items: items, student: self.student, chapters: [], skills: [], meetingDays: [], today: from
        ).domain().items
        return NoteRecord(
            student: student, chapters: chapters, skills: skills, checks: checks, sessions: sessions, marks: marks,
            items: items
        )
    }
}

private func week(_ input: NoteCase.Input) throws -> NoteCase.Expected {
    let calendar = DayHeading.india
    let record = try input.record()
    let (student, chapters, skills) = (record.student, record.chapters, record.skills)
    let range = try CaseJSON.day(input.from) ... CaseJSON.day(input.to)
    let facts = NoteWeek.facts(record, week: range, calendar: calendar)
    let isLadder = CanDoWeek.isLadderNote(student, chapters: chapters)
    let canDo = isLadder ? CanDoWeek.facts(chapters: chapters, skills: skills, week: range, calendar: calendar) : nil
    return .init(
        facts: .init(
            taught: facts.taught, taughtLine: facts.taughtLine, right: facts.right, practise: facts.practise,
            coming: facts.coming, attendance: facts.attendance, absentAllWeek: facts.absentAllWeek,
            rows: rows(facts.rows)
        ),
        topic: NoteWeek.topic(facts, chapters: chapters, skills: skills),
        isLadder: isLadder,
        canDo: canDo.map { made in
            .init(
                movedUp: made.movedUp.map { .init(area: $0.area.rawValue, step: $0.step) }, canDo: made.canDo,
                atHome: made.atHome, next: made.next, ladderHeading: made.ladderHeading, movedUpLine: made.movedUpLine,
                rows: rows(made.rows)
            )
        }
    )
}

/// The note-week scenarios: the week of Monday 5 to Sunday 11 October 2026, the note day Sunday.
private struct NoteCaseScenarios {
    var counter = 0

    mutating func next(_ prefix: String) -> String {
        counter += 1
        return String(format: "%@0000000-0000-4000-8000-%012d", prefix, counter)
    }

    typealias Book = (chapters: [NoteCase.ChapterJSON], skills: [InputJSON.SkillJSON])

    /// Two chapters of three skills; `states` gives each skill's state and the day it changed ("taught@2026-10-06").
    mutating func book(_ states: [String], names: [String] = ["Chemical reactions", "Acids, bases and salts"]) -> Book {
        var chapters: [NoteCase.ChapterJSON] = []
        var skills: [InputJSON.SkillJSON] = []
        let skillNames = [
            ["Balancing equations", "Types of reactions", "Rusting"], ["Naming acids", "Indicators", "Neutralisation"],
        ]
        for (index, name) in names.enumerated() {
            let chapter = NoteCase.ChapterJSON(id: next("b"), subject: "Science", position: index + 1, name: name)
            chapters.append(chapter)
            for position in 1 ... 3 {
                let place = index * 3 + position - 1
                let at = place < states.count ? states[place] : "not_started@2026-09-01"
                let parts = at.split(separator: "@").map(String.init)
                skills.append(.init(
                    id: next("d"), chapterID: chapter.id, position: position, name: skillNames[index][position - 1],
                    state: parts[0], stateAt: "\(parts[1])T11:30:00Z"
                ))
            }
        }
        return (chapters, skills)
    }

    mutating func ladder(_ reading: [String], _ numbers: [String]) -> Book {
        var chapters: [NoteCase.ChapterJSON] = []
        var skills: [InputJSON.SkillJSON] = []
        let areas: [(area: Ladder.Area, states: [String])] = [(.reading, reading), (.numbers, numbers)]
        for (index, area) in areas.enumerated() {
            let name = area.area.rawValue
            let chapter = NoteCase.ChapterJSON(
                id: next("b"), subject: name == "numbers" ? "Mathematics" : "English", position: index + 1,
                name: name.capitalized, ladder: name
            )
            chapters.append(chapter)
            for (position, step) in area.area.steps.enumerated() {
                let at = position < area.states.count ? area.states[position] : "not_started@2026-09-01"
                let parts = at.split(separator: "@").map(String.init)
                skills.append(.init(
                    id: next("d"), chapterID: chapter.id, position: position + 1, name: step, state: parts[0],
                    stateAt: "\(parts[1])T11:30:00Z"
                ))
            }
        }
        return (chapters, skills)
    }

    func input(
        _ book: Book, level: String = "8", checks: [NoteCase.CheckJSON] = [], sessions: [NoteCase.SessionJSON] = [],
        marks: [NoteCase.MarkJSON] = [], items: [SplitCase.ItemJSON] = []
    ) -> NoteCase.Input {
        .init(
            student: .init(
                id: "a0000000-0000-4000-8000-000000000001",
                name: "Dev",
                classLevel: level,
                schoolID: "f0000000-0000-4000-8000-000000000001"
            ),
            chapters: book.chapters, skills: book.skills, checks: checks, sessions: sessions, marks: marks,
            items: items,
            from: "2026-10-05", to: "2026-10-11"
        )
    }

    func check(_ skill: InputJSON.SkillJSON, _ day: String, _ correct: Bool, placement: Bool = false) -> NoteCase
        .CheckJSON {
        .init(skillID: skill.id, at: "\(day)T12:00:00Z", correct: correct, isPlacement: placement)
    }

    func sessions(_ marks: [String]) -> [NoteCase.SessionJSON] {
        let days = ["2026-10-05", "2026-10-07", "2026-10-09"]
        return zip(days, marks).map { .init(date: $0, mark: $1) }
    }

    mutating func all() -> [(name: String, input: NoteCase.Input)] {
        weekly() + coming()
    }

    mutating func taughtWeek() -> Book {
        book(["secure@2026-09-20", "taught@2026-10-06", "taught@2026-10-08", "practising@2026-09-28"])
    }

    mutating func weekly() -> [(name: String, input: NoteCase.Input)] {
        let week = taughtWeek()
        let quiet = book(["secure@2026-09-20", "practising@2026-09-28", "not_started@2026-09-01"])
        let movedOn = book(["secure@2026-09-20", "practising@2026-10-06", "revisit@2026-10-07"])
        let newChapter = book(["secure@2026-09-20", "secure@2026-09-22", "secure@2026-10-06"])
        return [
            ("a week of teaching, checks and a mark", input(
                week, checks: [
                    check(week.skills[1], "2026-10-06", true),
                    check(week.skills[1], "2026-10-08", false),
                    check(week.skills[2], "2026-10-08", true),
                    check(week.skills[0], "2026-10-01", false),
                ],
                sessions: sessions(["present", "present", "present"]),
                marks: [.init(subject: "Science", test: "Unit test 2", date: "2026-10-09", score: 14, max: 25)]
            )),
            ("two absences of three", input(week, sessions: sessions(["absent", "present", "absent"]))),
            ("absent all week teaches nothing", input(week, sessions: sessions(["absent", "absent", "absent"]))),
            ("no sessions and nothing taught", input(quiet)),
            ("wrong checks name what to practise when nothing is weak", input(
                newChapter, checks: [
                    check(newChapter.skills[2], "2026-10-07", false),
                    check(newChapter.skills[1], "2026-10-08", false),
                ]
            )),
            ("practising and revisit skills are what to practise", input(movedOn)),
            ("the next skill opens a new chapter", input(newChapter)),
            ("a placement's checks are not the week's", input(
                quiet, checks: [check(quiet.skills[1], "2026-10-06", true, placement: true)]
            )),
            ("every check right", input(
                week, checks: [check(week.skills[1], "2026-10-06", true), check(week.skills[2], "2026-10-08", true)]
            )),
        ]
    }

    mutating func coming() -> [(name: String, input: NoteCase.Input)] {
        let week = taughtWeek()
        let unit = SplitCase.ItemJSON(
            id: "e0000000-0000-4000-8000-000000000301", kind: "exam",
            audience: .init(school: "f0000000-0000-4000-8000-000000000001", classLevel: "8"), title: "Unit test",
            subject: "Science", date: "2026-10-16", receivedAt: "2026-10-01T10:00:00+05:30"
        )
        let far = SplitCase.ItemJSON(
            id: "e0000000-0000-4000-8000-000000000302", kind: "exam",
            audience: .init(school: "f0000000-0000-4000-8000-000000000001", classLevel: "8"), title: "Half yearly",
            subject: "Science", date: "2026-11-30", receivedAt: "2026-10-01T10:00:00+05:30"
        )
        let up = ladder(["secure@2026-09-01", "secure@2026-10-07", "taught@2026-10-08"], ["secure@2026-09-01"])
        let still = ladder(["secure@2026-09-01", "practising@2026-09-20"], ["taught@2026-09-25"])
        let early = ladder(["secure@2026-09-01", "secure@2026-10-06"], ["secure@2026-09-01", "secure@2026-10-09"])
        return [
            ("the nearest exam is coming", input(week, items: [unit])),
            ("an exam beyond its window is not", input(week, items: [far])),
            ("a mark outside the week is left out", input(
                week, marks: [.init(subject: "Science", test: "FA1", date: "2026-09-20", score: 9, max: 10)]
            )),
            ("UKG moving up gets can-now-do", input(up, level: "ukg")),
            ("class 2 on the ladder with no change", input(still, level: "2")),
            ("class 1 moving up in two areas", input(early, level: "1")),
            ("class 3 without a ladder chapter gets the weekly note", input(week, level: "3")),
        ]
    }
}

@Test func theNoteCaseFileIsHereAndHoldsEveryScenario() throws {
    var scenarios = NoteCaseScenarios()
    let file = try #require(file)
    #expect(file.cases.map(\.name) == scenarios.all().map(\.name))
}

@Test(arguments: (file?.cases ?? []).map(\.name))
func everyNoteCaseIsWhatTheWeekSays(name: String) throws {
    let item = try #require(file?.cases.first { $0.name == name })
    #expect(try week(item.input) == item.expected, "\(name)")
}

/// Writes the case file: `TEST_RUNNER_TC_WRITE_NOTE_CASES=<path> xcodebuild test
/// -only-testing:DomainTests/writeTheNoteCases`,
/// then `bun contract`.
@Test(.enabled(if: ProcessInfo.processInfo.environment["TC_WRITE_NOTE_CASES"] != nil))
func writeTheNoteCases() throws {
    var scenarios = NoteCaseScenarios()
    let cases = try scenarios.all().map { try NoteCase(name: $0.name, input: $0.input, expected: week($0.input)) }
    try CaseJSON.write(NoteCaseFile(cases: cases), to: "TC_WRITE_NOTE_CASES")
}
