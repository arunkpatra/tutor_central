import Data
import Domain
import Foundation
import SwiftUI

/// Everything a store needs, given through the environment; previews and `bun shots` give fakes (Fixtures).
public struct Dependencies: Sendable {
    public let auth: any AuthRepository
    public let centres: any CentreRepository
    public let counts: any CountsRepository
    public let now: @Sendable () -> Date
    /// "0.1 (12)": the marketing version and the build.
    public let bundleVersion: String

    public init(
        auth: any AuthRepository,
        centres: any CentreRepository,
        counts: any CountsRepository,
        now: @escaping @Sendable () -> Date,
        bundleVersion: String
    ) {
        self.auth = auth
        self.centres = centres
        self.counts = counts
        self.now = now
        self.bundleVersion = bundleVersion
    }

    /// The real thing, from Info.plist (SupabaseConfig) and the bundle's version strings.
    public static func live() throws -> Dependencies {
        let client = try SupabaseClientFactory.make(SupabaseConfig.fromMainBundle())
        let info = Bundle.main.infoDictionary ?? [:]
        let version = "\(info["CFBundleShortVersionString"] ?? "0") (\(info["CFBundleVersion"] ?? "0"))"
        return Dependencies(
            auth: SupabaseAuthRepository(client: client),
            centres: SupabaseCentreRepository(client: client),
            counts: SupabaseCountsRepository(client: client),
            now: { Date() },
            bundleVersion: version
        )
    }
}
