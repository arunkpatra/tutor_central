import Domain
import Foundation

/// Reminder settings in memory, for tests, previews and `bun shots`: the settings kept, each save, the next reminder.
public actor FakeReminderSettingsRepository: ReminderSettingsRepository {
    public private(set) var kept: ReminderSettings?
    public private(set) var saves: [ReminderSettings] = []
    private let upcoming: NextReminder?
    private let failure: (any Error)?

    public init(kept: ReminderSettings? = nil, next: NextReminder? = nil, failure: (any Error)? = nil) {
        self.kept = kept
        upcoming = next
        self.failure = failure
    }

    public func read(centre _: UUID) async throws -> ReminderSettings {
        if let failure {
            throw failure
        }
        return kept ?? ReminderSettings()
    }

    public func save(_ settings: ReminderSettings, centre _: UUID) async throws {
        if let failure {
            throw failure
        }
        kept = settings
        saves.append(settings)
    }

    public func next(centre _: UUID) async throws -> NextReminder? {
        upcoming
    }
}
