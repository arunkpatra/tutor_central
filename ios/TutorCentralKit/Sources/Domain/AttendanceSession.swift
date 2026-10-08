import Foundation

/// One saved class and day (`attendance_sessions`) with its marks; `classID` nil is the session for all students.
public struct AttendanceSession: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var classID: UUID?
    public var date: Day
    public var savedAt: Date
    public var marks: [UUID: AttendanceStatus]

    public init(id: UUID, classID: UUID?, date: Day, savedAt: Date, marks: [UUID: AttendanceStatus]) {
        self.id = id
        self.classID = classID
        self.date = date
        self.savedAt = savedAt
        self.marks = marks
    }

    public var presentCount: Int {
        marks.values.filter { $0 == .present }.count
    }

    public var absentCount: Int {
        marks.values.filter { $0 == .absent }.count
    }

    public var absentStudentIDs: [UUID] {
        marks.filter { $0.value == .absent }.map(\.key)
    }
}
