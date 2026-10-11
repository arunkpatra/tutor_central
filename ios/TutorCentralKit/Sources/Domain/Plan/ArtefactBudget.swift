import Foundation

/// One call the plan will make, in the order to make it. Group material names skills and a level, never a student; the
/// personal checks and the placement name the student by id only so the maker can link the answer (D62).
public enum ArtefactRequest: Hashable, Sendable {
    case checks(group: Int, skills: [String], skillIDs: [UUID], classLevel: ClassLevel, subject: String)
    case personalChecks(studentID: UUID, skills: [String], skillIDs: [UUID], classLevel: ClassLevel, subject: String)
    /// The maker builds the subjects from `Placement.groups`.
    case placement(studentID: UUID, classLevel: ClassLevel)
    case sheet(group: Int, skills: [String], classLevel: ClassLevel, subject: String, questions: Int, forHomework: Bool)
    case workedExample(group: Int, skill: String, classLevel: ClassLevel, subject: String)
    case figure(group: Int, kind: FigureSpec.Kind, skill: String, classLevel: ClassLevel, subject: String)
    case brief(group: Int, chapter: String, classLevel: ClassLevel, subject: String)
    /// The exam group's mock (Phase 13): portions and a pattern, no student; made once per exam and shared.
    case mock(
        group: Int, itemID: UUID, title: String, portions: [String], pattern: MockPattern, classLevel: ClassLevel,
        subject: String
    )

    public var groupNo: Int? {
        switch self {
        case let .checks(group, _, _, _, _), let .sheet(group, _, _, _, _, _), let .workedExample(group, _, _, _),
             let .figure(group, _, _, _, _), let .brief(group, _, _, _), let .mock(group, _, _, _, _, _, _):
            group
        case .personalChecks, .placement:
            nil
        }
    }
}

/// What the budget reads for the exam groups (Phase 13): each member's revision line, the exams whose mock exists, and
/// each student's weakest skills from a marked mock.
public struct ExamMaterial: Sendable {
    public let revisions: [UUID: RevisionLine]
    public let mocksMade: Set<UUID>
    public let gapSkills: [UUID: [String]]

    public init(revisions: [UUID: RevisionLine], mocksMade: Set<UUID>, gapSkills: [UUID: [String]]) {
        self.revisions = revisions
        self.mocksMade = mocksMade
        self.gapSkills = gapSkills
    }

    public static let none = ExamMaterial(revisions: [:], mocksMade: [], gapSkills: [:])
}

/// Which artefacts a plan makes and in what order (plan decision 6): per group the checks, the set, the homework sheet,
/// the worked example, a figure when the skill has one, the brief above class 7 or when asked before; then at most four
/// personal checks; at most 20 calls. Tested against the price sheet (DomainTests).
public enum ArtefactBudget {
    public static let maxPersonalChecks = 4
    public static let maxCalls = 20
    /// A line's "Check 3".
    public static let checksPerClass = 3
    public static let setQuestions = 10
    public static let homeworkQuestions = 10
    public static let lightHomeworkQuestions = 5

    /// `briefsMade`: chapter names a brief exists for (the tutor asked before). `spacedSkills`: per student, the spaced
    /// queue's pick in the group's subject, for the group's two spaced questions and the personal checks.
    public static func requests(
        for draft: PlanDraft, students: [UUID: Student], spacedSkills: [UUID: [Skill]], briefsMade: Set<String>,
        exam: ExamMaterial = .none
    ) -> [ArtefactRequest] {
        var made: [ArtefactRequest] = []
        for group in draft.groups where group.examItemID != nil {
            made += examRequests(group, students: students, exam: exam)
        }
        for group in draft.groups where group.examItemID == nil && !group.skill.isEmpty {
            made += groupRequests(group, students: students, spacedSkills: spacedSkills, briefsMade: briefsMade)
        }
        made += personalRequests(draft, students: students, spacedSkills: spacedSkills)
        return Array(made.prefix(maxCalls))
    }

    /// The group's class for the model's sake: the highest level among its members (a group spans a class at most two
    /// apart); class 5 when no member has a class.
    static func classLevel(of group: PlanGroup, students: [UUID: Student]) -> ClassLevel {
        group.memberIDs.compactMap { students[$0]?.classLevel }.max() ?? group.classLevels.max() ?? .five
    }

