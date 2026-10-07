import Testing
@testable import Data

@Suite struct SupabaseConfigTests {
    @Test func readsFromAnInfoDictionary() throws {
        let config = try SupabaseConfig(info: ["SUPABASE_URL": "https://x.supabase.co", "SUPABASE_ANON_KEY": "anon"])
        #expect(config.url.absoluteString == "https://x.supabase.co")
        #expect(config.anonKey == "anon")
    }

    @Test func refusesAMissingKey() {
        #expect(throws: SupabaseConfig.Error.missing("SUPABASE_ANON_KEY")) {
            try SupabaseConfig(info: ["SUPABASE_URL": "https://x.supabase.co"])
        }
        #expect(throws: SupabaseConfig.Error.missing("SUPABASE_URL")) {
            try SupabaseConfig(info: ["SUPABASE_URL": "", "SUPABASE_ANON_KEY": "anon"])
        }
    }

    @Test func refusesABadURL() {
        #expect(throws: SupabaseConfig.Error.invalidURL) {
            try SupabaseConfig(info: ["SUPABASE_URL": "not a url", "SUPABASE_ANON_KEY": "anon"])
        }
        #expect(throws: SupabaseConfig.Error.invalidURL) {
            try SupabaseConfig(info: ["SUPABASE_URL": "ftp://x.supabase.co", "SUPABASE_ANON_KEY": "anon"])
        }
    }
}
