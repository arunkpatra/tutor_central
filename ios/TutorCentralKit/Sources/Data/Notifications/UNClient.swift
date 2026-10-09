import Domain
import Foundation
import UserNotifications

/// `UNUserNotificationCenter`: a calendar trigger at `fireAt` (no repeat), the link and the kind in `userInfo`, the
/// reminder's id as the request's identifier.
public final class UNClient: NotificationCenterClient {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

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

    public func replace(with reminders: [Reminder]) async {
        let center = UNUserNotificationCenter.current()
        let wanted = Set(reminders.map(\.id))
        let stale = await center.pendingNotificationRequests().map(\.identifier).filter { !wanted.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        for reminder in reminders {
            try? await center.add(Self.request(for: reminder, calendar: calendar))
        }
    }

    public func pending() async -> [Reminder] {
        await UNUserNotificationCenter.current().pendingNotificationRequests().compactMap(Self.reminder(from:))
    }

    public func removeAll() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // The reminders already shown go too: they name classes and fee totals (review: sign-out and deletion).
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    static func request(for reminder: Reminder, calendar: Calendar) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.userInfo = ["link": reminder.link, "kind": kindName(reminder.kind), "subject": reminder.subject]
        var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireAt)
        parts.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }

    private static func reminder(from request: UNNotificationRequest) -> Reminder? {
        guard let link = request.content.userInfo["link"] as? String,
              let fireAt = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else { return nil }
        let kind: Reminder.Kind = switch request.content.userInfo["kind"] as? String {
        case "event": .event
        case "fees": .fees
        default: .classMeeting
        }
        return Reminder(
            id: request.identifier, kind: kind, title: request.content.title, body: request.content.body,
            fireAt: fireAt, link: link, subject: request.content.userInfo["subject"] as? String ?? ""
        )
    }

    private static func kindName(_ kind: Reminder.Kind) -> String {
        switch kind {
        case .classMeeting: "class"
        case .event: "event"
        case .fees: "fees"
        }
    }
}
