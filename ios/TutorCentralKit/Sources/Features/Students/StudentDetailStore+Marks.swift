import Domain
import Foundation

/// The Marks section (U36; P13-Student-Marks): one row per mark, newest first.
public struct MarkRow: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// "Unit test 2 · Mathematics", "Maths unit test 3 · mock · Mathematics".
    public let title: String
    /// "Vidya Niketan · 28 Sep".
    public let line: String
    /// "14 of 25".
    public let score: String
    public let belowUsual: Bool
}

extension StudentDetailStore {
    static let noMarks = (title: "No marks yet", line: "Marks from mocks and checked papers appear here.")

    public var markRows: [MarkRow] {
        let sorted = markRecords.sorted { $0.date > $1.date }
        return sorted.map { mark in
            MarkRow(
                id: mark.id, title: "\(mark.test) · \(mark.subject)",
                line: [school?.name, mark.date.shortText].compactMap(\.self).joined(separator: " · "),
                score: "\(mark.score) of \(mark.max)",
                belowUsual: MarkRules.belowUsual(mark, earlier: markRecords)
            )
        }
    }
}
