import Testing
@testable import Data

struct SupabaseConfigTests {
    static let info = [
        "SUPABASE_URL": "https://x.supabase.co", "SUPABASE_ANON_KEY": "anon", "API_ORIGIN": "https://api.example.app",
    ]

    @Test func refusesAMissingOrBadAPIOrigin() {
        var missing = Self.info
        missing["API_ORIGIN"] = nil
        #expect(throws: SupabaseConfig.Error.missing("API_ORIGIN")) { try SupabaseConfig(info: missing) }
        var bad = Self.info
        bad["API_ORIGIN"] = "not a url"
        #expect(throws: SupabaseConfig.Error.invalidURL) { try SupabaseConfig(info: bad) }
    }

    @Test func readsFromAnInfoDictionary() throws {
        let config = try SupabaseConfig(info: Self.info)
        #expect(config.url.absoluteString == "https://x.supabase.co")
        #expect(config.anonKey == "anon")
        #expect(config.apiOrigin.absoluteString == "https://api.example.app")
    }

    @Test func refusesAMissingKey() {
        #expect(throws: SupabaseConfig.Error.missing("SUPABASE_ANON_KEY")) {
            try SupabaseConfig(info: ["SUPABASE_URL": "https://x.supabase.co", "API_ORIGIN": "https://a.b"])
        }
        #expect(throws: SupabaseConfig.Error.missing("SUPABASE_URL")) {
            try SupabaseConfig(info: ["SUPABASE_URL": "", "SUPABASE_ANON_KEY": "anon", "API_ORIGIN": "https://a.b"])
        }
    }

    @Test func refusesABadURL() {
        #expect(throws: SupabaseConfig.Error.invalidURL) {
            try SupabaseConfig(info: [
                "SUPABASE_URL": "not a url",
                "SUPABASE_ANON_KEY": "anon",
                "API_ORIGIN": "https://a.b",
            ])
        }
        #expect(throws: SupabaseConfig.Error.invalidURL) {
            try SupabaseConfig(info: [
                "SUPABASE_URL": "ftp://x.supabase.co",
                "SUPABASE_ANON_KEY": "anon",
                "API_ORIGIN": "https://a.b",
            ])
        }
    }
}
