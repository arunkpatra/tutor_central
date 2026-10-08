import Domain
import Foundation

/// One opened WhatsApp link (`message_log`, D3): who it was about, the day of the absence, and when it was opened.
public struct AbsenceLog: Hashable, Sendable, Codable {
    public let studentID: UUID
    public let openedAt: Date
    /// The day the child was absent (migration 0005); nil on rows logged before it.
    public let aboutDate: Day?

    public init(studentID: UUID, openedAt: Date, aboutDate: Day? = nil) {
        self.studentID = studentID
        self.openedAt = openedAt
        self.aboutDate = aboutDate
    }

    /// The absence it tells of: its day, else (an older row) the day it was opened.
    public func day(in calendar: Calendar) -> Day {
        aboutDate ?? Day(openedAt, calendar: calendar)
    }
}

/// The log of opened parent messages. RLS keeps every call inside the member's centre.
public protocol MessageLogRepository: Sendable {
    /// The absence alerts about the month's days (India's), newest first.
    func absences(centre: UUID, month: Period) async throws -> [AbsenceLog]
    /// Logged when the tutor taps Open WhatsApp, before the link opens; `about` is the day of the absence.
    func logAbsence(centre: UUID, studentID: UUID, about: Day) async throws -> AbsenceLog
}
