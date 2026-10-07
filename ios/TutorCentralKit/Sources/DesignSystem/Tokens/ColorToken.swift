import SwiftUI

/// One colour in both appearances (D13). Declared with the document's literals; `color` adapts to the appearance.
public struct ColorToken: Hashable, Sendable {
    public let name: String
    public let dark: RGBA
    public let light: RGBA

    init(_ name: String, dark: String, light: String) {
        self.name = name
        self.dark = Self.literal(dark, name)
        self.light = Self.literal(light, name)
    }

    public var color: Color {
        DynamicColor.make(dark: dark, light: light)
    }

    /// The literals are this module's own, pinned by the document test; a typo traps at launch with its name.
    private static func literal(_ css: String, _ name: String) -> RGBA {
        guard let value = RGBA(css: css) else { fatalError("Colour token \(name) has an unreadable value \(css)") }
        return value
    }
}
