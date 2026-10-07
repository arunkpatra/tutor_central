/// An email address the app will send a code to: one @, a dot inside the domain, no spaces. Lower-cased and trimmed.
public struct EmailAddress: Hashable, Sendable {
    public let string: String

    public init?(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."), !parts[1].hasPrefix("."),
              !parts[1].hasSuffix("."), !text.contains(where: \.isWhitespace) else { return nil }
        string = text
    }
}
