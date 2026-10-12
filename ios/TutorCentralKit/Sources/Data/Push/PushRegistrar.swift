import Foundation

/// Push on this iPhone (plan/phase-18-plan.md decision 17): once the tutor allowed notifications (the same ask as the
/// reminders'), iOS is asked for a push token; the token iOS answers is kept for the server with this device's id, the
/// APNs environment of this build and the build number. Sign-out and deletion forget it before the wipe (D40).
@MainActor public final class PushRegistrar {
    private let notifications: any NotificationCenterClient
    private let tokens: any DeviceTokenRepository
    private let registerForRemote: @MainActor () -> Void
    private let unregisterFromRemote: @MainActor () -> Void
    private let deviceID: @MainActor () -> String?
    private let environment: String
    private let build: Int?

    /// `environment` is the build's (`PUSH_ENVIRONMENT` in Info.plist: sandbox in Debug, production in Release).
    public init(
        notifications: any NotificationCenterClient, tokens: any DeviceTokenRepository,
        registerForRemote: @escaping @MainActor () -> Void, unregisterFromRemote: @escaping @MainActor () -> Void,
        deviceID: @escaping @MainActor () -> String?, environment: String, build: Int?
    ) {
        self.notifications = notifications
        self.tokens = tokens
        self.registerForRemote = registerForRemote
        self.unregisterFromRemote = unregisterFromRemote
        self.deviceID = deviceID
        self.environment = environment
        self.build = build
    }

    /// Asks iOS for the token, only when notifications are allowed (never the system's ask: that is Turn on
    /// reminders').
    public func register() async {
        guard await notifications.permission() == .allowed else { return }
        registerForRemote()
    }

    /// The token iOS answered, kept for the server; a failed save is tried again at the next launch's registration.
    public func received(token: Data) async {
        guard let device = deviceID() else { return }
        try? await tokens.save(
            DeviceToken(deviceID: device, token: DeviceToken.hex(token), environment: environment, build: build)
        )
    }

    /// This device's token forgotten (sign-out, deletion), before the wipe; and the app unregistered from APNs, which
    /// needs no connection: offline the row cannot be deleted, and Apple then answers 410 for the token, which the
    /// server retires (the review's R-app-4). The next sign-in asks for a token again.
    public func forget() async {
        unregisterFromRemote()
        guard let device = deviceID() else { return }
        try? await tokens.forget(deviceID: device)
    }
}
