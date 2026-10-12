import Data
import UIKit
import UserNotifications

/// The one UIKit entry (D8, with its reason): the notification centre's delegate must be in place before launch ends,
/// or a tap that launched the app is lost; and iOS hands the push token to the app delegate alone. The tapped
/// notification's link reaches RootView through `NotificationDelegate`, the token the shell through `PushRelay`.
public final class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        return true
    }

    public func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MainActor.assumeIsolated { PushRelay.shared.received(deviceToken) }
    }

    /// No token (the simulator without network, push not in the profile): the reminders cannot reach this iPhone; the
    /// next launch asks again.
    public func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: any Error) {}
}
