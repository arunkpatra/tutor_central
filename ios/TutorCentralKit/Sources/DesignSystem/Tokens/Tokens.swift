import SwiftUI

/// Every value a view may use (D10). Names are the document's (`docs/design/design-tokens.md`): `ground` there is
/// `Tokens.ground` here. The registry lists every token by kind so the document test and the Kit can walk them.
public enum Tokens {
    public enum Kind: Sendable {
        case color(ColorToken)
        case type(TypeToken)
        case spacing(CGFloat)
        case radius(CGFloat)
        case shadow(ShadowToken)
        case duration(Double)
    }

    public static let registry: [String: Kind] = {
        var all: [String: Kind] = [:]
        for token in colors {
            all[token.name] = .color(token)
        }
        for token in types {
            all[token.name] = .type(token)
        }
        for (name, value) in spacings {
            all[name] = .spacing(value)
        }
        for (name, value) in radii {
            all[name] = .radius(value)
        }
        for token in shadows {
            all[token.name] = .shadow(token)
        }
        for (name, value) in durations {
            all[name] = .duration(value)
        }
        return all
    }()
}
