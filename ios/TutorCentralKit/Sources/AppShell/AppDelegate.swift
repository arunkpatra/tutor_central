import Data
import UIKit
import UserNotifications

/// The one UIKit entry (D8, with its reason): the notification centre's delegate must be in place before launch ends,
/// or a tap that launched the app is lost. The tapped reminder's link reaches RootView through `NotificationDelegate`.
/// The background refresh is registered here for the same reason (iOS refuses a registration after launch).
public final class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        BackgroundRefresh.register {}
        return true
    }
}
