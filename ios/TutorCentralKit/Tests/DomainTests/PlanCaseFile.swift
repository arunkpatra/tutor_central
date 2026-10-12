import Foundation
@testable import Domain

/// The shared plan cases (tools/contract/plan-cases.json, D80): inputs to `PlanRules.plan` and the drafts the Swift
/// rules
/// make of them, in one plain JSON shape the API's port reads too (api/src/plan). Ids are lowercase UUIDs, days
/// "YYYY-MM-DD", instants ISO 8601.
struct PlanCaseFile: Codable {
    var cases: [PlanCase]
}

struct PlanCase: Codable {
    var name: String
    var input: InputJSON
    var expected: DraftJSON
    /// The draft named by /ai/plan's topics and given the briefs made before, when the case asks for it.
    var named: NamedJSON?
}

struct NamedJSON: Codable {
    var topics: [String: TopicJSON]
    var briefChapters: [String]
    var expected: DraftJSON
}

struct TopicJSON: Codable {
    var chapter: String
    var skill: String
}

struct InputJSON: Codable {
    struct Classroom: Codable {
        var id: String
        var subject: String?
        var planGroups: Int?
        /// By ISO weekday, "1" Monday to "7" Sunday.
        var patterns: [String: PatternJSON]
    }

    struct PatternJSON: Codable {
        var groups: Int
        var subjects: [String]
    }

    struct StudentJSON: Codable {
        var id: String
        var name: String
        var classLevel: String?
        var trackStatus: String
        var nextStep: String?
        var gender: String?
    }

    struct ChapterJSON: Codable {
        var id: String
        var subject: String
        var position: Int
        var name: String
    }

    struct SkillJSON: Codable {
        var id: String
        var chapterID: String
        var position: Int
        var name: String
        var state: String
        var stateAt: String
        /// The spaced queue's clock (the budget's cases); absent in the plan's.
        var lastCheckedAt: String?
    }

    struct SessionJSON: Codable {
        var classID: String
        var date: String
        var marks: [String: String]
    }

    struct HintJSON: Codable {
        var studentID: String
        var subject: String
        var date: String
    }

    struct RevisionJSON: Codable {
        var itemID: String
        var title: String
        var subject: String
        var examDate: String
        var day: RevisionDayJSON
        var gapLine: String?
        var pattern: PatternLineJSON?
        var setNumber: Int
        /// What the budget reads besides the rules (the budget's cases): the day's skill names, the portions, the
        /// weakest skills of a marked mock.
        var skills: [String]?
        var portions: [String]?
        var gapSkills: [String]?
    }

    struct PatternLineJSON: Codable, Equatable {
        var marks: Int
        var durationMinutes: Int
    }

    var classroom: Classroom
    var date: String
    var students: [StudentJSON]
    var chapters: [String: [ChapterJSON]]
    var skills: [String: [SkillJSON]]
    var sessions: [SessionJSON]
    var hints: [HintJSON]
    var groupCount: Int?
    var subjects: [String: String]
    var revisions: [String: RevisionJSON]
    var holidays: [String]
}

/// A revision line's preparation day.
struct RevisionDayJSON: Codable {
    var day: String
    /// revise, mock, afterMock or exam.
    var kind: String
    var index: Int?
    var title: String
    var skillIDs: [String]
}

struct DraftJSON: Codable, Equatable {
    struct GroupJSON: Codable, Equatable {
        var number: Int
        var subject: String
        var chapter: String
        var skill: String
        var classLevels: [String]
        var memberIDs: [String]
        var skillID: String?
        var examItemID: String?
    }

    struct LineJSON: Codable, Equatable {
        var studentID: String?
        var groupNo: Int
        var kind: String
        var skillID: String?
        var words: String
        var personalChecks: Bool
    }

    var classID: String
    var date: String
    var groups: [GroupJSON]
    var lines: [LineJSON]
    var leftOut: [String]
    /// By student, the skill ids put first in their own checks.
    var personalCheckSkills: [String: [String]]
}

enum PlanCaseError: Error { case bad(String) }

private func id(_ uuid: UUID) -> String {
    uuid.uuidString.lowercased()
}

private func uuid(_ text: String) throws -> UUID {
    guard let value = UUID(uuidString: text) else { throw PlanCaseError.bad(text) }
    return value
}

private func isoDay(_ text: String) throws -> Day {
    guard let value = Day(iso: text) else { throw PlanCaseError.bad(text) }
    return value
}

