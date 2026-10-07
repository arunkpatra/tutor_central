import CryptoKit
import Foundation

/// Sign in with Apple wants a nonce: the raw one goes to Supabase, its SHA-256 goes to Apple.
public enum Nonce {
    public static func random() -> String {
        var generator = SystemRandomNumberGenerator()
        return (0 ..< 32).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max, using: &generator)) }
            .joined()
    }

    public static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
