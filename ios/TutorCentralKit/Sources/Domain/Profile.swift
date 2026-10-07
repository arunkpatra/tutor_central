/// The tutor as the app names them.
public struct Profile: Hashable, Sendable {
    public var displayName: String?

    public init(displayName: String?) {
        self.displayName = displayName
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
