import Foundation

/// Whether this iPhone lets the app remind the tutor.
public enum NotificationPermission: Hashable, Sendable {
    case notAsked, allowed, refused
}

/// The device's notification centre behind a protocol, so Teacher reminders and the shell are tested without
/// UserNotifications. The reminders themselves are sent by the server (Phase 18): the app asks, and clears.
public protocol NotificationCenterClient: Sendable {
    func permission() async -> NotificationPermission
    /// The system's ask; true when allowed. Only ever called from Turn on reminders.
    func requestPermission() async -> Bool
    /// The reminders builds 27 and earlier set on this iPhone, removed (the server sends them now).
    func removePending() async
    /// Every notification of ours, pending and shown (sign-out and deletion, D40).
    func removeAll() async
}

/// The notification centre of tests, previews and `bun shots`: a scripted permission, a record of the ask and of
/// what was removed.
@MainActor public final class FakeNotificationCenter: NotificationCenterClient {
    public var permissionAnswer: NotificationPermission
    public var allowOnAsk: Bool
    public private(set) var asked = 0
    public private(set) var pendingRemoved = 0
    public private(set) var allRemoved = 0

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

    public func removePending() async {
        pendingRemoved += 1
    }

    public func removeAll() async {
        allRemoved += 1
    }
}
