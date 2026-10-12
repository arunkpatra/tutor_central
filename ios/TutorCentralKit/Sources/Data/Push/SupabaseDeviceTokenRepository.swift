import Foundation
import Supabase

/// `device_tokens` through the signed-in user (RLS: their own rows); one row per user and device.
public struct SupabaseDeviceTokenRepository: DeviceTokenRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func save(_ token: DeviceToken) async throws {
        let formatter = ISO8601DateFormatter()
        let row: [String: AnyJSON] = [
            "device_id": .string(token.deviceID), "token": .string(token.token),
            "environment": .string(token.environment), "app_build": token.build.map(AnyJSON.integer) ?? .null,
            "last_seen_at": .string(formatter.string(from: Date())), "retired_at": .null,
        ]
        try await client.from("device_tokens").upsert(row, onConflict: "user_id,device_id").execute()
    }

    public func forget(deviceID: String) async throws {
        try await client.from("device_tokens").delete().eq("device_id", value: deviceID).execute()
    }
}
