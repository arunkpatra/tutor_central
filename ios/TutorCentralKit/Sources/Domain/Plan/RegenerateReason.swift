import Foundation

/// Why the tutor asks for a sheet again (P10-Sheet-Regenerate): one of the menu's reasons or their own words.
public enum RegenerateReason: Hashable, Sendable {
    case easier, harder, shorter, moreSums, differentNumbers, own(String)

    /// The tutor's own words are kept to this many scalars (D48), as the API's `reason` is.
    public static let ownLimit = 200

    /// What the API's prompt reads: the menu's word, or the tutor's text trimmed and cut to 200 scalars.
    public var words: String {
        switch self {
        case .easier: "easier"
        case .harder: "harder"
        case .shorter: "shorter"
        case .moreSums: "more sums"
        case .differentNumbers: "different numbers"
        case let .own(text): Self.cut(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    /// The sheet's banner while it is made again (P10-Sheet-Regenerating).
    public var title: String {
        switch self {
        case .easier: "Making it easier"
        case .harder: "Making it harder"
        case .shorter: "Making it shorter"
        case .moreSums: "Making it with more sums"
        case .differentNumbers: "Making it with different numbers"
        case .own: "Making it as you asked"
        }
    }

    private static func cut(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        scalars.append(contentsOf: text.unicodeScalars.prefix(ownLimit))
        return String(scalars)
    }
}
