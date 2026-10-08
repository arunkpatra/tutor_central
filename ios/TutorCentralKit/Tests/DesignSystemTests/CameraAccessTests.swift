import AVFoundation
import Testing
@testable import DesignSystem

/// Review, Important 4: Scan a QR asks for the camera the first time, says how to allow it when refused, and says
/// "No camera" only where there is none.
struct CameraAccessTests {
    @Test func theFirstTapAsksAndARefusalSaysWhereToAllowIt() {
        #expect(CameraAccess.decide(supported: true, status: .notDetermined) == .ask)
        #expect(CameraAccess.decide(supported: true, status: .authorized) == .scan)
        #expect(CameraAccess.decide(supported: true, status: .denied) == .denied)
        #expect(CameraAccess.decide(supported: true, status: .restricted) == .denied)
        #expect(CameraAccess.decide(supported: false, status: .authorized) == .noCamera)
        #expect(CameraAccess.deniedMessage == "Allow the camera for Tutor Central in Settings.")
        #expect(CameraAccess.noCameraMessage == "No camera on this device.")
    }
}
