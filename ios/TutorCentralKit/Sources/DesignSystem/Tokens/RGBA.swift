import SwiftUI

/// A colour as the design document writes it: `#RRGGBB` or `rgba(r,g,b,a)`. Kept as numbers so the document test can
/// compare, and so `css` writes it back byte for byte.
public struct RGBA: Hashable, Sendable {
    public let red: Int
    public let green: Int
    public let blue: Int
    public let alpha: Double

    public init(red: Int, green: Int, blue: Int, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init?(css: String) {
        let text = css.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("#"), text.count == 7, let hex = Int(text.dropFirst(), radix: 16) {
            self.init(red: hex >> 16 & 0xFF, green: hex >> 8 & 0xFF, blue: hex & 0xFF, alpha: 1)
            return
        }
        guard text.hasPrefix("rgba("), text.hasSuffix(")") else { return nil }
        let parts = text.dropFirst(5).dropLast().split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 4, let red = Int(parts[0]), let green = Int(parts[1]), let blue = Int(parts[2]),
              let alpha = Double(parts[3].hasPrefix(".") ? "0" + parts[3] : parts[3]) else { return nil }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// The document's spelling: upper-case hex when opaque, `rgba(r,g,b,.a)` with no leading zero otherwise.
    public var css: String {
        if alpha == 1 {
            return String(format: "#%02X%02X%02X", red, green, blue)
        }
        var fraction = String(alpha)
        if fraction.hasPrefix("0.") {
            fraction.removeFirst()
        }
        return "rgba(\(red),\(green),\(blue),\(fraction))"
    }

    var uiColor: UIColor {
        UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }
}
