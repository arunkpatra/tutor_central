import AVFoundation

/// What tapping a camera button does (Scan a QR, Take a photo, Take photos): scan, ask for the camera the first time,
/// say where to allow a refused camera, or say there is none (the simulator). DesignSystem's, because Fees, Students
/// and AITools all ask the same question; AVFoundation is imported only for the authorisation status.
public enum CameraAccess: Equatable, Sendable {
    case scan
    case ask
    case denied
    case noCamera

    public static let noCameraMessage = "No camera on this device."

    public static func decide(supported: Bool, status: AVAuthorizationStatus) -> CameraAccess {
        guard supported else { return .noCamera }
        switch status {
        case .authorized: return .scan
        case .notDetermined: return .ask
        default: return .denied
        }
    }
}
