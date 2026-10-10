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

/// One opened reminder or receipt (`message_log`, kinds `reminder` and `receipt`): `about_date` is the month's first
/// day, so with the student it names the fee exactly (`(student_id, period)` is unique on `fee_invoices`).
public struct FeeLog: Hashable, Sendable, Codable {
    public enum Kind: String, Hashable, Sendable, Codable {
        case reminder
        case receipt
    }

    public let studentID: UUID
    public let kind: Kind
    public let openedAt: Date
    public let month: Period

    public init(studentID: UUID, kind: Kind, openedAt: Date, month: Period) {
        self.studentID = studentID
        self.kind = kind
        self.openedAt = openedAt
        self.month = month
    }
}

/// The log of opened parent messages. RLS keeps every call inside the member's centre.
public protocol MessageLogRepository: Sendable {
    /// The absence alerts about the month's days (India's), newest first.
    func absences(centre: UUID, month: Period) async throws -> [AbsenceLog]
    /// Logged when the tutor taps Open WhatsApp, before the link opens; `about` is the day of the absence.
    func logAbsence(centre: UUID, studentID: UUID, about: Day) async throws -> AbsenceLog
    /// The month's reminders and receipts, newest first.
    func feeLogs(centre: UUID, month: Period) async throws -> [FeeLog]
    /// One student's reminders and receipts across months, newest first.
    func feeLogs(centre: UUID, student: UUID) async throws -> [FeeLog]
    /// Logged when the tutor taps Open WhatsApp, before the link opens; `month` is the fee's.
    func logFee(centre: UUID, studentID: UUID, kind: FeeLog.Kind, month: Period) async throws -> FeeLog
    /// A progress note's Open WhatsApp, logged before the link opens; when it was opened.
    func logProgress(centre: UUID, studentID: UUID) async throws -> Date
    /// The consent ask's Open WhatsApp, logged before the link opens (kind `consent`); when it was opened.
    func logConsent(centre: UUID, studentID: UUID) async throws -> Date
    /// Everything sent about one student, newest first (the page's Messages section and the consent's "asked on").
    func messages(centre: UUID, student: UUID) async throws -> [MessageEntry]
}
