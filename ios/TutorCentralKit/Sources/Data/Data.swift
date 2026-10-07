import Supabase

/// Repositories arrive with the features that need them (Phase 2 on). This file proves the dependency links.
public enum DataModule {
    public static func makeClient(_ config: SupabaseConfig) -> SupabaseClient {
        SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
    }
}
