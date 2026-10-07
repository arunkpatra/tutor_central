import UIKit
import XCTest

/// The one launch test (D15): the app process is up and has connected a scene.
final class LaunchSmokeTests: XCTestCase {
    @MainActor func testAppLaunchedWithAScene() {
        XCTAssertFalse(UIApplication.shared.connectedScenes.isEmpty, "no scene after launch")
    }
}
