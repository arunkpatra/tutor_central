import Domain
import Foundation

/// Whether this iPhone lets the app remind the tutor.
public enum NotificationPermission: Hashable, Sendable {
    case notAsked, allowed, refused
}

/// The device's notification centre behind a protocol, so the scheduler and Teacher reminders are tested without
/// UserNotifications.
public protocol NotificationCenterClient: Sendable {
    func permission() async -> NotificationPermission
    /// The system's ask; true when allowed. Only ever called from Turn on reminders.
    func requestPermission() async -> Bool
    /// Replaces every pending reminder of ours with these: the ones not in the plan go, the rest are added (the same
    /// id replaces itself, so an unchanged one keeps its place).
    func replace(with reminders: [Reminder]) async
    func pending() async -> [Reminder]
    func removeAll() async
}

/// The notification centre of tests, previews and `bun shots`: a scripted permission, a record of the ask and of
/// every plan.
@MainActor public final class FakeNotificationCenter: NotificationCenterClient {
    public var permissionAnswer: NotificationPermission
    public var allowOnAsk: Bool
    public private(set) var asked = 0
    public private(set) var scheduled: [Reminder] = []
    public private(set) var replacements = 0

    public init(permission: NotificationPermission = .notAsked, allowOnAsk: Bool = true) {
        permissionAnswer = permission
        self.allowOnAsk = allowOnAsk
    }

    public func permission() async -> NotificationPermission {
        permissionAnswer
    }

    public func requestPermission() async -> Bool {
        asked += 1
        permissionAnswer = allowOnAsk ? .allowed : .refused
        return allowOnAsk
    }

    public func replace(with reminders: [Reminder]) async {
        replacements += 1
        scheduled = reminders
    }

    public func pending() async -> [Reminder] {
        scheduled
    }

    public func removeAll() async {
        scheduled = []
    }
}
