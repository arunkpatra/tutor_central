import Foundation

/// Where the app finds Supabase. Values come from Info.plist, which the build fills from xcconfig
/// (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_ORIGIN`). The anon key is public by design; the service role key never
/// ships. `API_ORIGIN` is our API (the AI tools), never Anthropic's.
public struct SupabaseConfig: Sendable, Equatable {
    public enum Error: Swift.Error, Equatable {
        case missing(String)
        case invalidURL
    }

    public let url: URL
    public let anonKey: String
    public let apiOrigin: URL

    public init(info: [String: Any]) throws {
        guard let urlString = info["SUPABASE_URL"] as? String, !urlString.isEmpty else {
            throw Error.missing("SUPABASE_URL")
        }
        guard let key = info["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            throw Error.missing("SUPABASE_ANON_KEY")
        }
        guard let originString = info["API_ORIGIN"] as? String, !originString.isEmpty else {
            throw Error.missing("API_ORIGIN")
        }
        guard let url = Self.webURL(urlString), let origin = Self.webURL(originString) else {
            throw Error.invalidURL
        }
        self.url = url
        anonKey = key
        apiOrigin = origin
    }

    private static func webURL(_ text: String) -> URL? {
        guard let url = URL(string: text), ["http", "https"].contains(url.scheme), url.host() != nil else { return nil }
        return url
    }

    public static func fromMainBundle() throws -> SupabaseConfig {
        try SupabaseConfig(info: Bundle.main.infoDictionary ?? [:])
    }
}
