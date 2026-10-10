import Foundation

/// One of the plan's level groups, as `plans.groups` keeps it (docs/spec-v2.md section 6).
public struct PlanGroup: Hashable, Sendable, Codable, Identifiable {
    public var id: Int {
        number
    }

    /// 1 to 3; Group 1 is the largest.
    public let number: Int
    public let subject: String
    /// The teach skill's chapter ("Chemical reactions"); empty while /ai/plan has not named it.
    public let chapter: String
    /// The group's teach skill; empty while /ai/plan has not named it.
    public let skill: String
    /// Distinct, ascending, for the head ("Class 8 · 3 students").
    public let classLevels: [ClassLevel]
    /// The group's students, by name.
    public let memberIDs: [UUID]
    /// The skill row of the first member who has it; nil for a group named by /ai/plan.
    public let skillID: UUID?

    public init(
        number: Int, subject: String, chapter: String, skill: String, classLevels: [ClassLevel], memberIDs: [UUID],
        skillID: UUID?
    ) {
        self.number = number
        self.subject = subject
        self.chapter = chapter
        self.skill = skill
        self.classLevels = classLevels
        self.memberIDs = memberIDs
        self.skillID = skillID
    }

    /// The group with the chapter and skill /ai/plan named.
    public func named(chapter: String, skill: String) -> PlanGroup {
        PlanGroup(
            number: number, subject: subject, chapter: chapter, skill: skill, classLevels: classLevels,
            memberIDs: memberIDs, skillID: skillID
        )
    }

    /// The group with its members (a student moved in or out today).
    public func with(members: [UUID]) -> PlanGroup {
        PlanGroup(
            number: number, subject: subject, chapter: chapter, skill: skill, classLevels: classLevels,
            memberIDs: members, skillID: skillID
        )
    }
}

/// A line's kind (`plan_item_kind`, migrations 0010 and 0020). The brief, the worked example and the figure are a
/// group's lines (no student): each links its group's artefact.
public enum PlanLineKind: String, Hashable, Sendable, Codable, CaseIterable {
    case teach, practise, check, homework, brief, catchUp = "catch_up", workedExample = "worked_example", figure
}

/// One line as the rules made it, before it is written.
public struct PlanLine: Hashable, Sendable, Codable {
    /// Nil: the group's brief.
    public let studentID: UUID?
    public let groupNo: Int
    public let kind: PlanLineKind
    public let skillID: UUID?
    /// "Teach: Balancing equations".
    public let words: String
    /// A check line whose questions are the student's own (plan decision 5).
    public let personalChecks: Bool

    public init(
        studentID: UUID?, groupNo: Int, kind: PlanLineKind, skillID: UUID?, words: String, personalChecks: Bool = false
    ) {
        self.studentID = studentID
        self.groupNo = groupNo
        self.kind = kind
        self.skillID = skillID
        self.words = words
        self.personalChecks = personalChecks
    }

    func with(words: String) -> PlanLine {
        PlanLine(
            studentID: studentID, groupNo: groupNo, kind: kind, skillID: skillID, words: words,
            personalChecks: personalChecks
        )
    }
}

/// The day's plan for a batch as the rules made it.
public struct PlanDraft: Hashable, Sendable {
    /// The groups /ai/plan named (by number): their chapter and skill, the teach lines that followed the group, the
    /// brief's words and the figure's line when the skill has a template.
    public func naming(_ topics: [Int: (chapter: String, skill: String)]) -> PlanDraft {
        let renamed = groups.map { group in
            topics[group.number].map { group.named(chapter: $0.chapter, skill: $0.skill) } ?? group
        }
        var lines: [PlanLine] = []
        for line in self.lines {
            guard let topic = topics[line.groupNo], let group = renamed.first(where: { $0.number == line.groupNo })
            else {
                lines.append(line)
                continue
            }
            switch line.kind {
            case .teach where line.words == PlanRules.withTheGroup:
                lines.append(line.with(words: "Teach: \(topic.skill)"))
            case .catchUp where !line.words.contains(" · then "):
                lines.append(line.with(words: "\(line.words) · then \(topic.skill)"))
            case .brief:
                lines.append(PlanRules.briefLine(group))
            case .workedExample:
                lines.append(line.with(words: PlanRules.groupLineWords(.workedExample, group)))
                if let figure = PlanRules.figureLine(group) {
                    lines.append(figure)
                }
            case .figure:
                continue
            default:
                lines.append(line)
            }
        }
        return PlanDraft(classID: classID, date: date, groups: renamed, lines: lines, leftOut: leftOut)
    }

