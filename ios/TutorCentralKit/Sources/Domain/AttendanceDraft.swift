import Foundation

/// What the mark screen edits: a date, a class (nil: all students) and one mark per active member. Everyone starts
/// present; a saved session's marks come first; a member saved without a mark (joined since) is present.
public struct AttendanceDraft: Hashable, Sendable {
    public var date: Day
    public var classID: UUID?
    public var marks: [UUID: AttendanceStatus]

    public init(date: Day, classID: UUID?, members: [Student], saved: AttendanceSession?) {
        self.date = date
        self.classID = classID
        marks = Dictionary(uniqueKeysWithValues: members.filter { !$0.isArchived }.map { (
            $0.id,
            saved?.marks[$0.id] ?? .present
        ) })
    }

    public mutating func toggle(_ studentID: UUID) {
        guard let mark = marks[studentID] else { return }
        marks[studentID] = mark == .present ? .absent : .present
    }

    public var presentCount: Int {
        marks.values.filter { $0 == .present }.count
    }

    public var absentCount: Int {
        marks.values.filter { $0 == .absent }.count
    }

    /// The absent members in the order the list shows them.
    public func absentIDs(ordered members: [Student]) -> [UUID] {
        members.map(\.id).filter { marks[$0] == .absent }
    }

    /// A fresh class is always worth saving; a reopened one only once a mark differs from what was saved.
    public func isChanged(from saved: AttendanceSession?, members: [Student]) -> Bool {
        guard let saved else { return true }
        return members.filter { !$0.isArchived }.contains { marks[$0.id] != (saved.marks[$0.id] ?? .present) }
    }
}
