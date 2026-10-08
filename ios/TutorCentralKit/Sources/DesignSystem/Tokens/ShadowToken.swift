import SwiftUI

/// One shadow layer as CSS writes it: "x y blur [spread] colour".
public struct ShadowLayer: Hashable, Sendable {
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
    public let spread: CGFloat
    public let color: RGBA
}

/// An elevation token in both appearances, kept as the document's CSS strings (the test compares those) and parsed
/// into drop layers plus an optional inset highlight. SwiftUI has no inset shadow: `shadowed(_:)` draws the inset as
/// a 1 pt top stroke.
public struct ShadowToken: Hashable, Sendable {
    public let name: String
    public let dark: String
    public let light: String
    /// The layers, parsed once when the token is made, so drawing a long list never re-reads the CSS.
    private let parsedDark: Layers
    private let parsedLight: Layers

    /// A token's drop layers and its inset layer, if any.
    public struct Layers: Hashable, Sendable {
        public let drops: [ShadowLayer]
        public let inset: ShadowLayer?
    }

    init(_ name: String, dark: String, light: String) {
        self.name = name
        self.dark = dark
        self.light = light
        parsedDark = Self.layers(dark)
        parsedLight = Self.layers(light)
    }

    /// The layers for an appearance, as parsed when the token was made.
    public func layers(dark: Bool) -> Layers {
        dark ? parsedDark : parsedLight
    }

    private static func layers(_ css: String) -> Layers {
        let parsed = parse(css)
        return Layers(drops: parsed.drops, inset: parsed.inset)
    }

    /// "inset 0 1px 0 rgba(...), 0 1px 2px rgba(...)" → the drop layers and the inset layer, if any.
    public static func parse(_ css: String) -> (drops: [ShadowLayer], inset: ShadowLayer?) {
        var drops: [ShadowLayer] = []
        var inset: ShadowLayer?
        // Each layer ends with its rgba(...); splitting on ")" keeps the commas inside rgba() together.
        for raw in css.split(separator: ")") {
            var part = raw.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
            let isInset = part.hasPrefix("inset ")
            if isInset {
                part.removeFirst(6)
            }
            guard let colourStart = part.range(of: "rgba(") else { continue }
            let numbers = part[..<colourStart.lowerBound].split(separator: " ")
                .compactMap { Double($0.replacingOccurrences(of: "px", with: "")) }
            guard numbers.count >= 3,
                  let color = RGBA(css: String(part[colourStart.lowerBound...]) + ")") else { continue }
            let layer = ShadowLayer(
                x: numbers[0],
                y: numbers[1],
                blur: numbers[2],
                spread: numbers.count > 3 ? numbers[3] : 0,
                color: color
            )
            if isInset {
                inset = layer
            } else {
                drops.append(layer)
            }
        }
        return (drops, inset)
    }
}
