import Domain
import Foundation

/// A plan's draft and record for the Data tests: the boards' Evening batch with two groups (DataTests cannot see
/// DomainTests' builders).
enum PlanSamples {
    static let oct7at1635 = Date(timeIntervalSince1970: 1_791_371_100) // 2026-10-07 16:35 in India
    static let classID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let dev = UUID(uuidString: "7a1f0000-0000-0000-0000-0000000000d1")!
    static let meher = UUID(uuidString: "7a1f0000-0000-0000-0000-0000000000d2")!
    static let riya = UUID(uuidString: "7a1f0000-0000-0000-0000-0000000000d3")!

    static let groups = [
        PlanGroup(
            number: 1, subject: "Science", chapter: "Chemical reactions", skill: "Balancing equations",
            classLevels: [.eight], memberIDs: [dev, meher], skillID: nil
        ),
        PlanGroup(
            number: 2, subject: "Mathematics", chapter: "Parts and Wholes", skill: "Compare simple fractions",
            classLevels: [.five], memberIDs: [riya], skillID: nil
        ),
    ]

    static let sampleDraft: PlanDraft = {
        let lines = [
            (dev, 1, "Teach: Balancing equations"),
            (meher, 1, "Teach: Balancing equations"),
            (riya, 2, "Teach: Compare simple fractions"),
        ].flatMap { student, group, teach in
            [
                PlanLine(studentID: student, groupNo: group, kind: .teach, skillID: nil, words: teach),
                PlanLine(studentID: student, groupNo: group, kind: .practise, skillID: nil, words: "Practise set 1"),
                PlanLine(studentID: student, groupNo: group, kind: .check, skillID: nil, words: "Check 3"),
                PlanLine(studentID: student, groupNo: group, kind: .homework, skillID: nil, words: "Homework sheet 1"),
            ]
        } + [PlanLine(studentID: nil, groupNo: 1, kind: .brief, skillID: nil, words: "Your brief · Chemical reactions")]
        return PlanDraft(classID: classID, date: Day(iso: "2026-10-07")!, groups: groups, lines: lines, leftOut: [])
    }()

    static func sampleRecord(date: Day) -> PlanRecord {
        let items = sampleDraft.lines.map { line in
            PlanItem(
                id: UUID(), studentID: line.studentID, groupNo: line.groupNo, kind: line.kind, skillID: line.skillID,
                words: line.words, artefactID: nil, doneAt: nil, skippedAt: nil, movedFrom: nil
            )
        }
        return PlanRecord(
            id: UUID(), classID: classID, date: date, madeAt: oct7at1635, groups: groups, items: items, artefacts: [],
            sessionID: nil
        )
    }
}
