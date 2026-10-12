import CryptoKit
import Domain
import Foundation

/// The key every AI call carries (D84): by default the same for the same request on the same day in India (the route,
/// the body with its keys sorted, the day), so a repeat that day (a second open, a replayed run, a retry) costs nothing
/// and answers the same, and the plan's material asked again tomorrow is made again; a fresh one where the screen means
/// "another one" (Make it again, Write again, Create again). Under the API's 200 characters.
public enum IdempotencyKey {
    /// Set while a screen asks for another one (`another`): every AI call inside takes a fresh key.
    @TaskLocal public static var isAnother = false

    /// Runs `operation` as "another one": the same body asked again is a new call.
    public static func another<T>(
        isolation _: isolated (any Actor)? = #isolation, _ operation: () async throws -> T
    ) async rethrows -> T {
        try await $isAnother.withValue(true, operation: operation)
    }

    public static func forBody(route: String, body: Data, day: Day) -> String {
        var hash = SHA256()
        hash.update(data: Data(route.utf8))
        hash.update(data: Data([0]))
        hash.update(data: body)
        hash.update(data: Data([0]))
        hash.update(data: Data(day.iso.utf8))
        return "tc-" + hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    public static func fresh() -> String {
        "tc-" + UUID().uuidString.lowercased()
    }
}
