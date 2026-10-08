/// Up to two letters from the first two words of a name (components.md, Avatar); "?" when there is no name.
public enum NameInitials {
    public static func of(_ name: String) -> String {
        let letters = name.split(whereSeparator: \.isWhitespace).prefix(2).compactMap { $0.first.map(String.init) }
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }
}
