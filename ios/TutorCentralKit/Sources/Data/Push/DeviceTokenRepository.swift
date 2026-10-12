import Foundation

/// This iPhone's push token as `device_tokens` keeps it (D72): per user and device, the APNs environment it was issued
/// for, the build that sent it.
public struct DeviceToken: Hashable, Sendable {
    public let deviceID: String
    /// The token's bytes in lowercase hex, as APNs takes it.
    public let token: String
    /// "sandbox" (Debug builds and the simulator) or "production" (TestFlight and the App Store).
    public let environment: String
    public let build: Int?

    public init(deviceID: String, token: String, environment: String, build: Int?) {
        self.deviceID = deviceID
        self.token = token
        self.environment = environment
        self.build = build
    }

    /// The bytes iOS hands the app, in hex.
    public static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}

/// Where this iPhone's token is kept for the server to push to; removed at sign-out and deletion (D40).
public protocol DeviceTokenRepository: Sendable {
    /// Saves or replaces this device's row for the signed-in user.
    func save(_ token: DeviceToken) async throws
    /// Removes this device's row for the signed-in user.
    func forget(deviceID: String) async throws
}
