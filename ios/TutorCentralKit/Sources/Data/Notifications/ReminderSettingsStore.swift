import Domain
import Foundation

/// The tutor's reminder choices on this iPhone (P7-Reminders): JSON in `UserDefaults` under "reminders", and whether
/// the system was asked ("reminders.asked"). Never on the server. Both go on sign-out (D40, `Wipe`).
public struct ReminderSettingsStore: @unchecked Sendable {
    public static let key = "reminders"
    public static let askedKey = "reminders.asked"
    /// UserDefaults is thread-safe; it is not marked Sendable.
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The saved choices, or the defaults when none (or unreadable).
    public func load() -> ReminderSettings {
        defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(ReminderSettings.self, from: $0) }
            ?? ReminderSettings()
    }

    public func save(_ settings: ReminderSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.key)
        }
    }

    public var asked: Bool {
        get { defaults.bool(forKey: Self.askedKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.askedKey) }
    }
}