extension DraftJSON {
    init(_ draft: PlanDraft) {
        classID = id(draft.classID)
        date = draft.date.iso
        groups = draft.groups.map {
            GroupJSON(
                number: $0.number, subject: $0.subject, chapter: $0.chapter, skill: $0.skill,
                classLevels: $0.classLevels.map(\.rawValue), memberIDs: $0.memberIDs.map(id),
                skillID: $0.skillID.map(id), examItemID: $0.examItemID.map(id)
            )
        }
        lines = draft.lines.map {
            LineJSON(
                studentID: $0.studentID.map(id), groupNo: $0.groupNo, kind: $0.kind.rawValue,
                skillID: $0.skillID.map(id), words: $0.words, personalChecks: $0.personalChecks
            )
        }
        leftOut = draft.leftOut.map(id)
        personalCheckSkills = Dictionary(uniqueKeysWithValues: draft.personalCheckSkills.map { (
            id($0),
            $1.map { id($0.id) }
        ) })
    }
}

extension InputJSON {
    /// The input as the Swift rules take it.
    func planInput() throws -> PlanInput {
        var patterns: [Weekday: PlanPattern] = [:]
        for (key, value) in classroom.patterns {
            guard let raw = Int(key), let weekday = Weekday(rawValue: raw) else { throw PlanCaseError.bad(key) }
            patterns[weekday] = PlanPattern(groups: value.groups, subjects: value.subjects)
        }
        let room = try Domain.Classroom(
            id: uuid(classroom.id), name: "Batch", subject: classroom.subject, monthlyFee: nil,
            meetingDays: Set(Weekday.allCases), startTime: nil, endTime: nil, archivedAt: nil,
            planGroups: classroom.planGroups, planPattern: patterns
        )
        let people = try students.map(student(_:))
        return try PlanInput(
            classroom: room, date: isoDay(date), students: people,
            chapters: keyed(chapters) { try Chapter(
                id: uuid($0.id),
                subject: $0.subject,
                position: $0.position,
                name: $0.name
            ) },
            skills: keyed(skills, Self.skill), sessions: sessions.map(Self.session),
            schoolItems: hints.map { try SchoolItemHint(
                studentID: uuid($0.studentID),
                subject: $0.subject,
                date: isoDay($0.date)
            ) },
            now: Date(timeIntervalSince1970: 0), calendar: DayHeading.india, groupCount: groupCount,
            subjects: Dictionary(uniqueKeysWithValues: subjects.compactMap { key, value in
                Int(key).map { ($0, value) }
            }),
            revisions: Dictionary(uniqueKeysWithValues: revisions.map { key, value in try (uuid(key), value.line()) }),
            holidays: Set(holidays.map(uuid))
        )
    }

    private static func skill(_ json: SkillJSON) throws -> Skill {
        guard let at = ISO8601DateFormatter().date(from: json.stateAt),
              let state = SkillState(rawValue: json.state) else {
            throw PlanCaseError.bad(json.stateAt)
        }
        return try Skill(
            id: uuid(json.id), chapterID: uuid(json.chapterID), position: json.position, name: json.name, state: state,
            stateAt: at, lastCheckedAt: json.lastCheckedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }

    private static func session(_ json: SessionJSON) throws -> AttendanceSession {
        var marks: [UUID: AttendanceStatus] = [:]
        for (student, mark) in json.marks {
            try marks[uuid(student)] = AttendanceStatus(rawValue: mark)
        }
        return try AttendanceSession(
            id: UUID(), classID: uuid(json.classID), date: isoDay(json.date), savedAt: Date(), marks: marks
        )
    }

    private func student(_ json: StudentJSON) throws -> Student {
        try Student(
            id: uuid(json.id), name: json.name, classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil,
            dateOfBirth: nil, gender: json.gender.flatMap(Gender.init(rawValue:)), notes: nil, archivedAt: nil,
            thisMonth: nil, classLevel: json.classLevel.flatMap(ClassLevel.init(rawValue:)),
            trackStatus: TrackStatus(rawValue: json.trackStatus) ?? .notKnown,
            nextStep: json.nextStep.flatMap(NextStep.init(rawValue:))
        )
    }

    private func keyed<T, U>(_ map: [String: [T]], _ make: (T) throws -> U) throws -> [UUID: [U]] {
        var out: [UUID: [U]] = [:]
        for (key, values) in map {
            try out[uuid(key)] = try values.map(make)
        }
        return out
    }
}

extension InputJSON.RevisionJSON {
    func line() throws -> RevisionLine {
        let kind: PreparationDay.Kind = switch day.kind {
        case "revise": .revise(index: day.index ?? 1)
        case "mock": .mock
        case "afterMock": .afterMock
        default: .exam
        }
        let prepared = try PreparationDay(
            day: isoDay(day.day), kind: kind, title: day.title, skills: skills ?? [], skillIDs: day.skillIDs.map(uuid)
        )
        return try RevisionLine(
            itemID: uuid(itemID), title: title, subject: subject, examDate: isoDay(examDate), day: prepared,
            gapLine: gapLine, gapSkills: gapSkills ?? [], portions: portions ?? [],
            pattern: pattern.map { MockPattern(marks: $0.marks, durationMinutes: $0.durationMinutes) },
            setNumber: setNumber
        )
    }
}
