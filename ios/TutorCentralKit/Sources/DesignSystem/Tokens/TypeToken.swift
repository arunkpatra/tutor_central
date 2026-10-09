import SwiftUI

/// A text style: SF Pro through Dynamic Type (`style` gives the scaling), the design size, line height, weight,
/// tracking in em, and whether the text is upper-cased (eyebrows).
public struct TypeToken: Hashable, Sendable {
    public let name: String
    public let style: Font.TextStyle
    public let size: CGFloat
    public let line: CGFloat
    public let weight: Font.Weight
    public let trackingEm: CGFloat
    public let uppercase: Bool

    init(
        _ name: String,
        _ style: Font.TextStyle,
        size: CGFloat,
        line: CGFloat,
        weight: Int,
        tracking: CGFloat = 0,
        uppercase: Bool = false
    ) {
        self.name = name
        self.style = style
        self.size = size
        self.line = line
        self.weight = Self.weight(weight)
        trackingEm = tracking
        self.uppercase = uppercase
    }

    /// 400, 600, 700 and 800 are the only weights the system uses.
    static func weight(_ number: Int) -> Font.Weight {
        switch number {
        case 400: .regular
        case 600: .semibold
        case 700: .bold
        default: .heavy
        }
    }

    public var weightNumber: Int {
        switch weight {
        case .regular: 400
        case .semibold: 600
        case .bold: 700
        default: 800
        }
    }

    /// Scaled with the text style's Dynamic Type curve, at the app's text size now (for UIKit text built outside a
    /// view). Views go through `typeStyle`, which follows the environment's size.
    public var font: Font {
        let scaled = UIFontMetrics(forTextStyle: style.uiKit).scaledValue(for: size)
        return .system(size: scaled, weight: weight).monospacedDigit()
    }

    /// The point size at a given text size, on the text style's Dynamic Type curve.
    public func scaledSize(at typeSize: DynamicTypeSize) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(typeSize))
        return UIFontMetrics(forTextStyle: style.uiKit).scaledValue(for: size, compatibleWith: traits)
    }

    /// The font at a given text size.
    public func font(at typeSize: DynamicTypeSize) -> Font {
        .system(size: scaledSize(at: typeSize), weight: weight).monospacedDigit()
    }

    /// Extra space between lines so the line height matches the design at the default size: the design's line less
    /// the font's own (SF Pro at 34 pt is already about 41 high), never negative.
    public var lineSpacing: CGFloat {
        max(0, line - UIFont.systemFont(ofSize: size, weight: weight.uiKit).lineHeight)
    }

    /// Tracking in points at the design size.
    public var kerning: CGFloat {
        trackingEm * size
    }
}

extension Font.Weight {
    var uiKit: UIFont.Weight {
        switch self {
        case .regular: .regular
        case .semibold: .semibold
        case .bold: .bold
        default: .heavy
        }
    }
}

extension Font.TextStyle {
    var uiKit: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}
