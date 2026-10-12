import Domain
import Foundation

/// The reminder settings move from the iPhone to the account (plan/phase-18-plan.md decision 6): on the first launch
/// of a build with push, the choices builds 27 and earlier kept in `UserDefaults` ("reminders") are saved with the
/// account unless it holds choices already (set on another iPhone: the review's R-app-6), then the key and every
/// reminder still set on this iPhone go (the server sends them now). A failed read or save keeps the key for the next
/// launch.
public enum ReminderSettingsMigration {
    /// The key builds 27 and earlier kept the choices under, and the one that remembered the system's ask.
    public static let key = "reminders"
    public static let askedKey = "reminders.asked"

    @MainActor public static func run(
        defaults: UserDefaults, repository: any ReminderSettingsRepository, notifications: any NotificationCenterClient,
        centre: UUID
    ) async {
        guard let data = defaults.data(forKey: key) else { return }
        if let old = try? JSONDecoder().decode(ReminderSettings.self, from: data) {
            do {
                if try await repository.read(centre: centre) == nil {
                    try await repository.save(old, centre: centre)
                }
            } catch {
                return
            }
        }
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: askedKey)
        await notifications.removePending()
    }
}
