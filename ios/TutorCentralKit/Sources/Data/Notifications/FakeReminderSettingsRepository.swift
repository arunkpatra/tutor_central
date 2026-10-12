import Domain
import Foundation

/// Reminder settings in memory, for tests, previews and `bun shots`: the settings kept, each save, the next reminder.
public actor FakeReminderSettingsRepository: ReminderSettingsRepository {
    public private(set) var kept: ReminderSettings?
    public private(set) var saves: [ReminderSettings] = []
    private let upcoming: NextReminder?
    private let failure: (any Error)?
    /// A test holds the next save until it releases it, as a slow connection (the review's R-app-3).
    private var holding = false
    private var held: CheckedContinuation<Void, Never>?

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
        if holding {
            holding = false
            await withCheckedContinuation { held = $0 }
        }
        kept = settings
        saves.append(settings)
    }

    public func holdNextSave() {
        holding = true
    }

    /// Whether a held save is waiting.
    public var isHolding: Bool {
        held != nil
    }

    public func releaseSave() {
        held?.resume()
        held = nil
    }

    public func next(centre _: UUID) async throws -> NextReminder? {
        upcoming
    }
}
