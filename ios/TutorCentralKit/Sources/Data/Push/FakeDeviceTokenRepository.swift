import Foundation

/// Device tokens in memory, for tests, previews and `bun shots`: a record of saves and forgets, in order.
public actor FakeDeviceTokenRepository: DeviceTokenRepository {
    public private(set) var saved: [DeviceToken] = []
    public private(set) var forgotten: [String] = []
    private let failure: (any Error)?
    private let onForget: (@Sendable () async -> Void)?

    public init(failure: (any Error)? = nil, onForget: (@Sendable () async -> Void)? = nil) {
        self.failure = failure
        self.onForget = onForget
    }

    public func save(_ token: DeviceToken) async throws {
        if let failure {
            throw failure
        }
        saved.append(token)
    }

    public func forget(deviceID: String) async throws {
        await onForget?()
        forgotten.append(deviceID)
    }
}
