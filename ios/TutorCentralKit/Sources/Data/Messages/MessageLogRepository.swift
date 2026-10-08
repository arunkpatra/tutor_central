import Domain
import Foundation

/// One opened WhatsApp link (`message_log`, D3): who it was about and when.
public struct AbsenceLog: Hashable, Sendable, Codable {
    public let studentID: UUID
    public let openedAt: Date

    public init(studentID: UUID, openedAt: Date) {
        self.studentID = studentID
        self.openedAt = openedAt
    }
}

/// The log of opened parent messages. RLS keeps every call inside the member's centre.
public protocol MessageLogRepository: Sendable {
    /// The absence alerts opened in the month (India's), newest first.
    func absences(centre: UUID, month: Period) async throws -> [AbsenceLog]
    /// Logged when the tutor taps Open WhatsApp, before the link opens.
    func logAbsence(centre: UUID, studentID: UUID) async throws -> AbsenceLog
}
