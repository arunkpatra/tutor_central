import Foundation

/// The plan in exam mode (docs/spec-v2.md section 6.6; plan/phase-13-plan.md decision 10): students of one exam within
/// the window form a group of their own, nearest exam first, with revision lines from the day's portion.
public extension PlanRules {
    static let revisionPrefix = "Revise: "
    /// `plan_items.words`' limit.
    static let wordsLimit = 200

    /// At most 200 scalars, cut at a word, with no trailing space, comma or " ·".
    static func cut(_ words: String) -> String {
        guard words.unicodeScalars.count > wordsLimit else { return words }
        var text = String(String.UnicodeScalarView(words.unicodeScalars.prefix(wordsLimit)))
        if let space = text.lastIndex(of: " ") {
            text = String(text[..<space])
        }
        return text.trimmingCharacters(in: CharacterSet(charactersIn: " ·,;"))
    }

    /// The teach line's words for a student revising: the day's portion, the mock with its pattern, the gap report's
    /// line after the mock.
    static func revisionTeach(_ revision: RevisionLine) -> String {
        switch revision.day.kind {
        case .revise: revisionPrefix + revision.day.title
        case .mock: ["The mock", revision.pattern?.line].compactMap(\.self).joined(separator: " · ")
        case .afterMock: revision.gapLine ?? "Revise: what the mock showed"
        case .exam: "The test today"
        }
    }
}

extension PlanRules {
    /// The students of each exam, nearest exam first (ties by title), by name; at most two groups when other students
    /// remain (a level group is left for them), else three. Students of a later exam stay in the level cut.
    static func examGroups(_ students: [Student], input: PlanInput) -> [[Student]] {
        let revising = students.filter { input.revisions[$0.id] != nil }
        let byItem = Dictionary(grouping: revising) { input.revisions[$0.id]?.itemID }
        let ordered = byItem.values.sorted { lhs, rhs in
            guard let left = lhs.first.flatMap({ input.revisions[$0.id] }),
                  let right = rhs.first.flatMap({ input.revisions[$0.id] }) else { return false }
            return (left.examDate, left.title, left.itemID.uuidString) < (
                right.examDate,
                right.title,
                right.itemID.uuidString
            )
        }
        let othersRemain = students.count > revising.count
        let cap = othersRemain ? maxGroups - 1 : maxGroups
        return ordered.prefix(cap).map { $0.sorted { $0.name < $1.name } }
    }

    static func examGroup(_ number: Int, members: [Student], input: PlanInput) -> PlanGroup {
        let revision = members.first.flatMap { input.revisions[$0.id] }
        return PlanGroup(
            number: number, subject: revision?.subject ?? "", chapter: revision?.title ?? "",
            skill: revision?.day.title ?? "", classLevels: Array(Set(members.compactMap(\.classLevel))).sorted(),
            memberIDs: members.map(\.id), skillID: nil, examItemID: revision?.itemID
        )
    }

    /// A revising student's lines: a catch-up first when they missed the last two, the day's revision, the set (the
    /// mock on the mock day), Check 3, the revision sheet (none on the mock day).
    static func examLines(_ student: Student, group: PlanGroup, input: PlanInput) -> [PlanLine] {
        guard let revision = input.revisions[student.id] else { return [] }
        let line = { (kind: PlanLineKind, words: String) in
            PlanLine(
                studentID: student.id, groupNo: group.number, kind: kind, skillID: revision.day.skillIDs.first,
                words: words
            )
        }
        var lines: [PlanLine] = []
        if let missed = catchUp(for: student, input: input) {
            lines.append(line(.catchUp, "\(missed) · then \(revision.day.title)"))
        }
        lines.append(line(.teach, revisionTeach(revision)))
        let mockDay = revision.day.kind == .mock
        lines.append(line(.practise, mockDay ? "The mock" : "Revision set \(revision.setNumber)"))
        lines.append(line(.check, "Check 3"))
        if !mockDay {
            lines.append(line(.homework, "Revision sheet \(revision.setNumber)"))
        }
        return lines
    }
}
