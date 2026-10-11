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

public extension StudentDetailStore {
    internal static let noMarks = (title: "No marks yet", line: "Marks from mocks and checked papers appear here.")

    /// Add from a photo (P10-Student-Record): the parent's consent first (D62); none on an archived student.
    var canAddMarks: Bool {
        guard let student, student.archivedAt == nil else { return false }
        return student.consent != nil
    }

    /// Under the Marks header while the action waits: "Marks from a photo wait for Neha's consent."
    var marksConsentLine: String? {
        guard let student, student.archivedAt == nil, student.consent == nil else { return nil }
        let parent = student.parentName.flatMap { $0.split(separator: " ").first.map(String.init) }
        return "Marks from a photo wait for \(parent.map { "\($0)'s" } ?? "the parent's") consent."
    }

    var markRows: [MarkRow] {
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