    /// A brief line for each group whose chapter the tutor had a brief made for before, when it has none.
    public func addingBriefs(for chapters: Set<String>) -> PlanDraft {
        let missing = groups.filter { group in
            chapters.contains(group.chapter) && !lines.contains { $0.kind == .brief && $0.groupNo == group.number }
        }
        guard !missing.isEmpty else { return self }
        return PlanDraft(
            classID: classID, date: date, groups: groups, lines: lines + missing.map(PlanRules.briefLine),
            leftOut: leftOut
        )
    }

    public let classID: UUID
    public let date: Day
    public let groups: [PlanGroup]
    public let lines: [PlanLine]
    /// Students with no lines (left out today).
    public let leftOut: [UUID]

    public init(classID: UUID, date: Day, groups: [PlanGroup], lines: [PlanLine], leftOut: [UUID]) {
        self.classID = classID
        self.date = date
        self.groups = groups
        self.lines = lines
        self.leftOut = leftOut
    }
}

/// A line as read back (`plan_items`).
public struct PlanItem: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let studentID: UUID?
    public var groupNo: Int
    public let kind: PlanLineKind
    public let skillID: UUID?
    public let words: String
    public var artefactID: UUID?
    public var doneAt: Date?
    public var skippedAt: Date?
    public var movedFrom: Int?

    public init(
        id: UUID, studentID: UUID?, groupNo: Int, kind: PlanLineKind, skillID: UUID?, words: String,
        artefactID: UUID?, doneAt: Date?, skippedAt: Date?, movedFrom: Int?
    ) {
        self.id = id
        self.studentID = studentID
        self.groupNo = groupNo
        self.kind = kind
        self.skillID = skillID
        self.words = words
        self.artefactID = artefactID
        self.doneAt = doneAt
        self.skippedAt = skippedAt
        self.movedFrom = movedFrom
    }
}

/// The day's plan for a batch as read back, with its artefacts.
public struct PlanRecord: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let classID: UUID
    public let date: Day
    public let madeAt: Date
    public var groups: [PlanGroup]
    public var items: [PlanItem]
    public var artefacts: [Artefact]
    public var sessionID: UUID?

    public init(
        id: UUID, classID: UUID, date: Day, madeAt: Date, groups: [PlanGroup], items: [PlanItem],
        artefacts: [Artefact], sessionID: UUID?
    ) {
        self.id = id
        self.classID = classID
        self.date = date
        self.madeAt = madeAt
        self.groups = groups
        self.items = items
        self.artefacts = artefacts
        self.sessionID = sessionID
    }

    /// The student's lines, in the order the plan made them.
    public func items(of studentID: UUID) -> [PlanItem] {
        items.filter { $0.studentID == studentID }
    }

    public func artefact(_ id: UUID?) -> Artefact? {
        guard let id else { return nil }
        return artefacts.first { $0.id == id }
    }

    /// The group's artefact of a kind (the sheet with `forHomework`, the checks, the worked example, the figure, the
    /// brief): one linked to the group's lines and made for no one student.
    public func artefact(group: Int, kind: ArtefactKind, homework: Bool? = nil) -> Artefact? {
        let linked = items.filter { $0.groupNo == group }.compactMap { artefact($0.artefactID) }
        return linked.first { candidate in
            guard candidate.kind == kind, candidate.studentID == nil else { return false }
            guard let homework else { return true }
            if case let .sheet(sheet) = candidate.content {
                return sheet.forHomework == homework
            }
            return false
        }
    }

    /// The student's checks: their own when the plan made them, else the ones their check line links, else the
    /// group's.
    public func checks(for studentID: UUID) -> Artefact? {
        if let own = artefacts.first(where: { $0.kind == .check && $0.studentID == studentID }) {
            return own
        }
        guard let line = items(of: studentID).first(where: { $0.kind == .check }) else { return nil }
        return artefact(line.artefactID) ?? artefact(group: line.groupNo, kind: .check)
    }
}
