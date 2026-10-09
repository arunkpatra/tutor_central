import Foundation
import UserNotifications

/// `UNUserNotificationCenterDelegate` behind a class: SwiftUI has no way to receive a tapped notification (D8, UIKit
/// with its reason). A tap hands the reminder's link to `onOpen`, which RootView sets to the deep-link path; a tap
/// before that (the launch itself, or signed out) is kept and delivered once when `onOpen` is set.
@MainActor public final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationDelegate()

    private var kept: URL?

    /// Set by RootView once the session is ready; a kept link is delivered on set.
    public var onOpen: ((URL) -> Void)? {
        didSet {
            guard let onOpen, let url = kept else { return }
            kept = nil
            onOpen(url)
        }
    }

    override public init() {}

    func open(_ url: URL?) {
        guard let url else { return }
        guard let onOpen else {
            kept = url
            return
        }
        onOpen(url)
    }

    /// In the foreground the banner shows, as it does on the lock screen.
    public nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter, willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    public nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        let link = (response.notification.request.content.userInfo["link"] as? String).flatMap(URL.init(string:))
        await open(link)
    }
}
