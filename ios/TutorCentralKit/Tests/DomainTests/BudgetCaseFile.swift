import Foundation
@testable import Domain

/// The shared budget cases (tools/contract/budget-cases.json, D80; plan/phase-18-plan.md Task 7): a plan's input, its
/// draft made by the rules (held equal by the plan cases), and the artefacts `ArtefactBudget.requests` asks for, with
/// the spaced queue's picks as the plan maker takes them; and the exam split (`ExamPreparation.days` from
/// `ExamPreparation.start`) for one student, with the nearest exam and the holiday rule. The API's port
/// (api/src/plan/budget.ts, exam-prep.ts) answers every case alike.
struct BudgetCaseFile: Codable {
    var cases: [BudgetCase]
    var splits: [SplitCase]
}

struct BudgetCase: Codable {
    struct Input: Codable {
        var plan: InputJSON
        /// The spaced queue's clock.
        var now: String
        var briefsMade: [String]
        var mocksMade: [String]
    }

    var name: String
    var input: Input
    var expected: [RequestJSON]
}

/// One request of the budget, its fields by kind.
struct RequestJSON: Codable, Equatable {
    var kind: String
    var group: Int?
    var student: String?
    var skills: [String]?
    var skillIDs: [String]?
    var classLevel: String
    var subject: String?
    var questions: Int?
    var forHomework: Bool?
    var figure: String?
    var chapter: String?
    var item: String?
    var title: String?
    var portions: [String]?
    var pattern: InputJSON.PatternLineJSON?

    init(_ request: ArtefactRequest) {
        kind = ""
        classLevel = ""
        switch request {
        case let .checks(group, skills, ids, level, subject):
            set("checks", level, group: group, subject: subject)
            (self.skills, skillIDs) = (skills, ids.map(CaseJSON.id))
        case let .personalChecks(student, skills, ids, level, subject):
            set("personalChecks", level, subject: subject)
            (self.student, self.skills, skillIDs) = (CaseJSON.id(student), skills, ids.map(CaseJSON.id))
        case let .placement(student, level):
            set("placement", level)
            self.student = CaseJSON.id(student)
        case let .sheet(group, skills, level, subject, questions, forHomework):
            set("sheet", level, group: group, subject: subject)
            (self.skills, self.questions, self.forHomework) = (skills, questions, forHomework)
        case let .workedExample(group, skill, level, subject):
            set("workedExample", level, group: group, subject: subject)
            skills = [skill]
        case let .figure(group, kind, skill, level, subject):
            set("figure", level, group: group, subject: subject)
            (figure, skills) = (kind.rawValue, [skill])
        case let .brief(group, chapter, level, subject):
            set("brief", level, group: group, subject: subject)
            self.chapter = chapter
        case let .mock(group, item, title, portions, pattern, level, subject):
            set("mock", level, group: group, subject: subject)
            (self.item, self.title, self.portions) = (CaseJSON.id(item), title, portions)
            self.pattern = .init(marks: pattern.marks, durationMinutes: pattern.durationMinutes)
        }
    }

    private mutating func set(_ kind: String, _ level: ClassLevel, group: Int? = nil, subject: String? = nil) {
        self.kind = kind
        classLevel = level.rawValue
        self.group = group
        self.subject = subject
    }
}

/// One student's exam split for the batch's day.
struct SplitCase: Codable {
    struct Audience: Codable {
        var student: String?
        var school: String?
        var classLevel: String?
    }

    struct ItemJSON: Codable {
        var id: String
        var kind: String
        var audience: Audience
        var title: String
        var subject: String?
        var date: String
        var endDate: String?
        var portions: String?
        var receivedAt: String
        var windowDays: Int?
    }

    struct StudentJSON: Codable {
        var id: String
        var name: String
        var classLevel: String?
        var schoolID: String?
    }

    struct Input: Codable {
        var items: [ItemJSON]
        var student: StudentJSON
        var chapters: [InputJSON.ChapterJSON]
        var skills: [InputJSON.SkillJSON]
        /// ISO weekdays, Monday 1.
        var meetingDays: [Int]
        var today: String
    }

    struct DayJSON: Codable, Equatable {
        var day: String
        var kind: String
        var index: Int?
        var title: String
        var skills: [String]
        var skillIDs: [String]
    }

    struct Expected: Codable, Equatable {
        /// The exam that drives the student's revision today, if any.
        var nearest: String?
        var onHoliday: Bool
        /// Where the split starts (the day the item came, or the window's first day).
        var start: String?
        var days: [DayJSON]
    }

    var name: String
    var input: Input
    var expected: Expected
}

/// A split case's input as Domain's types.
struct SplitDomain {
    let items: [SchoolItem]
    let student: Student
    let chapters: [Chapter]
    let skills: [Skill]
    let room: Classroom
}

extension SplitCase.Input {
    func domain() throws -> SplitDomain {
        let student = try Student(
            id: CaseJSON.uuid(student.id), name: student.name, classID: nil, monthlyFee: nil, parentName: nil,
            parentPhone: nil, dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil,
            classLevel: student.classLevel.flatMap { ClassLevel(rawValue: $0) },
            schoolID: student.schoolID.map(CaseJSON.uuid)
        )
        let items = try items.map { json in
            try SchoolItem(
                id: CaseJSON.uuid(json.id), kind: SchoolItemKind(rawValue: json.kind) ?? .notice,
                audience: json.audience.domain(), title: json.title, subject: json.subject,
                date: CaseJSON.day(json.date), endDate: json.endDate.map(CaseJSON.day), portions: json.portions,
                sourceText: nil, photoPath: nil, source: .typed, receivedAt: CaseJSON.instant(json.receivedAt),
                confirmedAt: nil, windowDays: json.windowDays
            )
        }
        let chapters = try chapters.map {
            try Chapter(id: CaseJSON.uuid($0.id), subject: $0.subject, position: $0.position, name: $0.name)
        }
        let skills = try skills.map {
            try Skill(
                id: CaseJSON.uuid($0.id), chapterID: CaseJSON.uuid($0.chapterID), position: $0.position, name: $0.name,
                state: SkillState(rawValue: $0.state) ?? .notStarted, stateAt: CaseJSON.instant($0.stateAt),
                lastCheckedAt: nil
            )
        }
        let room = try Classroom(
            id: UUID(), name: "Batch", subject: nil, monthlyFee: nil, meetingDays: CaseJSON.weekdays(meetingDays),
            startTime: nil, endTime: nil, archivedAt: nil
        )
        return SplitDomain(items: items, student: student, chapters: chapters, skills: skills, room: room)
    }
}

extension SplitCase.Audience {
    func domain() throws -> ItemAudience {
        if let student {
            return try .student(CaseJSON.uuid(student))
        }
        guard let school else { throw CaseJSON.Bad.value("audience") }
        if let classLevel, let level = ClassLevel(rawValue: classLevel) {
            return try .schoolClass(school: CaseJSON.uuid(school), level: level)
        }
        return try .school(CaseJSON.uuid(school))
    }
}

extension SplitCase.DayJSON {
    init(_ day: PreparationDay) {
        self.day = day.day.iso
        switch day.kind {
        case let .revise(index): (kind, self.index) = ("revise", index)
        case .mock: (kind, index) = ("mock", nil)
        case .afterMock: (kind, index) = ("afterMock", nil)
        case .exam: (kind, index) = ("exam", nil)
        }
        title = day.title
        skills = day.skills
        skillIDs = day.skillIDs.map(CaseJSON.id)
    }
}
