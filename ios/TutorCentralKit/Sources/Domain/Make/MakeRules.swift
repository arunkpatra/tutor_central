import Foundation

/// One of today's plan groups, as the For sheet lists it.
public struct TodayGroup: Hashable, Sendable {
    public let planID: UUID
    public let classID: UUID?
    public let group: PlanGroup

    public init(planID: UUID, classID: UUID?, group: PlanGroup) {
        self.planID = planID
        self.classID = classID
        self.group = group
    }
}

/// A student's chapters and skills, as Make reads them for the Skill tile and Progress for its rows.
public struct RecordBook: Hashable, Sendable {
    public let chapters: [Chapter]
    public let skills: [Skill]

    public init(chapters: [Chapter], skills: [Skill]) {
        self.chapters = chapters
        self.skills = skills
    }
}

/// What Make knows of the centre when it works out a target's level and skills: the active students, the batches,
/// today's groups.
public struct MakeRoster: Sendable {
    public let students: [Student]
    public let classes: [Classroom]
    public let groups: [TodayGroup]

    public init(students: [Student], classes: [Classroom], groups: [TodayGroup]) {
        self.students = students
        self.classes = classes
        self.groups = groups
    }

    func student(_ id: UUID) -> Student? {
        students.first { $0.id == id }
    }

    func members(of classID: UUID) -> [Student] {
        students.filter { $0.classID == classID }
    }

    func group(plan: UUID, number: Int) -> PlanGroup? {
        groups.first { $0.planID == plan && $0.group.number == number }?.group
    }
}

/// Make's target turned into what the API takes: a class level and skill names, never a student (D62; plan/phase-15-
/// plan.md decision 3).
public enum MakeRules {
    public static let sheetLengths: [(title: String, questions: Int)] = [("Short", 6), ("Medium", 10), ("Long", 15)]
    public static let levels: [(title: String, reason: String?)] = [
        ("Easier", "easier"), ("As the record says", nil), ("Harder", "harder"),
    ]
    public static let tutorSaysLimit = 300
    /// The skills a batch offers the Skill tile at most (the sheet's schema takes six).
    static let batchSkills = 6

    /// The level the material is made at: a student's class; a group's highest member's (as the plan makes it); a
    /// batch's most common, ties to the higher; a class level itself. Nil until known (the Class tile reads Choose).
    public static func level(for target: MakeTarget, roster: MakeRoster) -> ClassLevel? {
        switch target {
        case let .student(id):
            return roster.student(id)?.classLevel
        case let .group(plan, number):
            guard let group = roster.group(plan: plan, number: number) else { return nil }
            return group.memberIDs.compactMap { roster.student($0)?.classLevel }.max() ?? group.classLevels.max()
        case let .batch(id):
            let counts = Dictionary(grouping: roster.members(of: id).compactMap(\.classLevel), by: \.self)
                .mapValues(\.count)
            return counts.max { lhs, rhs in lhs.value != rhs.value ? lhs.value < rhs.value : lhs.key < rhs.key }?.key
        case let .classLevel(level):
            return level
        }
    }

    /// The Skill tile's choices from the record: a student's current skill in the subject; a group's teach skill; a
    /// batch's members' current skills (distinct, at most six); nothing for a class level (a topic is typed).
    public static func skills(
        for target: MakeTarget, subject: String, books: [UUID: RecordBook], roster: MakeRoster
    ) -> [String] {
        switch target {
        case let .student(id):
            return current(books[id], subject: subject).map { [$0] } ?? []
        case let .group(plan, number):
            guard let skill = roster.group(plan: plan, number: number)?.skill, !skill.isEmpty else { return [] }
            return [skill]
        case let .batch(id):
            var names: [String] = []
            for member in roster.members(of: id) {
                if let name = current(books[member.id], subject: subject), !names.contains(name) {
                    names.append(name)
                }
            }
            return Array(names.prefix(batchSkills))
        case .classLevel:
            return []
        }
    }

    /// The Subject tile's choices: the subjects of the student's books, the group's subject, the batch's members'
    /// subjects after the batch's own; none for a class level (typed).
    public static func subjects(for target: MakeTarget, books: [UUID: RecordBook], roster: MakeRoster) -> [String] {
        switch target {
        case let .student(id):
            return subjects(of: [books[id]])
        case let .group(plan, number):
            return roster.group(plan: plan, number: number).map { [$0.subject] } ?? []
        case let .batch(id):
            let own = roster.classes.first { $0.id == id }?.subject.map { [$0] } ?? []
            return distinct(own + subjects(of: roster.members(of: id).map { books[$0.id] }))
        case .classLevel:
            return []
        }
    }

    /// The target's words for the artefact's eyebrow and Recent.
    public static func forWords(_ target: MakeTarget, roster: MakeRoster, subject: String, skill: String?) -> MakeFor {
        let level = level(for: target, roster: roster)
        let topic = skill.flatMap { $0.isEmpty ? nil : $0 }
        let joined = { (parts: [String?]) in
            parts.compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · ")
        }
        let levelSubject = [level?.title, subject.isEmpty ? nil : subject].compactMap(\.self).joined(separator: " ")
        switch target {
        case let .student(id):
            let name = roster.student(id)?.firstName ?? "a student"
            return MakeFor(target: target, title: "For \(name)", line: joined([levelSubject, topic]))
        case let .group(_, number):
            return MakeFor(target: target, title: "Group \(number)", line: joined([levelSubject, topic]))
        case let .batch(id):
            let name = roster.classes.first { $0.id == id }?.name ?? "A batch"
            return MakeFor(target: target, title: name, line: joined([level?.title, subject, topic]))
        case let .classLevel(level):
            return MakeFor(target: target, title: level.title, line: joined([subject, topic]))
        }
    }

    private static func current(_ book: RecordBook?, subject: String) -> String? {
        guard let book else { return nil }
        let chapters = book.chapters.filter { $0.subject == subject }
        return TrackingRules.currentSkill(skills: book.skills, chapters: chapters)?.name
    }

    private static func subjects(of books: [RecordBook?]) -> [String] {
        distinct(books.compactMap(\.self).flatMap { $0.chapters.sorted { $0.position < $1.position }.map(\.subject) })
    }

    private static func distinct(_ names: [String]) -> [String] {
        var seen: [String] = []
        for name in names where !seen.contains(name) {
            seen.append(name)
        }
        return seen
    }
}