    private static func groupRequests(
        _ group: PlanGroup, students: [UUID: Student], spacedSkills: [UUID: [Skill]], briefsMade: Set<String>
    ) -> [ArtefactRequest] {
        let level = classLevel(of: group, students: students)
        let spaced = spacedPair(group, spacedSkills: spacedSkills)
        // Three questions a class: the day's skill fills the places the spaced queue leaves (a new batch has none).
        let fill = max(0, checksPerClass - 1 - spaced.count)
        let teachIDs = group.skillID.map { Array(repeating: $0, count: 1 + fill) } ?? []
        var requests: [ArtefactRequest] = [
            .checks(
                group: group.number, skills: Array(repeating: group.skill, count: 1 + fill) + spaced.map(\.name),
                skillIDs: teachIDs + spaced.map(\.id), classLevel: level, subject: group.subject
            ),
            .sheet(
                group: group.number, skills: [group.skill], classLevel: level, subject: group.subject,
                questions: setQuestions, forHomework: false
            ),
            .sheet(
                group: group.number, skills: [group.skill], classLevel: level, subject: group.subject,
                questions: level.homeworkIsLight ? lightHomeworkQuestions : homeworkQuestions, forHomework: true
            ),
            .workedExample(group: group.number, skill: group.skill, classLevel: level, subject: group.subject),
        ]
        if let kind = FigureSpec.Kind.matching(skill: group.skill) {
            requests.append(
                .figure(group: group.number, kind: kind, skill: group.skill, classLevel: level, subject: group.subject)
            )
        }
        if !group.chapter.isEmpty, level > .seven || briefsMade.contains(group.chapter) {
            requests.append(.brief(
                group: group.number,
                chapter: group.chapter,
                classLevel: level,
                subject: group.subject
            ))
        }
        return requests
    }

    /// The two most overdue distinct skills across the members' spaced picks (by last checked, else the state's
    /// change, oldest first), the teach skill left out.
    private static func spacedPair(_ group: PlanGroup, spacedSkills: [UUID: [Skill]]) -> [Skill] {
        let candidates = group.memberIDs.flatMap { spacedSkills[$0] ?? [] }
            .filter { $0.name != group.skill && $0.id != group.skillID }
            .sorted { ($0.lastCheckedAt ?? $0.stateAt) < ($1.lastCheckedAt ?? $1.stateAt) }
        var seen: Set<String> = []
        return Array(candidates.filter { seen.insert($0.name).inserted }.prefix(2))
    }

    private static func personalRequests(
        _ draft: PlanDraft, students: [UUID: Student], spacedSkills: [UUID: [Skill]]
    ) -> [ArtefactRequest] {
        let lines = draft.lines.filter { $0.kind == .check && $0.personalChecks }
            .compactMap { line in line.studentID.flatMap { students[$0] }.map { (line, $0) } }
            .sorted { $0.1.name < $1.1.name }
        let requests = lines.map { line, student -> ArtefactRequest in
            let group = draft.groups.first { $0.number == line.groupNo }
            let level = student.classLevel ?? group.map { classLevel(of: $0, students: students) } ?? .five
            // Nothing taught in the subject: the spaced queue has nothing to pick, so the student is placed.
            let picked = Array((spacedSkills[student.id] ?? []).prefix(SpacedQueue.count))
            guard !picked.isEmpty else { return .placement(studentID: student.id, classLevel: level) }
            return .personalChecks(
                studentID: student.id, skills: picked.map(\.name), skillIDs: picked.map(\.id), classLevel: level,
                subject: group?.subject ?? ""
            )
        }
        return Array(requests.prefix(maxPersonalChecks))
    }

    /// An exam group's material (plan decision 11): checks on the day's skills (at most three, else the portion), the
    /// set
    /// and the homework sheet from them; on the mock day the mock in the set's place (once per exam) and no sheet;
    /// after
    /// the mock, the set from the members' weakest skills (up to six), else the portions.
    private static func examRequests(
        _ group: PlanGroup,
        students: [UUID: Student],
        exam: ExamMaterial
    ) -> [ArtefactRequest] {
        guard let itemID = group.examItemID,
              let revision = group.memberIDs.lazy.compactMap({ exam.revisions[$0] }).first else { return [] }
        let level = classLevel(of: group, students: students)
        let day = revision.day
        let skills: [String]
        let skillIDs: [UUID]
        switch day.kind {
        case .revise:
            skills = day.skills.isEmpty ? [day.title] : day.skills
            skillIDs = day.skillIDs
        case .afterMock:
            var seen: Set<String> = []
            let weakest = group.memberIDs.flatMap { exam.gapSkills[$0] ?? [] }.filter { seen.insert($0).inserted }
            skills = Array((weakest.isEmpty ? revision.portions : weakest).prefix(6))
            skillIDs = []
        case .mock, .exam:
            skills = revision.portions.isEmpty ? [revision.title] : revision.portions
            skillIDs = []
        }
        let checkSkills = Array((skills.isEmpty ? [group.skill] : skills).prefix(3))
        let checks = ArtefactRequest.checks(
            group: group.number, skills: checkSkills, skillIDs: Array(skillIDs.prefix(3)), classLevel: level,
            subject: group.subject
        )
        var requests = [checks]
        if day.kind == .mock {
            if !exam.mocksMade.contains(itemID) {
                requests.append(.mock(
                    group: group.number, itemID: itemID, title: revision.title, portions: revision.portions,
                    pattern: revision.pattern ?? .default(for: level), classLevel: level, subject: group.subject
                ))
            }
            return requests
        }
        requests.append(.sheet(
            group: group.number, skills: skills, classLevel: level, subject: group.subject, questions: setQuestions,
            forHomework: false
        ))
        requests.append(.sheet(
            group: group.number, skills: skills, classLevel: level, subject: group.subject,
            questions: level.homeworkIsLight ? lightHomeworkQuestions : homeworkQuestions, forHomework: true
        ))
        return requests
    }
}
