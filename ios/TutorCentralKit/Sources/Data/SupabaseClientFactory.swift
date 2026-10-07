import Foundation
import Supabase

/// The one client. The redirect URL is the app's scheme (Info.plist): Google's web session comes back to it.
public enum SupabaseClientFactory {
    public static let redirectURL = URL(string: "tutorcentral://auth-callback") ?? URL(fileURLWithPath: "/")

    public static func make(_ config: SupabaseConfig) -> SupabaseClient {
        SupabaseClient(
            supabaseURL: config.url,
            supabaseKey: config.anonKey,
            options: .init(auth: .init(redirectToURL: redirectURL, emitLocalSessionAsInitialSession: true))
        )
    }
}
