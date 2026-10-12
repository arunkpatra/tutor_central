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
        _: UNUserNotificationCenter, willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// The completion-handler form, not the async one: the async form finished on a background thread and UIKit, told
    /// there that the tap was handled, aborted (build 13, a tester's crash on tapping a class reminder).
    public nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        received(Self.link(from: response.notification.request.content.userInfo), then: completionHandler)
    }

    /// The notification's link: a push carries it beside `aps` (api/src/push/payload.ts), a reminder set by builds 27
    /// and earlier in `userInfo["link"]`; a push with no link opens Today.
    nonisolated static func link(from userInfo: [AnyHashable: Any]) -> URL? {
        if let link = (userInfo["link"] as? String).flatMap(URL.init(string:)) {
            return link
        }
        return userInfo["aps"] == nil ? nil : URL(string: "tutorcentral://today")
    }

    /// Opens the link and tells UIKit the tap is handled, both on the main thread, wherever the tap arrived.
    nonisolated func received(_ link: URL?, then done: @escaping () -> Void) {
        nonisolated(unsafe) let done = done
        if Thread.isMainThread {
            MainActor.assumeIsolated { open(link) }
            done()
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.open(link) }
                done()
            }
        }
    }
}
