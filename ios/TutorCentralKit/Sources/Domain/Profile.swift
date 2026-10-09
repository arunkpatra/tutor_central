/// The tutor as the app names them.
public struct Profile: Hashable, Sendable, Codable {
    public var displayName: String?
    /// Whether the tutor set a password (`profiles.has_password`): Account's row and the sign-in sheet's offer.
    public var hasPassword: Bool

    public init(displayName: String?, hasPassword: Bool = false) {
        self.displayName = displayName
        self.hasPassword = hasPassword
    }

    /// "Meera Nair" → "Meera"; nil when there is no name.
    public var firstName: String? {
        displayName?.split(separator: " ").first.map(String.init)
    }

    /// "Meera Nair" → "MN"; "Meera" → "M"; no name → "?".
    public var initials: String {
        let letters = (displayName ?? "").split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }
}
