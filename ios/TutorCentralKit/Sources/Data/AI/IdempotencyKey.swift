import CryptoKit
import Foundation

/// The key every AI call carries (D84): by default the same for the same request (the route and the body, its keys
/// sorted), so a repeat within a day (a second open, a replayed run, a retry) costs nothing and answers the same; a
/// fresh
/// one where the screen means "another one" (Create again). Under the API's 200 characters.
public enum IdempotencyKey {
    public static func forBody(route: String, body: Data) -> String {
        var hash = SHA256()
        hash.update(data: Data(route.utf8))
        hash.update(data: Data([0]))
        hash.update(data: body)
        return "tc-" + hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    public static func fresh() -> String {
        "tc-" + UUID().uuidString.lowercased()
    }
}
