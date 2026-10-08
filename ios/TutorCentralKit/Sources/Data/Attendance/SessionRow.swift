import Domain
import Foundation

/// An `attendance_sessions` row with its marks embedded.
struct SessionRow: Decodable {
    struct Mark: Decodable {
        let studentId: UUID
        let status: String
    }

    let id: UUID
    let classId: UUID?
    let date: String
    let savedAt: Date
    let attendanceMarks: [Mark]

    var session: AttendanceSession {
        AttendanceSession(
            id: id, classID: classId, date: Day(iso: date) ?? Day(year: 1970, month: 1, day: 1)!, savedAt: savedAt,
            marks: Dictionary(uniqueKeysWithValues: attendanceMarks.compactMap { mark in
                AttendanceStatus(rawValue: mark.status).map { (mark.studentId, $0) }
            })
        )
    }
}
