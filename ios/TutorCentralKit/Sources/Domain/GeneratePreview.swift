import Foundation

/// What `generate_fees` will make for a month, counted on the device by its rule: one fee per active student without
/// one, from the student's own fee, else the class's, else nothing (P5-Generate, -Generate-Nothing).
public struct GeneratePreview: Hashable, Sendable {
    public struct Group: Hashable, Sendable, Identifiable {
        public let id: String
        public let name: String
        public let count: Int
        public let total: Money

        public var line: String {
            "\(name) · \(count == 1 ? "1 student" : "\(count) students")"
        }
    }

    public let month: Period
    public let groups: [Group]
    public let count: Int
    public let total: Money

    public static func make(
        students: [Student],
        classes: [Classroom],
        invoices: [FeeInvoice],
        month: Period
    ) -> GeneratePreview {
        let covered = Set(invoices.filter { $0.period == month }.map(\.studentID))
        let missing = students.filter { !$0.isArchived && !covered.contains($0.id) }
        var groups: [Group] = []
        for classroom in classes.filter({ !$0.isArchived }) {
            let members = missing.filter { $0.classID == classroom.id }
            guard !members.isEmpty else { continue }
            groups.append(Group(
                id: classroom.id.uuidString, name: classroom.name, count: members.count,
                total: members.map { $0.fee(in: classroom) ?? .zero }.total
            ))
        }
        let noClass = missing.filter { student in !classes.contains { $0.id == student.classID && !$0.isArchived } }
        if !noClass.isEmpty {
            groups.append(Group(
                id: "none",
                name: "No class",
                count: noClass.count,
                total: noClass.map { $0.monthlyFee ?? .zero }.total
            ))
        }
        return GeneratePreview(month: month, groups: groups, count: missing.count, total: groups.map(\.total).total)
    }

    /// Every student without a fee falls in a group ("No class" takes the rest).
    public var canCreate: Bool {
        !groups.isEmpty
    }

    public var title: String {
        switch count {
        case 0: "Everyone has a fee for \(month.monthName)"
        case 1: "1 fee will be created"
        default: "\(count) fees will be created"
        }
    }

    public var line: String {
        canCreate
            ? "One for each student without a fee for \(month.monthName), from the class fee or the student's own."
            : "Nothing to create. A student you add later gets one from here."
    }

    public var buttonLabel: String {
        switch count {
        case 0: "Nothing to create"
        case 1: "Create 1 fee"
        default: "Create \(count) fees"
        }
    }
}
