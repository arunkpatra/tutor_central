import Foundation

/// Where the app finds Supabase. Values come from Info.plist, which the build fills from xcconfig
/// (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). The anon key is public by design; the service role key never ships.
public struct SupabaseConfig: Sendable, Equatable {
    public enum Error: Swift.Error, Equatable {
        case missing(String)
        case invalidURL
    }

    public let url: URL
    public let anonKey: String

    public init(info: [String: Any]) throws {
        guard let urlString = info["SUPABASE_URL"] as? String, !urlString.isEmpty else {
            throw Error.missing("SUPABASE_URL")
        }
        guard let key = info["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            throw Error.missing("SUPABASE_ANON_KEY")
        }
        guard let url = URL(string: urlString), ["http", "https"].contains(url.scheme), url.host() != nil else {
            throw Error.invalidURL
        }
        self.url = url
        anonKey = key
    }

    public static func fromMainBundle() throws -> SupabaseConfig {
        try SupabaseConfig(info: Bundle.main.infoDictionary ?? [:])
    }
}
