import UIKit
import XCTest

/// The one launch test (D15): the app process is up and has connected a scene.
final class LaunchSmokeTests: XCTestCase {
    @MainActor func testAppLaunchedWithAScene() {
        XCTAssertFalse(UIApplication.shared.connectedScenes.isEmpty, "no scene after launch")
    }

    /// iPhone only (D1): the built app declares device family 1 alone. App Store Connect refuses a portrait-only app
    /// that also declares iPad.
    func testTheAppIsForIPhoneOnly() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "UIDeviceFamily") as? [Int], [1])
    }
}
