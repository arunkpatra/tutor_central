import Foundation
import UserNotifications

/// `UNUserNotificationCenter`: the permission and its ask, and the removals. The reminders arrive as pushes from the
/// server (Phase 18), so nothing is scheduled here any more.
public final class UNClient: NotificationCenterClient {
    public init() {}

    public func permission() async -> NotificationPermission {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .notAsked
        case .denied: .refused
        case .authorized, .provisional, .ephemeral: .allowed
        @unknown default: .refused
        }
    }

    public func requestPermission() async -> Bool {
        await (try? UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func removePending() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    public func removeAll() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // The reminders already shown go too: they name classes and fee totals (review: sign-out and deletion).
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
