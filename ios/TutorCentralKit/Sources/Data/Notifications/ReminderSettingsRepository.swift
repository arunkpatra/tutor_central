import Domain
import Foundation

/// The next reminder the server will send this tutor (their own outbox rows): what it is about and when.
public struct NextReminder: Hashable, Sendable {
    public let subject: String
    public let at: Date

    public init(subject: String, at: Date) {
        self.subject = subject
        self.at = at
    }
}

/// The tutor's reminder settings with the account (`reminder_settings`, plan/phase-18-plan.md decision 6), and the next
/// reminder the server has planned for them.
public protocol ReminderSettingsRepository: Sendable {
    /// The tutor's settings for the centre; nil when none are kept yet (the screen shows the defaults).
    func read(centre: UUID) async throws -> ReminderSettings?
    func save(_ settings: ReminderSettings, centre: UUID) async throws
    /// The soonest class, event or fee reminder still to be sent; none when nothing is planned.
    func next(centre: UUID) async throws -> NextReminder?
}
